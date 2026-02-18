// 工作汇报列表页 - 对应 src/pages/work-report/index.vue + WorkReportCard.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/api/work_report_api.dart';
import '../../data/models/work_report_models.dart';

final _workReportApiProvider = Provider<WorkReportApi>((ref) {
  return WorkReportApi(ref.watch(dioProvider));
});

class WorkReportListPage extends ConsumerStatefulWidget {
  const WorkReportListPage({super.key});

  @override
  ConsumerState<WorkReportListPage> createState() => _WorkReportListPageState();
}

class _WorkReportListPageState extends ConsumerState<WorkReportListPage> {
  List<WorkReportVo> _reports = [];
  bool _isLoading = true;
  String _filterPeriod = 'all';

  static const _periodFilters = [
    ('all', '全部'),
    ('weekly', '周报'),
    ('monthly', '月报'),
    ('yearly', '年报'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(_workReportApiProvider);
      final period = _filterPeriod == 'all' ? null : _filterPeriod;
      final res = await api.getList(period: period);
      if (res.isSuccess) {
        final sorted = List<WorkReportVo>.from(res.rows ?? []);
        sorted.sort((a, b) =>
            (b.createTime ?? '').compareTo(a.createTime ?? ''));
        setState(() => _reports = sorted);
      }
    } catch (e) { debugPrint('[work_report_list_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('工作汇报'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await context.push('/work-report/publish');
              if (result == true) _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reports.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _buildReportCard(_reports[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _periodFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = _periodFilters[index];
          final isActive = _filterPeriod == value;
          return GestureDetector(
            onTap: () {
              if (_filterPeriod != value) {
                setState(() => _filterPeriod = value);
                _loadData();
              }
            },
            child: Chip(
              label: Text(label),
              backgroundColor:
                  isActive ? const Color(0xFF007AFF) : const Color(0xFFF3F4F6),
              labelStyle: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
              ),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 60, color: Color(0xFFC7C7CC)),
          SizedBox(height: 12),
          Text('暂无工作汇报',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildReportCard(WorkReportVo report) {
    final period = report.periodEnum;
    final tagColor = switch (period) {
      WorkReportPeriod.weekly => const Color(0xFF007AFF),
      WorkReportPeriod.monthly => const Color(0xFFFF9500),
      WorkReportPeriod.yearly => const Color(0xFF34C759),
    };

    return GestureDetector(
      onTap: () {
        if (report.id != null) {
          context.push('/work-report/detail?id=${report.id}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title ?? '无标题',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          period.label,
                          style: TextStyle(fontSize: 11, color: tagColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(report.createTime),
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFC7C7CC), size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${d.month}月${d.day}日';
  }
}
