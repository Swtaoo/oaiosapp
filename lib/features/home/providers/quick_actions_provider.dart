import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/api/quick_actions_api.dart';
import '../home_modules.dart';

class QuickActionsState {
  final bool isLoading;
  final bool isEditing;
  final bool isSaving;
  final List<String> keys;

  const QuickActionsState({
    this.isLoading = false,
    this.isEditing = false,
    this.isSaving = false,
    this.keys = kDefaultQuickActionKeys,
  });

  QuickActionsState copyWith({
    bool? isLoading,
    bool? isEditing,
    bool? isSaving,
    List<String>? keys,
  }) {
    return QuickActionsState(
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      keys: keys ?? this.keys,
    );
  }
}

final quickActionsApiProvider = Provider<QuickActionsApi>((ref) {
  final dio = ref.watch(dioProvider);
  return QuickActionsApi(dio);
});

final quickActionsProvider =
    StateNotifierProvider<QuickActionsNotifier, QuickActionsState>((ref) {
  final api = ref.watch(quickActionsApiProvider);
  final userId = ref.watch(currentUserProvider)?.effectiveUserId;
  return QuickActionsNotifier(ref, api, userId);
});

class QuickActionsNotifier extends StateNotifier<QuickActionsState> {
  final Ref _ref;
  final QuickActionsApi _api;
  final int? _userId;

  QuickActionsNotifier(this._ref, this._api, this._userId)
      : super(const QuickActionsState()) {
    _init();
  }

  static const _storageKeyPrefix = 'oa_quick_actions:';

  String _storageKey(int userId) => '$_storageKeyPrefix$userId';

  List<String> _sanitizeKeys(List<String> input) {
    final allowed = kAllHomeModules.map((e) => e.key).toSet();
    final result = <String>[];
    for (final raw in input) {
      final key = raw.trim();
      if (key.isEmpty) continue;
      if (!allowed.contains(key)) continue;
      if (result.contains(key)) continue;
      result.add(key);
    }
    return result;
  }

  Future<List<String>> _readLocal(int userId) async {
    try {
      final storage = await _ref.read(localStorageProvider.future);
      final raw = storage.getString(_storageKey(userId));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return const [];
    } catch (e) {
      debugPrint('[quick_actions] read local failed: $e');
      return const [];
    }
  }

  Future<void> _writeLocal(int userId, List<String> keys) async {
    try {
      final storage = await _ref.read(localStorageProvider.future);
      await storage.setString(_storageKey(userId), jsonEncode(keys));
    } catch (e) {
      debugPrint('[quick_actions] write local failed: $e');
    }
  }

  Future<void> _init() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true);

    // 先读取本地缓存（加速首屏）
    final local = _sanitizeKeys(await _readLocal(_userId));
    if (local.isNotEmpty) {
      state = state.copyWith(keys: local);
    }

    // 再拉取后端配置（以服务端为准）
    try {
      final res = await _api.getMyQuickActions();
      if (res.isSuccess && res.data != null) {
        final remote = _sanitizeKeys(res.data!);
        final keys = remote.isNotEmpty
            ? remote
            : (local.isNotEmpty ? local : kDefaultQuickActionKeys);
        state = state.copyWith(keys: keys);
        await _writeLocal(_userId, keys);
      } else {
        state = state.copyWith(
          keys: local.isNotEmpty ? local : kDefaultQuickActionKeys,
        );
      }
    } catch (e) {
      state = state.copyWith(
        keys: local.isNotEmpty ? local : kDefaultQuickActionKeys,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void setEditing(bool value) {
    state = state.copyWith(isEditing: value);
  }

  void reorder(int oldIndex, int newIndex) {
    final keys = [...state.keys];
    if (oldIndex < 0 || oldIndex >= keys.length) return;
    if (newIndex < 0 || newIndex >= keys.length) return;

    if (oldIndex < newIndex) newIndex -= 1;
    final item = keys.removeAt(oldIndex);
    keys.insert(newIndex, item);
    state = state.copyWith(keys: keys);
  }

  /// 将 [fromKey] 移动到 [toKey] 之前（用于按 key 拖拽排序）
  void moveKey(String fromKey, String toKey) {
    if (fromKey == toKey) return;

    final keys = [...state.keys];
    final fromIndex = keys.indexOf(fromKey);
    final toIndex = keys.indexOf(toKey);
    if (fromIndex < 0 || toIndex < 0) return;

    keys.removeAt(fromIndex);
    final insertIndex = fromIndex < toIndex ? toIndex - 1 : toIndex;
    keys.insert(insertIndex, fromKey);
    state = state.copyWith(keys: keys);
  }

  void addKey(String key) {
    final sanitized = _sanitizeKeys([key]);
    if (sanitized.isEmpty) return;
    final k = sanitized.first;
    if (state.keys.contains(k)) return;
    if (state.keys.length >= kAllHomeModules.length) return;
    state = state.copyWith(keys: [...state.keys, k]);
  }

  void removeKey(String key) {
    state = state.copyWith(keys: state.keys.where((k) => k != key).toList());
  }

  Future<bool> save() async {
    if (_userId == null) return false;
    final keys = _sanitizeKeys(state.keys);
    state = state.copyWith(isSaving: true);
    try {
      // 先本地落盘（避免网络失败导致丢失）
      await _writeLocal(_userId, keys);

      final res = await _api.saveMyQuickActions(keys);
      if (!res.isSuccess) return false;
      return true;
    } catch (e) {
      debugPrint('[quick_actions] save failed: $e');
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
