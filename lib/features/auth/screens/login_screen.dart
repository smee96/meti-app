import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      // v2.5: 로그인 성공 후 pending 초대 토큰 확인
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString('pending_invite_token');
      if (!mounted) return;
      if (pendingToken != null && pendingToken.isNotEmpty) {
        // pending 초대 토큰 있으면 InviteJoinScreen으로
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.inviteJoin,
          arguments: {'token': pendingToken},
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } else {
      showErrorSnackBar(context, auth.errorMessage ?? '로그인에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return LoadingOverlay(
              isLoading: auth.isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      // Logo
                      const Center(child: ElidLogo(size: 64)),
                      const SizedBox(height: 48),

                      // Title
                      const Text('로그인', style: AppTextStyles.h1),
                      const SizedBox(height: 8),
                      const Text(
                        '비즈니스 네트워킹을 시작해보세요',
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(height: 36),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요';
                          if (!v.contains('@')) return '이메일에 @가 포함되어야 합니다';
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(v.trim())) {
                            return '올바른 이메일 형식이 아닙니다';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          hintText: '8자 이상',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                          if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.forgotPassword),
                          child: const Text('비밀번호를 잊으셨나요?'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        child: const Text('로그인'),
                      ),
                      const SizedBox(height: 16),

                      // Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('아직 계정이 없으신가요?', style: AppTextStyles.body2),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.register),
                            child: const Text('회원가입'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
