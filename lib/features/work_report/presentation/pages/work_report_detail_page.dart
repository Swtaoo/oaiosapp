// 工作汇报详情页 - 对应 src/pages/work-report/detail.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/api/work_report_api.dart';
import '../../data/models/work_report_models.dart';

final _workReportApiProvider = Provider<WorkReportApi>((ref) {
  return WorkReportApi(ref.watch(dioProvider));
});

class WorkReportDetailPage extends ConsumerStatefulWidget {
  final int reportId;

  const WorkReportDetailPage({super.key, required this.reportId});

  @override
  ConsumerState<WorkReportDetailPage> createState() =>
      _WorkReportDetailPageState();
}

class _WorkReportDetailPageState
    extends ConsumerState<WorkReportDetailPage> {
  WorkReportVo? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = ref.read(_workReportApiProvider);
      final res = await api.getDetail(widget.reportId);
      if (res.isSuccess && res.data != null) {
        setState(() => _report = res.data);
      }
    } catch (e) { debugPrint('[work_report_detail_page] Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('汇报详情')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? _buildEmpty()
              : _buildContent(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 60, color: Color(0xFFC7C7CC)),
          SizedBox(height: 12),
          Text('汇报不存在',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final report = _report!;
    final period = report.periodEnum;
    final tagColor = switch (period) {
      WorkReportPeriod.weekly => const Color(0xFF007AFF),
      WorkReportPeriod.monthly => const Color(0xFFFF9500),
      WorkReportPeriod.yearly => const Color(0xFF34C759),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 标题卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      report.reportDate ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report.title ?? '无标题',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '${report.personnelName ?? '未知'} · ${_formatTime(report.createTime)}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 内容卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('汇报内容',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(
                  report.content ?? '无内容',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF374151), height: 1.6),
                ),
              ],
            ),
          ),
          // 附件卡片
          if (report.attachments != null &&
              report.attachments!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '附件 (${report.attachments!.length})',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ...report.attachments!.map((att) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file,
                                size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                att.name ?? '未知文件',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF007AFF)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
