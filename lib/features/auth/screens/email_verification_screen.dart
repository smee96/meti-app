import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _tokenCtrl = TextEditingController();
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _email = args['email'] as String?;
      // v3.0 보안패치: verify_token 수신 제거
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      showErrorSnackBar(context, '인증 토큰을 입력해주세요');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(token);

    if (!mounted) return;
    if (success) {
      showSuccessSnackBar(context, '이메일 인증이 완료되었습니다!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      showErrorSnackBar(context, auth.errorMessage ?? '인증에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증')),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return LoadingOverlay(
              isLoading: auth.isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '이메일을 확인해주세요',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _email != null
                          ? '$_email\n으로 인증 링크를 발송했습니다.\n이메일의 인증 코드를 입력해주세요.'
                          : '이메일로 발송된 인증 코드를 입력해주세요.',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _tokenCtrl,
                      decoration: const InputDecoration(
                        labelText: '인증 토큰',
                        hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleVerify,
                      child: const Text('인증 완료'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, AppRoutes.login),
                      child: const Text('로그인 화면으로 돌아가기'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
