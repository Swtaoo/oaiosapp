import 'package:flutter/foundation.dart';
// 通知服务 - 对应 src/store/notification.ts
// 管理未读消息计数和通知展示

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 未读消息信息
class UnreadInfo {
  final int count;
  final String? lastContent;
  final String? lastSenderName;
  final int? lastTimestamp;
  final String? projectName;

  const UnreadInfo({
    this.count = 0,
    this.lastContent,
    this.lastSenderName,
    this.lastTimestamp,
    this.projectName,
  });

  Map<String, dynamic> toJson() => {
        'count': count,
        'lastContent': ?lastContent,
        'lastSenderName': ?lastSenderName,
        'lastTimestamp': ?lastTimestamp,
        'projectName': ?projectName,
      };

  factory UnreadInfo.fromJson(Map<String, dynamic> json) => UnreadInfo(
        count: json['count'] as int? ?? 0,
        lastContent: json['lastContent'] as String?,
        lastSenderName: json['lastSenderName'] as String?,
        lastTimestamp: json['lastTimestamp'] as int?,
        projectName: json['projectName'] as String?,
      );
}

/// 通知状态
class NotificationState {
  final Map<int, UnreadInfo> unreadMap;
  final int? currentViewingProjectId;
  final Map<int, String> projectNameCache;

  /// 当前用户所属的项目 ID 集合（null 表示尚未加载，放行所有）
  final Set<int>? myProjectIds;

  /// 当前用户是否为管理员（管理员跳过项目成员过滤）
  final bool isAdmin;

  const NotificationState({
    this.unreadMap = const {},
    this.currentViewingProjectId,
    this.projectNameCache = const {},
    this.myProjectIds,
    this.isAdmin = false,
  });

  int get totalUnread =>
      unreadMap.values.fold(0, (sum, info) => sum + info.count);

  int getUnreadCount(int projectId) =>
      unreadMap[projectId]?.count ?? 0;

  String getProjectName(int projectId) =>
      projectNameCache[projectId] ?? '项目$projectId';

  NotificationState copyWith({
    Map<int, UnreadInfo>? unreadMap,
    int? currentViewingProjectId,
    bool clearCurrentViewingProject = false,
    Map<int, String>? projectNameCache,
    Set<int>? myProjectIds,
    bool clearMyProjectIds = false,
    bool? isAdmin,
  }) {
    return NotificationState(
      unreadMap: unreadMap ?? this.unreadMap,
      currentViewingProjectId: clearCurrentViewingProject
          ? null
          : (currentViewingProjectId ?? this.currentViewingProjectId),
      projectNameCache: projectNameCache ?? this.projectNameCache,
      myProjectIds: clearMyProjectIds
          ? null
          : (myProjectIds ?? this.myProjectIds),
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// 通知状态管理
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState()) {
    _restoreFromStorage();
    _restoreMyProjectIds();
  }

  static const _storageKey = 'notification_unread';
  static const _myProjectIdsKey = 'my_project_ids';

  /// 检查是否为当前用户所属的项目
  /// 管理员放行所有；myProjectIds 尚未加载时（null）也放行，避免阻断正常使用
  bool isMyProject(int projectId) {
    if (state.isAdmin) return true;
    final ids = state.myProjectIds;
    return ids == null || ids.contains(projectId);
  }

  /// 获取当前用户的项目 ID 集合（供外部读取）
  Set<int>? get myProjectIds => state.myProjectIds;

  /// 设置/更新成员项目 ID 集合，同时清理非成员项目的 stale 未读记录
  void setMyProjectIds(Set<int> ids) {
    // 清理不属于用户的项目的未读记录
    final cleanedMap = Map<int, UnreadInfo>.from(state.unreadMap)
      ..removeWhere((projectId, _) => !ids.contains(projectId));

    state = state.copyWith(
      myProjectIds: ids,
      unreadMap: cleanedMap,
    );
    _saveMyProjectIds();
    _saveToStorage();
  }

  /// 设置管理员标记
  void setAdmin(bool value) {
    state = state.copyWith(isAdmin: value);
  }

  /// 清除成员项目 ID（退出登录时调用）
  void clearMyProjectIds() {
    state = state.copyWith(clearMyProjectIds: true, isAdmin: false);
    _removeMyProjectIds();
  }

  /// 设置当前查看的项目
  void setCurrentViewingProject(int? projectId) {
    if (projectId == null) {
      state = state.copyWith(clearCurrentViewingProject: true);
    } else {
      state = state.copyWith(currentViewingProjectId: projectId);
      clearUnread(projectId);
    }
  }

  /// 缓存项目名称
  void cacheProjectName(int projectId, String name) {
    state = state.copyWith(
      projectNameCache: {...state.projectNameCache, projectId: name},
    );
  }

  /// 处理 WebSocket 聊天消息
  void handleWebSocketMessage(Map<String, dynamic> message) {
    final projectId = message['projectId'] as int?;
    final personnelName = message['personnelName'] as String? ?? '未知用户';
    final content = message['content'] as String? ??
        message['chatContent'] as String? ??
        '[消息]';

    if (projectId == null) return;

    // 非本人所属项目的消息不计入未读
    if (!isMyProject(projectId)) return;

    // 正在查看该项目时不计未读
    if (state.currentViewingProjectId == projectId) return;

    final existing = state.unreadMap[projectId];
    final newMap = Map<int, UnreadInfo>.from(state.unreadMap);
    newMap[projectId] = UnreadInfo(
      count: (existing?.count ?? 0) + 1,
      lastContent: content,
      lastSenderName: personnelName,
      lastTimestamp: DateTime.now().millisecondsSinceEpoch,
      projectName: state.getProjectName(projectId),
    );

    state = state.copyWith(unreadMap: newMap);
    _saveToStorage();
  }

  /// 清除某个项目的未读
  void clearUnread(int projectId) {
    final newMap = Map<int, UnreadInfo>.from(state.unreadMap)
      ..remove(projectId);
    state = state.copyWith(unreadMap: newMap);
    _saveToStorage();
  }

  /// 清除所有未读
  void clearAllUnread() {
    state = state.copyWith(unreadMap: {});
    _saveToStorage();
  }

  /// 从本地存储恢复未读状态
  Future<void> _restoreFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored == null) return;

