import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/password_policy_box.dart';

/// 비밀번호 변경 — PUT /auth/password
///
/// 로그인 상태에서만 진입한다. 서버가 현재 비밀번호를 검증하므로
/// 실패(400)는 폼 오류로 되돌리고 화면을 닫지 않는다.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // 한글 IME와 무관한 필드지만 회원가입 화면과 이동 방식을 맞춘다
  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String _newPassword = '';
  String _confirm = '';
  bool _submitting = false;

  PasswordPolicy get _policy => PasswordPolicy(_newPassword);
  bool get _confirmStarted => _confirm.isNotEmpty;
  bool get _confirmMatch => _newPassword == _confirm && _confirm.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() => setState(() => _newPassword = _newCtrl.text));
    _confirmCtrl.addListener(() => setState(() => _confirm = _confirmCtrl.text));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final error = await context.read<AuthProvider>().changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      showSuccessSnackBar(context, '비밀번호가 변경되었습니다.');
      Navigator.pop(context);
    } else {
      showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _submitting,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    '현재 비밀번호를 확인한 뒤\n새 비밀번호로 변경합니다.',
                    style: AppTextStyles.body2,
                  ),
                  const SizedBox(height: 24),

                  // ── 현재 비밀번호 ────────────────────────
                  TextFormField(
                    controller: _currentCtrl,
                    focusNode: _currentFocus,
                    obscureText: _obscureCurrent,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () {
                      _currentFocus.unfocus();
                      FocusScope.of(context).requestFocus(_newFocus);
                    },
                    decoration: InputDecoration(
                      labelText: '현재 비밀번호',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '현재 비밀번호를 입력해주세요';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── 새 비밀번호 ──────────────────────────
                  TextFormField(
                    controller: _newCtrl,
                    focusNode: _newFocus,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () {
                      _newFocus.unfocus();
                      FocusScope.of(context).requestFocus(_confirmFocus);
                    },
                    decoration: InputDecoration(
                      labelText: '새 비밀번호',
                      hintText: '8자 이상 영문+숫자 조합',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '새 비밀번호를 입력해주세요';
                      if (!_policy.allMet) return '비밀번호 정책을 모두 충족해야 합니다';
                      if (v == _currentCtrl.text) {
                        return '현재 비밀번호와 다른 비밀번호를 사용해주세요';
                      }
                      return null;
                    },
                  ),

                  if (_newPassword.isNotEmpty)
                    PasswordPolicyBox(policy: _policy),

                  const SizedBox(height: 16),

                  // ── 새 비밀번호 확인 ─────────────────────
                  TextFormField(
                    controller: _confirmCtrl,
                    focusNode: _confirmFocus,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSubmit(),
                    decoration: InputDecoration(
                      labelText: '새 비밀번호 확인',
                      hintText: '새 비밀번호 재입력',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: _confirmStarted
                          ? Icon(
                              _confirmMatch
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _confirmMatch
                                  ? AppColors.success
                                  : AppColors.warning,
                            )
                          : IconButton(
                              icon: Icon(_obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '새 비밀번호를 다시 입력해주세요';
                      if (v != _newCtrl.text) return '비밀번호가 일치하지 않습니다';
                      return null;
                    },
                  ),

                  if (_confirmStarted)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          Icon(
                            _confirmMatch
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 14,
                            color: _confirmMatch
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _confirmMatch
                                ? '비밀번호가 일치합니다'
                                : '비밀번호가 일치하지 않습니다',
                            style: TextStyle(
                              fontSize: 12,
                              color: _confirmMatch
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _handleSubmit,
                      child: const Text('비밀번호 변경'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
