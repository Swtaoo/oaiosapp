import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/approval_models.dart';
import '../../providers/approval_provider.dart';
import '../../../register/presentation/widgets/oss_upload.dart';

/// 离职交接页
class ResignHandoverPage extends ConsumerStatefulWidget {
  const ResignHandoverPage({super.key});

  @override
  ConsumerState<ResignHandoverPage> createState() =>
      _ResignHandoverPageState();
}

class _ResignHandoverPageState extends ConsumerState<ResignHandoverPage> {
  final _itemsCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  final List<String> _attachmentUrls = [];
  final List<PersonnelBasicInfoVo> _receiverOptions = [];

  PersonnelBasicInfoVo? _selectedReceiver;
  bool _loadingReceiverOptions = false;
  bool _submitting = false;

  @override
  void dispose() {
    _itemsCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_itemsCtrl.text.trim().isEmpty) {
      _showToast('请输入交接说明');
      return false;
    }
    if (_selectedReceiver?.id == null) {
      _showToast('请选择承接人');
      return false;
    }
    final currentUserId = ref.read(currentUserProvider)?.effectiveUserId ?? -1;
    if (_selectedReceiver!.id == currentUserId) {
      _showToast('承接人不能选择自己');
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
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      // TODO: 对接后端 API
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('提交成功'),
            backgroundColor: AppColors.success,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.pop();
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

  Future<void> _loadReceiverOptions({bool force = false}) async {
    if (_loadingReceiverOptions) return;
    if (!force && _receiverOptions.isNotEmpty) return;

    setState(() => _loadingReceiverOptions = true);
    try {
      final currentUserId = ref.read(currentUserProvider)?.effectiveUserId ?? -1;
      final api = ref.read(approvalApiProvider);
      final res = await api.getPersonnelList(pageSize: 1000);
      if (!mounted) return;

      if (!res.isSuccess) {
        _showToast(res.msg ?? '获取人员列表失败');
        return;
      }

      final rows = (res.rows ?? const <PersonnelBasicInfoVo>[])
          .where(
            (item) => item.id != null && item.id != currentUserId,
          )
          .toList();
      setState(() {
        _receiverOptions
          ..clear()
          ..addAll(rows);
        if (_selectedReceiver?.id == currentUserId) {
          _selectedReceiver = null;
        }
      });
    } catch (e) {
      if (mounted) _showToast('获取人员列表失败');
    } finally {
      if (mounted) setState(() => _loadingReceiverOptions = false);
    }
  }

  Future<void> _showReceiverPicker() async {
    await _loadReceiverOptions();
    if (!mounted) return;

    String query = '';
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _receiverOptions.where((item) {
              final name = (item.name ?? '').toLowerCase();
              final department = (item.department ?? '').toLowerCase();
              return query.isEmpty ||
                  name.contains(query) ||
                  department.contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.35,
                maxChildSize: 0.85,
                expand: false,
                builder: (ctx, scrollCtrl) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Text(
                              '选择承接人',
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setModalState(() {
                              query = value.trim().toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: '搜索姓名/部门',
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
                              horizontal: 12,
                              vertical: 10,
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
                      Expanded(
                        child: _loadingReceiverOptions
                            ? const Center(child: CircularProgressIndicator())
                            : filtered.isEmpty
                            ? Center(
                                child: Text(
                                  '暂无可选人员',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 0.5,
                                  color: AppColors.separatorNonOpaque,
                                ),
                                itemBuilder: (ctx, index) {
                                  final item = filtered[index];
                                  final isSelected =
                                      _selectedReceiver?.id == item.id;
                                  final displayName =
                                      item.name?.trim().isNotEmpty == true
                                      ? item.name!.trim()
                                      : '未命名人员';
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      displayName,
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
                                    subtitle:
                                        (item.department?.isNotEmpty ?? false)
                                        ? Text(
                                            item.department!,
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
                                      setState(() => _selectedReceiver = item);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('离职交接')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          children: [
            _buildCard(
              title: '交接信息',
              children: [
                _buildInfoBanner(
                  '请在交接说明中填写账号、物品、工作等需交接内容，便于审批与后续跟进。',
                ),
                _buildFormField(
                  label: '交接说明',
                  required: true,
                  child: _textArea(
                    _itemsCtrl,
                    '请填写需交接的工作、物品、账号等内容',
                  ),
                ),
                _buildFormField(
                  label: '承接人',
                  required: true,
                  child: _buildSelector(
                    value: _selectedReceiver?.name,
                    placeholder: '请选择承接人',
                    onTap: _showReceiverPicker,
                  ),
                ),
                _buildFormField(
                  label: '备注',
                  child: _textArea(_remarkCtrl, '请输入备注（选填）'),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      bottomNavigationBar: _buildSubmitBar(),
    );
  }

  // ========== 通用 UI 组件 ==========

  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
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

  Widget _buildFormField({
    required String label,
    bool required = false,
    required Widget child,
  }) {
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

  Widget _buildInfoBanner(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.primary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSelector({
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
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
                hasValue ? value : placeholder,
                style: TextStyle(
                  fontSize: 15,
                  color: hasValue ? Colors.black : AppColors.textPlaceholder,
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

  Widget _buildSubmitBar() {
    return Container(
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
    );
  }
}