      final parsed = jsonDecode(stored) as Map<String, dynamic>;
      final map = <int, UnreadInfo>{};
      for (final entry in parsed.entries) {
        final key = int.tryParse(entry.key);
        if (key != null && entry.value is Map<String, dynamic>) {
          map[key] =
              UnreadInfo.fromJson(entry.value as Map<String, dynamic>);
        }
      }
      state = state.copyWith(unreadMap: map);
    } catch (e) { debugPrint('[notification_service] Error: $e'); }
  }

  /// 保存到本地存储
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final obj = <String, dynamic>{};
      for (final entry in state.unreadMap.entries) {
        obj[entry.key.toString()] = entry.value.toJson();
      }
      await prefs.setString(_storageKey, jsonEncode(obj));
    } catch (e) { debugPrint('[notification_service] Error: $e'); }
  }

  /// 持久化 myProjectIds 到 SharedPreferences
  Future<void> _saveMyProjectIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = state.myProjectIds;
      if (ids != null) {
        await prefs.setStringList(
          _myProjectIdsKey,
          ids.map((id) => id.toString()).toList(),
        );
      }
    } catch (e) {
      debugPrint('[notification_service] saveMyProjectIds error: $e');
    }
  }

  /// 从 SharedPreferences 移除 myProjectIds
  Future<void> _removeMyProjectIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_myProjectIdsKey);
    } catch (e) {
      debugPrint('[notification_service] removeMyProjectIds error: $e');
    }
  }

  /// 从本地存储恢复 myProjectIds（冷启动过渡期使用）
  Future<void> _restoreMyProjectIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_myProjectIdsKey);
      if (stored != null && stored.isNotEmpty) {
        final ids = stored
            .map((s) => int.tryParse(s))
            .whereType<int>()
            .toSet();
        state = state.copyWith(myProjectIds: ids);
      }
    } catch (e) {
      debugPrint('[notification_service] restoreMyProjectIds error: $e');
    }
  }

  /// 获取某个项目最后一条消息的摘要
  String getLastMessageSummary(int projectId) {
    final info = state.unreadMap[projectId];
    if (info == null) return '';
    final sender = info.lastSenderName ?? '';
    final content = info.lastContent ?? '';
    if (sender.isNotEmpty) return '$sender: $content';
    return content;
  }
}

/// 通知服务 Provider
final notificationServiceProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
