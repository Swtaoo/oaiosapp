// 修改密码页 - 对应 src/pages/me/changePassword.vue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../auth/providers/auth_provider.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _oldPwdCtl = TextEditingController();
  final _newPwdCtl = TextEditingController();
  final _confirmPwdCtl = TextEditingController();
  bool _isSubmitting = false;

  bool _validate() {
    if (_oldPwdCtl.text.isEmpty) {
      _showSnack('请输入原密码');
      return false;
    }
    if (_newPwdCtl.text.isEmpty) {
      _showSnack('请输入新密码');
      return false;
    }
    if (_newPwdCtl.text.length < 6) {
      _showSnack('新密码至少6位');
      return false;
    }
    if (_confirmPwdCtl.text.isEmpty) {
      _showSnack('请确认新密码');
      return false;
    }
    if (_newPwdCtl.text != _confirmPwdCtl.text) {
      _showSnack('两次密码不一致');
      return false;
    }
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleSubmit() async {
    if (!_validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(authApiProvider);

      final request = UpdatePasswordRequest(
        oldPassword: _oldPwdCtl.text,
        newPassword: _newPwdCtl.text,
      );

      final res = await api.updatePassword(request);
      if (res.isSuccess) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('提示'),
              content: const Text('密码修改成功'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
                  },
                  child: const Text('确定'),
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
    _oldPwdCtl.dispose();
    _newPwdCtl.dispose();
    _confirmPwdCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(title: const Text('修改密码')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildField('原密码', _oldPwdCtl, '请输入原密码'),
                  const Divider(height: 0.5, indent: 16),
                  _buildField('新密码', _newPwdCtl, '请输入新密码（至少6位）'),
                  const Divider(height: 0.5, indent: 16),
                  _buildField('确认密码', _confirmPwdCtl, '请再次输入新密码',
                      showDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF007AFF)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('确定修改',
                        style: TextStyle(
                            fontSize: 16, color: Color(0xFF007AFF))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, String hint,
      {bool showDivider = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 16, color: Color(0xFF333333))),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF999999)),
              ),
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }
}
