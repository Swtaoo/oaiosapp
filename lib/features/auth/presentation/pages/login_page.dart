import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/auth_models.dart';
import '../../providers/auth_provider.dart';

/// 登录页面 - 对应 src/pages/login/index.vue
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _validatePhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone.trim());
  }

  bool _validatePassword(String password) {
    return password.trim().length >= 6;
  }

  bool _validateForm() {
    setState(() {
      _phoneError = null;
      _passwordError = null;
    });

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    bool isValid = true;

    if (phone.isEmpty) {
      setState(() => _phoneError = '请输入手机号');
      isValid = false;
    } else if (!_validatePhone(phone)) {
      setState(() => _phoneError = '请输入正确的手机号码');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = '请输入密码');
      isValid = false;
    } else if (!_validatePassword(password)) {
      setState(() => _passwordError = '密码长度不能少于6位');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleLogin() async {
    if (!_validateForm()) {
      final firstError = _phoneError ?? _passwordError ?? '请检查表单';
      _showToast(firstError);
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(authStateNotifierProvider.notifier).login(
            LoginRequest(
              phone: _phoneController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );

      if (mounted) {
        _showToast('登录成功', isSuccess: true);
        // GoRouter redirect 会自动跳转首页
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        _showToast('登录失败，请检查账号密码');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showToast(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : null,
        duration: Duration(milliseconds: isSuccess ? 1500 : 2000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 110),
              // Logo
              const Text(
                'OA',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 45),
              // 手机号输入
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 11,
                decoration: InputDecoration(
                  hintText: '手机号',
                  counterText: '',
                  errorText: _phoneError,
                ),
                onChanged: (value) {
                  // 只允许数字
                  final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                  if (digitsOnly != value) {
                    _phoneController.text = digitsOnly;
                    _phoneController.selection = TextSelection.fromPosition(
                      TextPosition(offset: digitsOnly.length),
                    );
                  }
                  if (_phoneError != null) {
                    setState(() => _phoneError = null);
                  }
                },
              ),
              const SizedBox(height: 13),
              // 密码输入
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '密码',
                  errorText: _passwordError,
                  suffixIcon: _passwordController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFFB0B0B0),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(
                                () => _obscurePassword = !_obscurePassword);
                          },
                        )
                      : null,
                ),
                onChanged: (_) {
                  setState(() {
                    if (_passwordError != null) _passwordError = null;
                  });
                },
                onSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 22),
              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    disabledBackgroundColor:
                        const Color(0xFF1677FF).withValues(alpha: 0.75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 22),
              // 创建账号
              TextButton(
                onPressed: () {
                  context.push('/register/basic');
                },
                child: const Text(
                  '创建账号',
                  style: TextStyle(
                    fontSize: 16.5,
                    color: Color(0xFF1677FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // 底部协议
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '登录即表示同意',
                style: TextStyle(fontSize: 11, color: Color(0xFFB0B0B0)),
              ),
              GestureDetector(
                onTap: () => _showToast('用户协议待补充'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '用户协议',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1677FF)),
                  ),
                ),
              ),
              Text(
                '和',
                style: TextStyle(fontSize: 11, color: Color(0xFFB0B0B0)),
              ),
              GestureDetector(
                onTap: () => _showToast('隐私政策待补充'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '隐私政策',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1677FF)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
