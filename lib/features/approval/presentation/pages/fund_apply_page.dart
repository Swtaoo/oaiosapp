import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/approval_models.dart';
import '../../providers/approval_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../project/data/models/project_models.dart';
import '../../../project/providers/project_providers.dart';
import '../../../register/presentation/widgets/oss_upload.dart';

/// 资金申请页 - 对应 src/pages/approval/apply.vue
class FundApplyPage extends ConsumerStatefulWidget {
  const FundApplyPage({super.key});

  @override
  ConsumerState<FundApplyPage> createState() => _FundApplyPageState();
}

class _FundApplyPageState extends ConsumerState<FundApplyPage> {
  final _applyDepartmentCtrl = TextEditingController();
  final _applicantCtrl = TextEditingController();
  final _applyAmountCtrl = TextEditingController();
  final _fundCostDescCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final List<String> _attachmentUrls = [];
  bool _submitting = false;

  List<ProjectInfoVo> _projects = [];
  ProjectInfoVo? _selectedProject;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserContext();
    _loadProjects();
  }

  @override
  void dispose() {
    _applyDepartmentCtrl.dispose();
    _applicantCtrl.dispose();
    _applyAmountCtrl.dispose();
    _fundCostDescCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    super.dispose();
  }

  String get _applicantName {
    final fromForm = _applicantCtrl.text.trim();
    if (fromForm.isNotEmpty) return fromForm;
    return ref.read(currentUserProvider)?.displayName.trim() ?? '';
  }

  Future<void> _loadCurrentUserContext() async {
    final currentUser = ref.read(currentUserProvider);
    final userId = currentUser?.effectiveUserId ?? -1;
    final userName = currentUser?.displayName.trim() ?? '';

    if (userName.isNotEmpty) {
      _applicantCtrl.text = userName;
    }
    if (userId <= 0) return;
    if (_applyDepartmentCtrl.text.trim().isNotEmpty) return;

    try {
      final api = ref.read(approvalApiProvider);
      final res = await api.getPersonnelList(pageSize: 1000);
      if (!res.isSuccess || res.rows == null) return;

      String department = '';
      for (final person in res.rows!) {
        if (person.id == userId) {
          department = person.department?.trim() ?? '';
          break;
        }
      }
      if (department.isNotEmpty) {
        _applyDepartmentCtrl.text = department;
      }
    } catch (e) {
      debugPrint('[fund_apply_page] _loadCurrentUserContext error: $e');
    }
  }

  Future<void> _loadProjects() async {
    try {
      final api = ref.read(projectApiProvider);
      final res = await api.getProjectList();
      if (res.isSuccess && res.rows != null && mounted) {
        setState(() {
          _projects = res.rows!.where((p) => p.delFlag != 2).toList();
        });
      }
    } catch (e) { debugPrint('[fund_apply_page] _loadProjects error: $e'); }
  }

  bool _validate() {
    if (_applyDepartmentCtrl.text.trim().isEmpty) {
      _showToast('未获取到当前用户部门');
      return false;
    }
    if (_applicantName.isEmpty) {
      _showToast('未获取到当前用户');
      return false;
    }
    final amount = double.tryParse(_applyAmountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      _showToast('请输入有效的申请金额');
      return false;
    }
    if (_selectedProject == null) {
      _showToast('请选择申请资金项目');
      return false;
    }
    return true;
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.warning),
    );
  }

  Future<void> _handleSubmit() async {
    await _loadCurrentUserContext();
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      final api = ref.read(approvalApiProvider);
      final data = FundApplicationSubmit(
        applyDepartment: _applyDepartmentCtrl.text.trim(),
        applicant: _applicantName,
        applyAmount: double.parse(_applyAmountCtrl.text.trim()),
        fundProject: _selectedProject!.projectName ?? '',
        fundCostDesc: _fundCostDescCtrl.text.trim(),
        accountName: _accountNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        contactPerson: _contactPersonCtrl.text.trim(),
        attachment: _attachmentUrls.isEmpty ? null : _attachmentUrls.join(','),
      );
      final res = await api.createFundApplication(data);
      if (res.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('提交成功'),
            backgroundColor: AppColors.success,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('提交失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('资金申请')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            // 基本信息
            _buildCard(
              title: '申请金额',
              hint: '必填',
              children: [
                _textField(
                  _applyAmountCtrl,
                  '请输入金额',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 申请项目明细
            _buildCard(
              title: '申请项目明细',
              children: [
                _buildFormField(
                  label: '申请资金项目',
                  required: true,
                  child: _buildProjectSelector(),
                ),
                _buildFormField(
                  label: '申请资金费用',
                  child: _textArea(
                    _fundCostDescCtrl,
                    '如：合同总价12000元，本次付定金3600元',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 采购商账户信息
            _buildCard(
              title: '采购商账户信息',
              children: [
                _buildFormField(
                  label: '账户名',
                  child: _textField(_accountNameCtrl, '请输入公司名称'),
                ),
                _buildFormField(
                  label: '银行账号',
                  child: _textField(_accountNumberCtrl, '请输入银行账号'),
                ),
                _buildFormField(
                  label: '开户行',
                  child: _textField(_bankNameCtrl, '请输入开户行'),
                ),
                _buildFormField(
                  label: '联系人',
                  child: _textField(_contactPersonCtrl, '请输入联系人'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 附件
            _buildCard(
              title: '附件',
              children: [
                _buildFormField(
                  label: '上传附件（可选）',
                  child: OssUpload(
                    maxCount: 5,
                    addButtonText: '上传图片',
                    onSuccess: (result) {
                      if (_attachmentUrls.contains(result.url)) return;
                      setState(() => _attachmentUrls.add(result.url));
                    },
                    onRemove: (item) {
                      setState(() => _attachmentUrls.remove(item.url));
                    },
                  ),
                ),
                if (_attachmentUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '已上传 ${_attachmentUrls.length} 张',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      // 底部提交按钮
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _submitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              elevation: 2,
              shadowColor: AppColors.primary.withValues(alpha: 0.24),
            ),
            child: Text(
              _submitting ? '提交中...' : '提交申请',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title, String? hint, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE5E5EA),
                    width: 0.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 12,
                          color: hint.contains('必填')
                              ? AppColors.error
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormField(
      {required String label, bool required = false, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                children: required
                    ? [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildProjectSelector() {
    return GestureDetector(
      onTap: _showProjectPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedProject?.projectName ?? '请选择资金项目',
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedProject != null
                      ? Colors.black
                      : AppColors.textPlaceholder,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectPicker() {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = query.isEmpty
                ? _projects
                : _projects.where((p) {
                    final name = (p.projectName ?? '').toLowerCase();
                    return name.contains(query);
                  }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (ctx, scrollCtrl) {
                return Column(
                  children: [
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Text(
                            '选择资金项目',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(
                              Icons.close,
                              size: 22,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 搜索框
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: '搜索项目名称',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPlaceholder,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF2F2F7),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 列表
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                '暂无匹配项目',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length,
                              separatorBuilder: (_, i) => Divider(
                                height: 0.5,
                                color: AppColors.separatorNonOpaque,
                              ),
                              itemBuilder: (ctx, index) {
                                final project = filtered[index];
                                final isSelected =
                                    _selectedProject?.id == project.id;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    project.projectName ?? '-',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: project.projectStatus != null
                                      ? Text(
                                          project.projectStatus!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textTertiary,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 20,
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() => _selectedProject = project);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _textField(TextEditingController ctrl, String placeholder,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: AppColors.textPlaceholder),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      style: const TextStyle(fontSize: 15, color: Colors.black),
    );
  }

  Widget _textArea(TextEditingController ctrl, String placeholder) {
    return TextField(
      controller: ctrl,
      maxLines: 4,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: AppColors.textPlaceholder),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.all(12),
        counterStyle:
            TextStyle(fontSize: 12, color: AppColors.textTertiary),
      ),
      style: const TextStyle(fontSize: 15, color: Colors.black, height: 1.6),
    );
  }

}
