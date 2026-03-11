import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/api/schedule_api.dart';
import '../data/models/schedule_models.dart';

// ──────────────────────────────────────────────
// API Provider
// ──────────────────────────────────────────────
final scheduleApiProvider = Provider<ScheduleApi>((ref) {
  return ScheduleApi(ref.read(dioProvider));
});

// ──────────────────────────────────────────────
// State
// ──────────────────────────────────────────────
class ScheduleState {
  final List<ScheduleUser> users;
  final ScheduleUser? selectedUser;
  final int year;
  final int month;

  /// 有显式 rest 记录的日期集合 (yyyy-MM-dd)，其余默认为 workday
  final Set<String> restDates;

  /// 正在保存中的日期（显示 loading 圆圈）
  final Set<String> savingDates;

  final bool isLoadingUsers;
  final bool isLoadingSchedule;

  /// 全体批量排班保存中
  final bool isBatchSaving;

  final String? error;

  const ScheduleState({
    this.users = const [],
    this.selectedUser,
    required this.year,
    required this.month,
    this.restDates = const {},
    this.savingDates = const {},
    this.isLoadingUsers = false,
    this.isLoadingSchedule = false,
    this.isBatchSaving = false,
    this.error,
  });

  ScheduleState copyWith({
    List<ScheduleUser>? users,
    ScheduleUser? selectedUser,
    int? year,
    int? month,
    Set<String>? restDates,
    Set<String>? savingDates,
    bool? isLoadingUsers,
    bool? isLoadingSchedule,
    bool? isBatchSaving,
    String? error,
    bool clearError = false,
    bool clearSelectedUser = false,
  }) {
    return ScheduleState(
      users: users ?? this.users,
      selectedUser: clearSelectedUser ? null : (selectedUser ?? this.selectedUser),
      year: year ?? this.year,
      month: month ?? this.month,
      restDates: restDates ?? this.restDates,
      savingDates: savingDates ?? this.savingDates,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isLoadingSchedule: isLoadingSchedule ?? this.isLoadingSchedule,
      isBatchSaving: isBatchSaving ?? this.isBatchSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  String getScheduleType(String date) =>
      restDates.contains(date) ? 'rest' : 'workday';
}

// ──────────────────────────────────────────────
// Notifier
// ──────────────────────────────────────────────
class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleApi _api;

  ScheduleNotifier(this._api)
      : super(ScheduleState(
          year: DateTime.now().year,
          month: DateTime.now().month,
        ));

  Future<void> init() async {
    await loadPersonnel();
  }

  Future<void> loadPersonnel() async {
    state = state.copyWith(isLoadingUsers: true, clearError: true);
    try {
      final res = await _api.getPersonnel();
      if (res.isSuccess && res.data != null) {
        final users = res.data!;
        state = state.copyWith(
          users: users,
          isLoadingUsers: false,
        );
        if (users.isNotEmpty && state.selectedUser == null) {
          await selectUser(users.first);
        }
      } else {
        state = state.copyWith(
          isLoadingUsers: false,
          error: res.message ?? '获取人员列表失败',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingUsers: false, error: e.toString());
    }
  }

  Future<void> selectUser(ScheduleUser user) async {
    state = state.copyWith(selectedUser: user);
    await _loadMonthSchedule(user.userId, state.year, state.month);
  }

  Future<void> changeMonth(int year, int month) async {
    state = state.copyWith(year: year, month: month, restDates: {});
    if (state.selectedUser != null) {
      await _loadMonthSchedule(state.selectedUser!.userId, year, month);
    }
  }

  Future<void> _loadMonthSchedule(int userId, int year, int month) async {
    state = state.copyWith(isLoadingSchedule: true, clearError: true);
    try {
      final res = await _api.getMonthSchedule(
        userId: userId,
        year: year,
        month: month,
      );
      if (res.isSuccess && res.data != null) {
        final restSet = res.data!
            .where((d) => d.isRest)
            .map((d) => d.date)
            .toSet();
        state = state.copyWith(restDates: restSet, isLoadingSchedule: false);
      } else {
        state = state.copyWith(
          isLoadingSchedule: false,
          error: res.message ?? '加载排班失败',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingSchedule: false, error: e.toString());
    }
  }

  Future<void> toggleDay(String date) async {
    final user = state.selectedUser;
    if (user == null) return;

    final currentIsRest = state.restDates.contains(date);
    final newType = currentIsRest ? 'workday' : 'rest';

    // 乐观更新
    final newRestDates = Set<String>.from(state.restDates);
    if (newType == 'rest') {
      newRestDates.add(date);
    } else {
      newRestDates.remove(date);
    }
    final newSaving = Set<String>.from(state.savingDates)..add(date);
    state = state.copyWith(restDates: newRestDates, savingDates: newSaving);

    try {
      final res = await _api.setDaySchedule(
        userId: user.userId,
        date: date,
        scheduleType: newType,
      );
      if (!res.isSuccess) {
        // 回滚
        _revertDay(date, currentIsRest);
        state = state.copyWith(error: res.message ?? '保存失败');
      }
    } catch (e) {
      _revertDay(date, currentIsRest);
      state = state.copyWith(error: e.toString());
    } finally {
      final saving = Set<String>.from(state.savingDates)..remove(date);
      state = state.copyWith(savingDates: saving);
    }
  }

  void _revertDay(String date, bool wasRest) {
    final reverted = Set<String>.from(state.restDates);
    if (wasRest) {
      reverted.add(date);
    } else {
      reverted.remove(date);
    }
    state = state.copyWith(restDates: reverted);
  }

  /// 全体员工批量设置某月排班，完成后刷新当前用户的排班视图
  Future<void> setBatchMonth(int year, int month, Set<String> restDates) async {
    state = state.copyWith(isBatchSaving: true, clearError: true);
    try {
      final res = await _api.setBatchMonth(
        year: year,
        month: month,
        restDates: restDates.toList(),
      );
      if (res.isSuccess) {
        // 刷新当前选中用户的排班
        if (state.selectedUser != null &&
            state.year == year &&
            state.month == month) {
          await _loadMonthSchedule(state.selectedUser!.userId, year, month);
        }
        state = state.copyWith(isBatchSaving: false);
      } else {
        state = state.copyWith(
          isBatchSaving: false,
          error: res.message ?? '批量排班失败',
        );
      }
    } catch (e) {
      state = state.copyWith(isBatchSaving: false, error: e.toString());
    }
  }
}

// ──────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────
final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(ref.read(scheduleApiProvider));
});
