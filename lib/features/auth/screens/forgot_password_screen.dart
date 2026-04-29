import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      showErrorSnackBar(context, '이메일을 입력해주세요');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(email);

    if (!mounted) return;
    if (success) {
      setState(() => _sent = true);
    } else {
      showErrorSnackBar(context, auth.errorMessage ?? '오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return LoadingOverlay(
              isLoading: auth.isLoading,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _sent ? _buildSentView() : _buildFormView(auth),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormView(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.lock_reset, size: 60, color: AppColors.primary),
        const SizedBox(height: 24),
        const Text('비밀번호 재설정', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          '가입하신 이메일로 재설정 링크를 보내드립니다.',
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '이메일',
            hintText: 'example@email.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: auth.isLoading ? null : _handleSubmit,
          child: const Text('재설정 링크 발송'),
        ),
      ],
    );
  }

  Widget _buildSentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.mark_email_read, size: 72, color: AppColors.success),
        const SizedBox(height: 24),
        const Text('이메일 발송 완료', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          '${_emailCtrl.text}\n으로 재설정 링크를 발송했습니다.',
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          child: const Text('로그인으로 이동'),
        ),
      ],
    );
  }
}
