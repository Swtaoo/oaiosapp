import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/api/approval_api.dart';
import '../data/models/approval_models.dart';

/// Approval API Provider
final approvalApiProvider = Provider<ApprovalApi>((ref) {
  final dio = ref.watch(dioProvider);
  return ApprovalApi(dio);
});

/// 审批轮询状态
class ApprovalPollingState {
  final Set<int> notifiedIds;
  final bool isPolling;
  final bool isForeground;

  const ApprovalPollingState({
    this.notifiedIds = const {},
    this.isPolling = false,
    this.isForeground = true,
  });

  ApprovalPollingState copyWith({
    Set<int>? notifiedIds,
    bool? isPolling,
    bool? isForeground,
  }) {
    return ApprovalPollingState(
      notifiedIds: notifiedIds ?? this.notifiedIds,
      isPolling: isPolling ?? this.isPolling,
      isForeground: isForeground ?? this.isForeground,
    );
  }
}

/// 审批轮询管理 - 对应 src/store/approval.ts
class ApprovalPollingNotifier extends StateNotifier<ApprovalPollingState> {
  final Ref _ref;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 5);
  static const _initialDelay = Duration(seconds: 5);

  ApprovalPollingNotifier(this._ref) : super(const ApprovalPollingState());

  bool get _isAdmin => _ref.read(isAdminProvider);

  void startPolling() {
    if (state.isPolling) return;
    state = state.copyWith(isPolling: true);

    Timer(_initialDelay, () async {
      await _checkPendingApprovals();
      _scheduleNextPoll();
    });
  }

  void stopPolling() {
    state = state.copyWith(isPolling: false);
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void setForeground(bool value) {
    state = state.copyWith(isForeground: value);
    if (state.isPolling) {
      _pollTimer?.cancel();
      _scheduleNextPoll();
    }
  }

  void clearNotifiedIds() {
    state = state.copyWith(notifiedIds: {});
  }

  void _scheduleNextPoll() {
    if (!state.isPolling) return;
    _pollTimer = Timer(_pollInterval, () async {
      await _checkPendingApprovals();
      _scheduleNextPoll();
    });
  }

  Future<void> _checkPendingApprovals() async {
    if (!_isAdmin) return;

    try {
      final api = _ref.read(approvalApiProvider);
      final res = await api.getMyPending(pageNum: 1, pageSize: 50);

      if (res.isSuccess && res.rows != null) {
        final newIds = Set<int>.from(state.notifiedIds);
        bool hasNew = false;

        for (final item in res.rows!) {
          final id = item.id;
          if (id != null && !newIds.contains(id)) {
            newIds.add(id);
            hasNew = true;
            // TODO: 发送本地通知
          }
        }

        if (hasNew) {
          state = state.copyWith(notifiedIds: newIds);
        }
      }
    } catch (e) { debugPrint('[approval_provider] Error: $e');
      // 轮询失败静默忽略
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

/// 审批轮询 Provider
final approvalPollingProvider =
    StateNotifierProvider<ApprovalPollingNotifier, ApprovalPollingState>((ref) {
  return ApprovalPollingNotifier(ref);
});

/// 待审批列表状态
class ApprovalListState {
  final List<ApprovalFlowVo> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? filterType;
  final String searchQuery;
  /// objectId -> fundProject 名称（仅 type='1' 资金申请）
  final Map<int, String> fundProjectNames;
  /// objectId -> fundCostDesc 资金费用说明（仅 type='1' 资金申请）
  final Map<int, String> fundCostDescs;

  const ApprovalListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.filterType,
    this.searchQuery = '',
    this.fundProjectNames = const {},
    this.fundCostDescs = const {},
  });

  ApprovalListState copyWith({
    List<ApprovalFlowVo>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? Function()? filterType,
    String? searchQuery,
    Map<int, String>? fundProjectNames,
    Map<int, String>? fundCostDescs,
  }) {
    return ApprovalListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filterType: filterType != null ? filterType() : this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
      fundProjectNames: fundProjectNames ?? this.fundProjectNames,
      fundCostDescs: fundCostDescs ?? this.fundCostDescs,
    );
  }
}

/// 待审批列表管理
class ApprovalListNotifier extends StateNotifier<ApprovalListState> {
  final Ref _ref;
  static const _pageSize = 10;

  ApprovalListNotifier(this._ref) : super(const ApprovalListState());

  ApprovalApi get _api => _ref.read(approvalApiProvider);

  int get _currentUserId =>
      _ref.read(currentUserProvider)?.effectiveUserId ?? 0;

  /// 设置筛选类型并刷新
  Future<void> setFilter(String? filterType) async {
    state = state.copyWith(filterType: () => filterType);
    await refresh();
  }

