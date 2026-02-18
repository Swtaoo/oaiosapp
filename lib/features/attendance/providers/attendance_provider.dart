import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/attendance_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/api/attendance_api.dart';
import '../data/models/attendance_models.dart';

// 考勤 API Provider
final attendanceApiProvider = Provider<AttendanceApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AttendanceApi(dio);
});

/// 考勤状态
class AttendanceState {
  final DailyAttendance? todayData;
  final List<DailyAttendance> records;
  final MonthlyStats? monthlyStats;
  final PeriodStats? detailedStats;
  final AttendanceRule rule;
  final bool isLoading;
  final String? error;
  final TeamStats? teamStats;
  final LocalPunchData localPunchData;

  AttendanceState({
    this.todayData,
    this.records = const [],
    this.monthlyStats,
    this.detailedStats,
    AttendanceRule? rule,
    this.isLoading = false,
    this.error,
    this.teamStats,
    LocalPunchData? localPunchData,
  })  : rule = rule ??
            const AttendanceRule(
              id: DefaultAttendanceRule.id,
              companyName: DefaultAttendanceRule.companyName,
              workStartTime: DefaultAttendanceRule.workStartTime,
              workEndTime: DefaultAttendanceRule.workEndTime,
              lateGraceMinutes: DefaultAttendanceRule.lateGraceMinutes,
              fenceLat: DefaultAttendanceRule.fenceLat,
              fenceLng: DefaultAttendanceRule.fenceLng,
              fenceRadius: DefaultAttendanceRule.fenceRadius,
              wifiNames: DefaultAttendanceRule.wifiNames,
              requirePhoto: DefaultAttendanceRule.requirePhoto,
            ),
        localPunchData = localPunchData ?? LocalPunchData();

  bool get hasClockedIn =>
      todayData?.clockInRecord != null || localPunchData.morningPunch;

  bool get hasClockedOut =>
      todayData?.clockOutRecord != null || localPunchData.eveningPunch;

  String get clockInTime {
    final record = todayData?.clockInRecord;
    if (record != null) {
      final parts = record.punchTime.split(' ');
      return parts.length > 1 ? (parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1]) : '';
    }
    return localPunchData.morningTime;
  }

  String get clockOutTime {
    final record = todayData?.clockOutRecord;
    if (record != null) {
      final parts = record.punchTime.split(' ');
      return parts.length > 1 ? (parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1]) : '';
    }
    return localPunchData.eveningTime;
  }

  String get scheduledClockIn =>
      todayData?.scheduledClockIn.isNotEmpty == true
          ? todayData!.scheduledClockIn
          : rule.workStartTime;

  String get scheduledClockOut =>
      todayData?.scheduledClockOut.isNotEmpty == true
          ? todayData!.scheduledClockOut
          : rule.workEndTime;

  AttendanceState copyWith({
    DailyAttendance? todayData,
    bool clearTodayData = false,
    List<DailyAttendance>? records,
    MonthlyStats? monthlyStats,
    bool clearMonthlyStats = false,
    PeriodStats? detailedStats,
    bool clearDetailedStats = false,
    AttendanceRule? rule,
    bool? isLoading,
    String? error,
    bool clearError = false,
    TeamStats? teamStats,
    bool clearTeamStats = false,
    LocalPunchData? localPunchData,
  }) {
    return AttendanceState(
      todayData: clearTodayData ? null : (todayData ?? this.todayData),
      records: records ?? this.records,
      monthlyStats:
          clearMonthlyStats ? null : (monthlyStats ?? this.monthlyStats),
      detailedStats:
          clearDetailedStats ? null : (detailedStats ?? this.detailedStats),
      rule: rule ?? this.rule,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      teamStats: clearTeamStats ? null : (teamStats ?? this.teamStats),
      localPunchData: localPunchData ?? this.localPunchData,
    );
  }
}

