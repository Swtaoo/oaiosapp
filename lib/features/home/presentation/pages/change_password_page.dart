// 修改密码页 - 对应 src/pages/me/changePassword.vue

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/providers/auth_provider.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPwdCtl = TextEditingController();
  final _newPwdCtl = TextEditingController();
  final _confirmPwdCtl = TextEditingController();

  bool _isSubmitting = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  bool get _canSubmit {
    return !_isSubmitting &&
        _oldPwdCtl.text.trim().isNotEmpty &&
        _newPwdCtl.text.trim().isNotEmpty &&
        _confirmPwdCtl.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _oldPwdCtl.addListener(_handleInputChanged);
    _newPwdCtl.addListener(_handleInputChanged);
    _confirmPwdCtl.addListener(_handleInputChanged);
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showSnack(String msg) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _autoValidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    try {
      final api = ref.read(authApiProvider);

      final request = UpdatePasswordRequest(
        oldPassword: _oldPwdCtl.text,
        newPassword: _newPwdCtl.text,
      );

      final res = await api.updatePassword(request);
      if (res.isSuccess) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '修改成功',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: Text(
                '登录密码已更新，下次登录请使用新密码。',
                textAlign: TextAlign.center,
                style: AppTypography.subheadline.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('我知道了'),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) _showSnack(res.errorMessage);
      }
    } catch (e) {
      if (mounted) _showSnack('修改失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _oldPwdCtl.removeListener(_handleInputChanged);
    _newPwdCtl.removeListener(_handleInputChanged);
    _confirmPwdCtl.removeListener(_handleInputChanged);
    _oldPwdCtl.dispose();
    _newPwdCtl.dispose();
    _confirmPwdCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardVisible = bottomInset > 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundGroupedPrimary,
      appBar: AppBar(title: const Text('修改密码')),
      bottomNavigationBar: isKeyboardVisible ? null : _buildBottomActionBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.s12,
            AppSpacing.pagePadding,
            AppSpacing.s24,
          ).copyWith(bottom: AppSpacing.s24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Text(
                  '请填写当前密码并设置新的登录密码。修改后，下次登录请使用新密码。',
                  style: AppTypography.subheadline.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '密码信息',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              _buildFormCard(),
              const SizedBox(height: AppSpacing.s12),
              _buildInlineNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPasswordField(
              label: '原密码',
              hint: '请输入当前登录密码',
              controller: _oldPwdCtl,
              obscureText: _obscureOldPassword,
              onToggleVisibility: () {
                setState(() => _obscureOldPassword = !_obscureOldPassword);
              },
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return '请输入原密码';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.neutral200,
            ),
            _buildPasswordField(
              label: '新密码',
              hint: '请输入新密码（至少 6 位）',
              controller: _newPwdCtl,
              obscureText: _obscureNewPassword,
              onToggleVisibility: () {
                setState(() => _obscureNewPassword = !_obscureNewPassword);
              },
              validator: (value) {
                final currentValue = (value ?? '').trim();
                if (currentValue.isEmpty) {
                  return '请输入新密码';
                }
                if (currentValue.length < 6) {
                  return '新密码至少 6 位';
                }
                if (currentValue == _oldPwdCtl.text.trim()) {
                  return '新密码不能与原密码相同';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.neutral200,
            ),
            _buildPasswordField(
              label: '确认密码',
              hint: '请再次输入新密码',
              controller: _confirmPwdCtl,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
              validator: (value) {
                final currentValue = (value ?? '').trim();
                if (currentValue.isEmpty) {
                  return '请再次输入新密码';
                }
                if (currentValue != _newPwdCtl.text.trim()) {
                  return '两次输入的密码不一致';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              onSubmitted: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              '建议使用 6 位以上的新密码，并避免与原密码相同。',
              style: AppTypography.caption1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required TextInputAction textInputAction,
    Future<void> Function()? onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: AppTypography.caption1.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            obscuringCharacter: '•',
            scrollPadding: const EdgeInsets.only(bottom: 140),
            textInputAction: textInputAction,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onFieldSubmitted: (_) async {
              if (onSubmitted != null) {
                await onSubmitted();
              }
            },
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.callout.copyWith(
                color: AppColors.textPlaceholder,
              ),
              suffixIcon: IconButton(
                tooltip: obscureText ? '显示密码' : '隐藏密码',
                splashRadius: 18,
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.4,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.2,
                ),
              ),
              errorStyle: AppTypography.caption1.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: const Border(
          top: BorderSide(color: AppColors.neutral200, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.45,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isSubmitting
                        ? Row(
                            key: const ValueKey('loading'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              Text(
                                '提交中...',
                                style: AppTypography.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            key: const ValueKey('label'),
                            '确定修改',
                            style: AppTypography.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                '提交前请确认两次输入的新密码保持一致。',
                textAlign: TextAlign.center,
                style: AppTypography.caption1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