  /// 设置搜索关键字并刷新
  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    await refresh();
  }

  /// 刷新（重置加载第一页）
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, currentPage: 0, hasMore: true);
    try {
      final query = state.searchQuery.trim();
      final res = await _api.getMyPending(
        filterType: state.filterType,
        applicantName: query.isNotEmpty ? query : null,
        pageNum: 1,
        pageSize: _pageSize,
      );
      if (res.isSuccess && res.rows != null) {
        var filtered = res.rows!.where((e) => !e.isDeleted).toList();
        // 先渲染列表，再异步纠正 displayStatus
        state = state.copyWith(
          items: filtered,
          isLoading: false,
          currentPage: 1,
          hasMore: filtered.length >= _pageSize,
        );
        // 异步纠正 displayStatus（后端 bug 补偿）
        _correctDisplayStatuses(filtered);
        // 异步加载资金项目名称
        _loadFundProjectNames(filtered);
      } else {
        state = state.copyWith(isLoading: false, items: []);
      }
    } catch (e) { debugPrint('[approval_provider] Error: $e');
      state = state.copyWith(isLoading: false, items: []);
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final nextPage = state.currentPage + 1;
    try {
      final query = state.searchQuery.trim();
      final res = await _api.getMyPending(
        filterType: state.filterType,
        applicantName: query.isNotEmpty ? query : null,
        pageNum: nextPage,
        pageSize: _pageSize,
      );
      if (res.isSuccess && res.rows != null) {
        final filtered = res.rows!.where((e) => !e.isDeleted).toList();
        final allItems = [...state.items, ...filtered];
        state = state.copyWith(
          items: allItems,
          isLoading: false,
          currentPage: nextPage,
          hasMore: filtered.length >= _pageSize,
        );
        // 异步纠正新加载项的 displayStatus
        _correctDisplayStatuses(allItems);
        // 异步加载新项的资金项目名称
        _loadFundProjectNames(filtered);
      } else {
        state = state.copyWith(isLoading: false, hasMore: false);
      }
    } catch (e) { debugPrint('[approval_provider] Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 异步加载资金申请的项目名称和费用说明（type='1' 的项）
  Future<void> _loadFundProjectNames(List<ApprovalFlowVo> items) async {
    final fundItems = items.where((item) =>
        item.approvalObjectType == '1' &&
        item.objectId != null &&
        !state.fundProjectNames.containsKey(item.objectId)).toList();

    if (fundItems.isEmpty) return;

    // 去重
    final seen = <int>{};
    final uniqueItems = <ApprovalFlowVo>[];
    for (final item in fundItems) {
      if (seen.add(item.objectId!)) uniqueItems.add(item);
    }

    final futures = uniqueItems.map((item) async {
      try {
        final res = await _api.getFundApplication(item.objectId!);
        if (res.isSuccess && res.data != null) {
          return MapEntry(item.objectId!, res.data!);
        }
      } catch (e) {
        debugPrint('[approval_provider] _loadFundProjectNames error: $e');
      }
      return null;
    });

    final results = await Future.wait(futures);

    final newNames = Map<int, String>.from(state.fundProjectNames);
    final newDescs = Map<int, String>.from(state.fundCostDescs);
    bool changed = false;
    for (final entry in results) {
      if (entry != null) {
        final fund = entry.value;
        if (fund.fundProject != null && fund.fundProject!.isNotEmpty) {
          newNames[entry.key] = fund.fundProject!;
          changed = true;
        }
        if (fund.fundCostDesc != null && fund.fundCostDesc!.isNotEmpty) {
          newDescs[entry.key] = fund.fundCostDesc!;
          changed = true;
        }
      }
    }

    if (changed && mounted) {
      state = state.copyWith(
        fundProjectNames: newNames,
        fundCostDescs: newDescs,
      );
    }
  }

  /// 后端 bug 补偿：并发加载审批流程，按顺序找第一个待审批节点纠正 displayStatus。
  /// - 第一个待审批节点的审批人是当前用户 → myPending
  /// - 第一个待审批节点的审批人不是当前用户 → pending
  /// - 所有节点都已处理 → 保留后端原始 displayStatus（approved/paid）
  Future<void> _correctDisplayStatuses(List<ApprovalFlowVo> items) async {
    final userId = _currentUserId;
    if (userId <= 0) return;

    // 找出需要校验的项（已经是 myPending 的不需要再校验）
    final pendingItems = items.where((item) =>
        item.displayStatus != 'myPending' &&
        item.objectId != null &&
        item.approvalObjectType != null).toList();

    if (pendingItems.isEmpty) return;

    // 去重：同一 objectId+type 只查一次
    final seen = <String>{};
    final uniqueItems = <ApprovalFlowVo>[];
    for (final item in pendingItems) {
      final key = '${item.approvalObjectType}_${item.objectId}';
      if (seen.add(key)) uniqueItems.add(item);
    }

    // 并发加载审批流程
    final futures = uniqueItems.map((item) async {
      try {
        final flowRes = await _api.getApprovalFlowList(
          approvalObjectType: item.approvalObjectType!,
          objectId: item.objectId!,
          pageSize: 20,
        );
        if (flowRes.isSuccess && flowRes.rows != null) {
          final nodes = flowRes.rows!.where((n) => !n.isDeleted).toList();
          final key = '${item.approvalObjectType}_${item.objectId}';

          // 按顺序找第一个待审批节点（节点已按 createTime asc 排序）
          for (final node in nodes) {
            final s = node.status;
            if (s == '0' || s == null || s.isEmpty) {
              // 找到了第一个待审批节点
              if (node.approverId == userId) {
                return MapEntry(key, 'myPending');
              }
              // 不是当前用户 → 待审批
              return MapEntry(key, 'pending');
            }
          }
          // 所有节点都已处理，保留后端原始 displayStatus
        }
      } catch (e) {
        debugPrint('[approval_provider] _correctDisplayStatuses error: $e');
      }
      return null;
    });

    final results = await Future.wait(futures);

    // 构建纠正映射
    final corrections = <String, String>{};
    for (final entry in results) {
      if (entry != null) corrections[entry.key] = entry.value;
    }

    if (corrections.isEmpty || !mounted) return;

    // 应用纠正
    final corrected = state.items.map((item) {
      final key = '${item.approvalObjectType}_${item.objectId}';
      final correctedStatus = corrections[key];
      if (correctedStatus != null && item.displayStatus != correctedStatus) {
        return item.withDisplayStatus(correctedStatus);
      }
      return item;
    }).toList();

    state = state.copyWith(items: corrected);
  }
}

/// 审批列表 Provider
final approvalListProvider =
    StateNotifierProvider<ApprovalListNotifier, ApprovalListState>((ref) {
  return ApprovalListNotifier(ref);
});
