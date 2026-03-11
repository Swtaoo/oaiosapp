import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/approval_models.dart';
import '../../data/utils/approval_utils.dart';
import '../../providers/approval_provider.dart';

/// 筛选 Tab 定义
class _FilterTab {
  final String? filterType;
  final String label;

  const _FilterTab({this.filterType, required this.label});
}

const _tabs = [
  _FilterTab(label: '全部'),
  _FilterTab(filterType: 'myPending', label: '待我审批'),
  _FilterTab(filterType: 'pending', label: '待审批'),
  _FilterTab(filterType: 'approved', label: '已审批'),
  _FilterTab(filterType: 'paid', label: '已支付'),
];

/// 审批列表页
class ApprovalListPage extends ConsumerStatefulWidget {
  const ApprovalListPage({super.key});

  @override
  ConsumerState<ApprovalListPage> createState() => _ApprovalListPageState();
}

class _ApprovalListPageState extends ConsumerState<ApprovalListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 同步 Tab 选中状态与 provider 中的 filterType
      final currentFilter = ref.read(approvalListProvider).filterType;
      final index = _tabs.indexWhere((t) => t.filterType == currentFilter);
      if (index >= 0 && index != _selectedTabIndex) {
        setState(() => _selectedTabIndex = index);
      }
      ref.read(approvalListProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(approvalListProvider.notifier).loadMore();
    }
  }

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
    ref.read(approvalListProvider.notifier).setFilter(_tabs[index].filterType);
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(approvalListProvider.notifier).setSearchQuery(value);
    });
  }

  Color _getTypeTagColor(String? type) {
    switch (type) {
      case '1':
        return AppColors.primary;
      case '2':
        return AppColors.warning;
      case '3':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  void _onItemTap(ApprovalFlowVo item) {
    if (item.id == null || item.objectId == null) return;
    final type = item.approvalObjectType ?? '1';
    context.push(
      '/approval/detail?id=${item.objectId}&type=$type',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('审批列表')),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(),

          // 筛选 Tab 栏
          _buildFilterTabs(),

          // 列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(approvalListProvider.notifier).refresh(),
              child: state.items.isEmpty && !state.isLoading
                  ? _buildEmpty()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.items.length + (state.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildListItem(state.items[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索申请人',
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.textPlaceholder,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: AppColors.textTertiary,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (_, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: Icon(
                  Icons.clear,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              );
            },
          ),
          filled: true,
          fillColor: const Color(0xFFF2F2F7),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final isSelected = _selectedTabIndex == index;
          final color = tab.filterType != null
              ? getDisplayStatusColor(tab.filterType)
              : AppColors.primary;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == _tabs.length - 1 ? 0 : 4,
              ),
              child: GestureDetector(
                onTap: () => _onTabChanged(index),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.4)
                          : AppColors.separatorNonOpaque,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined,
                    size: 64, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                Text(
                  '暂无审批记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前没有任何审批流程',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(ApprovalFlowVo item) {
    final typeColor = _getTypeTagColor(item.approvalObjectType);
    // displayStatus 已在 provider 中纠正过（后端 bug 补偿）
    final displayStatus = item.displayStatus;

    // 资金申请动态显示具体项目名称
    final state = ref.watch(approvalListProvider);
    String typeLabel = getApprovalTypeText(item.approvalObjectType);
    if (item.approvalObjectType == '1' && item.objectId != null) {
      final projectName = state.fundProjectNames[item.objectId];
      if (projectName != null && projectName.isNotEmpty) {
        final display = projectName.length > 6
            ? '${projectName.substring(0, 6)}...'
            : projectName;
        typeLabel = '资金申请（$display）';
      }
    }

    return GestureDetector(
      onTap: () => _onItemTap(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：类型标签
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: typeColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // 申请人
            _buildInfoRow('申请人：', item.applicantName ?? item.approverName ?? '-'),
            // 资金申请显示费用明细
            if (item.approvalObjectType == '1' && item.objectId != null)
              _buildVerticalInfoRow(
                '申请资金费用明细：',
                state.fundCostDescs[item.objectId] ?? '-',
              ),

            const SizedBox(height: 8),

            // 底部：完整时间 + 箭头
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.separatorNonOpaque,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    formatDateTimeFull(item.createTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getDisplayStatusBgColor(displayStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      getDisplayStatusText(displayStatus),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: getDisplayStatusColor(displayStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
