import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/approval_models.dart';
import '../../data/utils/approval_utils.dart';
import '../../providers/approval_provider.dart';

/// 工资明细页 - 对应 src/pages/approval/salaryDetail.vue
class SalaryDetailPage extends ConsumerStatefulWidget {
  final int detailId;

  const SalaryDetailPage({super.key, required this.detailId});

  @override
  ConsumerState<SalaryDetailPage> createState() => _SalaryDetailPageState();
}

class _SalaryDetailPageState extends ConsumerState<SalaryDetailPage> {
  bool _isLoading = true;
  SalaryDetailVo? _detail;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(approvalApiProvider);
      final res = await api.getSalaryDetail(widget.detailId);
      if (res.isSuccess && res.data != null) {
        _detail = res.data;
      }
    } catch (e) { debugPrint('[salary_detail_page] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取明细失败')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _detail?.employeeName != null
        ? '${_detail!.employeeName}的工资明细'
        : '工资明细';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _detail == null
              ? Center(
                  child: Text(
                    '暂无明细数据',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textTertiary),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSection('基础信息', [
                          _row('员工姓名', _detail!.employeeName ?? '-'),
                          if (_detail!.employeePosition != null)
                            _row('员工职位', _detail!.employeePosition!),
                        ]),
                        _buildSection('薪资构成', [
                          _row('基本工资',
                              '\u00A5${formatAmount(_detail!.basicSalary)}'),
                          _row('岗位工资',
                              '\u00A5${formatAmount(_detail!.positionSalary)}'),
                          _row('绩效工资',
                              '\u00A5${formatAmount(_detail!.performanceSalary)}'),
                          _row('岗位补贴',
                              '\u00A5${formatAmount(_detail!.positionSubsidy)}'),
                          _row('电脑补贴',
                              '\u00A5${formatAmount(_detail!.computerSubsidy)}'),
                          _row('其他补贴',
                              '\u00A5${formatAmount(_detail!.otherSubsidy)}'),
                          _row('住房补贴',
                              '\u00A5${formatAmount(_detail!.housingSubsidy)}'),
                          _row('午餐补贴',
                              '\u00A5${formatAmount(_detail!.lunchSubsidy)}'),
                          _highlightRow('应发工资',
                              '\u00A5${formatAmount(_detail!.payableSalary)}'),
                        ]),
                        _buildSection('扣款', [
                          _row('社保扣款',
                              '\u00A5${formatAmount(_detail!.socialSecurityDeduction)}'),
                          _row('考勤扣款',
                              '\u00A5${formatAmount(_detail!.attendanceDeduction)}'),
                          _row('公积金扣款',
                              '\u00A5${formatAmount(_detail!.housingFundDeduction)}'),
                          _row('个人所得税',
                              '\u00A5${formatAmount(_detail!.personalTaxDeduction)}'),
                          _row('扣款合计',
                              '\u00A5${formatAmount(_detail!.totalDeduction)}'),
                        ]),
                        _buildSection('实发', [
                          _highlightRow(
                            '实发工资',
                            '\u00A5${formatAmount(_detail!.actualSalary)}',
                            isAccent: true,
                          ),
                          if (_detail!.salaryRemark != null &&
                              _detail!.salaryRemark!.isNotEmpty)
                            _row('薪资备注', _detail!.salaryRemark!),
                        ]),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFF1F1F1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightRow(String label, String value, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isAccent ? const Color(0xFFFF6B6B) : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