/// 考勤状态管理 - 对应 src/store/attendance.ts
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final Ref _ref;
  static const _storageKeyPrefix = 'attendance_punch_data';

  AttendanceNotifier(this._ref) : super(AttendanceState());

  int get _userId =>
      _ref.read(currentUserProvider)?.effectiveUserId ?? 0;

  AttendanceApi get _api => _ref.read(attendanceApiProvider);

  String get _storageKey => '${_storageKeyPrefix}_${_userId > 0 ? _userId : 'unknown'}';

  // === 本地存储 ===

  Future<void> loadLocalPunchData() async {
    try {
      final storage = await _ref.read(localStorageProvider.future);
      final data = storage.getString(_storageKey);
      if (data != null) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final local = LocalPunchData.fromJson(json);
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (local.lastPunchDate == today) {
          state = state.copyWith(localPunchData: local);
        } else {
          await clearLocalPunchData();
        }
      }
    } catch (e) { debugPrint('[attendance_provider] Error: $e'); }
  }

  Future<void> saveLocalPunchData() async {
    try {
      final storage = await _ref.read(localStorageProvider.future);
      await storage.setString(
        _storageKey,
        jsonEncode(state.localPunchData.toJson()),
      );
    } catch (e) { debugPrint('[attendance_provider] Error: $e'); }
  }

  Future<void> clearLocalPunchData() async {
    state = state.copyWith(localPunchData: LocalPunchData());
    try {
      final storage = await _ref.read(localStorageProvider.future);
      await storage.remove(_storageKey);
    } catch (e) { debugPrint('[attendance_provider] Error: $e'); }
  }

  // === API 方法 ===

  Future<void> fetchTodayData() async {
    if (_userId <= 0) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _api.getToday(_userId);
      if (res.isSuccess && res.data != null) {
        final data = res.data!;
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final local = state.localPunchData;
        local.lastPunchDate = today;
        if (data.clockInRecord != null) {
          local.morningPunch = true;
          final parts = data.clockInRecord!.punchTime.split(' ');
          local.morningTime = parts.length > 1
              ? (parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1])
              : '';
        }
        if (data.clockOutRecord != null) {
          local.eveningPunch = true;
          final parts = data.clockOutRecord!.punchTime.split(' ');
          local.eveningTime = parts.length > 1
              ? (parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1])
              : '';
        }
        state = state.copyWith(
          todayData: data,
          localPunchData: local,
          isLoading: false,
        );
        await saveLocalPunchData();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) { debugPrint('[attendance_provider] Error: $e');
      await loadLocalPunchData();
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchRecords(String startDate, String endDate) async {
    if (_userId <= 0) return;

    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getRecords(
        userId: _userId,
        startDate: startDate,
        endDate: endDate,
      );
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(records: res.data!, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) { debugPrint('[attendance_provider] Error: $e');
      state = state.copyWith(records: [], isLoading: false);
    }
  }

  Future<void> fetchMonthlyStats(int year, int month) async {
    if (_userId <= 0) return;

    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getMonthlyStats(
        userId: _userId,
        year: year,
        month: month,
      );
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(monthlyStats: res.data!, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) { debugPrint('[attendance_provider] Error: $e');
      state = state.copyWith(clearMonthlyStats: true, isLoading: false);
    }
  }

  Future<void> fetchWeeklyStats(int year, int month, int weekOfMonth) async {
    if (_userId <= 0) return;

    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getWeeklyStats(
        userId: _userId,
        year: year,
        month: month,
        weekOfMonth: weekOfMonth,
      );
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(detailedStats: res.data!, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) { debugPrint('[attendance_provider] Error: $e');
      state = state.copyWith(clearDetailedStats: true, isLoading: false);
    }
  }

  Future<void> fetchMonthlyDetailedStats(int year, int month) async {
    if (_userId <= 0) return;

    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getMonthlyDetailedStats(
        userId: _userId,
        year: year,
        month: month,
      );
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(detailedStats: res.data!, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) { debugPrint('[attendance_provider] Error: $e');
      state = state.copyWith(clearDetailedStats: true, isLoading: false);
    }
  }

  Future<void> fetchRule() async {
    if (_userId <= 0) return;

    try {
      final res = await _api.getRule(_userId);
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(rule: res.data!);
      }
    } catch (e) { debugPrint('[attendance_provider] Error: $e');
      // 使用默认规则
    }
  }

  Future<void> fetchTeamStats(int year, int month, {String? endDate}) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.getTeamStats(
        year: year,
        month: month,
        endDate: endDate,
      );
      if (res.isSuccess && res.data != null) {
        state = state.copyWith(teamStats: res.data!, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) { debugPrint('[attendance_provider] Error: $e');
      state = state.copyWith(clearTeamStats: true, isLoading: false);
    }
  }

  /// 打卡
  Future<AttendancePunchRecord?> doPunch({
    required String punchLocation,
    required String punchTime,
  }) async {
    if (_userId <= 0) throw Exception('用户未登录');

    final alreadyClockedIn = state.hasClockedIn;

    final res = await _api.punch(
      punchLocation: punchLocation,
      punchTime: punchTime,
      userId: _userId,
      punchCategory: alreadyClockedIn ? 1 : 0,
    );

    if (res.isSuccess) {
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final local = state.localPunchData;
      local.lastPunchDate = today;
      if (alreadyClockedIn) {
        local.eveningPunch = true;
        local.eveningTime = timeStr;
      } else {
        local.morningPunch = true;
        local.morningTime = timeStr;
      }
      state = state.copyWith(localPunchData: local);
      await saveLocalPunchData();
      // 异步刷新后端数据
      fetchTodayData();
      return res.data;
    }
    throw Exception('打卡失败');
  }

  /// 重置每日状态 (跨天)
  Future<void> resetDailyStatus() async {
    state = state.copyWith(clearTodayData: true);
    await clearLocalPunchData();
  }

  /// 初始化
  Future<void> init() async {
    await loadLocalPunchData();
    fetchRule();
    fetchTodayData();
  }
}

/// 考勤状态 Provider
final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier(ref);
});
