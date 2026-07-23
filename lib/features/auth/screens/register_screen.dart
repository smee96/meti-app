import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // 한글 IME 버그 방지: textInputAction.next 대신 FocusNode 수동 이동
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // 실시간 상태 추적
  String _password = '';
  String _confirm = '';

  // ── 비밀번호 정책 체크 ────────────────────────────────
  bool get _hasMinLength => _password.length >= 8;
  bool get _hasUppercase => _password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _password.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'));
  bool get _allPoliciesMet =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasDigit;

  // 비밀번호 일치 여부 (한 글자라도 입력했을 때만 표시)
  bool get _confirmStarted => _confirm.isNotEmpty;
  bool get _confirmMatch => _password == _confirm && _confirm.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      setState(() => _password = _passwordCtrl.text);
    });
    _confirmCtrl.addListener(() {
      setState(() => _confirm = _confirmCtrl.text);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final result = await auth.register(
      email: _emailCtrl.text.trim().toLowerCase(),
      password: _passwordCtrl.text,
      name: _nameCtrl.text.trim(),
      // v2.8: accountType 파라미터 제거 — 서버 자동 고정
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.emailVerification,
        arguments: {
          'email': _emailCtrl.text.trim().toLowerCase(),
          // v3.0 보안패치: verify_token 서버 응답에서 제거됨
        },
      );
    } else {
      showErrorSnackBar(context, auth.errorMessage ?? '회원가입에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
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
                      const SizedBox(height: 24),
                      const Text('계정 만들기', style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                      const Text(
                        '글로벌 비즈니스 네트워킹을 시작하세요',
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(height: 24),

                      // ── 이름 ────────────────────────────
                      TextFormField(
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        // keyboardType.name: 한글 IME 조합 보존
                        keyboardType: TextInputType.name,
                        // textInputAction.next 제거 → onEditingComplete로 수동 이동
                        // (Android 한글 IME: next 액션이 조합 중 커밋 강제 → 입력 깨짐)
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () {
                          _nameFocus.unfocus();
                          FocusScope.of(context).requestFocus(_emailFocus);
                        },
                        decoration: const InputDecoration(
                          labelText: '이름',
                          hintText: '홍길동',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return '이름을 입력해주세요';
                          if (v.trim().length < 2) return '이름은 2자 이상이어야 합니다';
                          if (v.trim().length > 50) return '이름은 50자 이하여야 합니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── 이메일 ──────────────────────────
                      TextFormField(
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        // 키보드 자동 대문자화 방지 (서버 노트 2026-07-22)
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () {
                          _emailFocus.unfocus();
                          FocusScope.of(context).requestFocus(_passwordFocus);
                        },
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          hintText: 'example@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          // @ 포함 여부 먼저 체크 (명확한 에러 메시지)
                          if (!v.contains('@')) {
                            return '이메일에 @가 포함되어야 합니다';
                          }
                          // 엄격한 이메일 형식 검사
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(v.trim())) {
                            return '올바른 이메일 형식이 아닙니다 (예: user@example.com)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── 비밀번호 ─────────────────────────
                      TextFormField(
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () {
                          _passwordFocus.unfocus();
                          FocusScope.of(context).requestFocus(_confirmFocus);
                        },
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          hintText: '8자 이상 영문+숫자 조합',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                          if (!_allPoliciesMet) {
                            return '비밀번호 정책을 모두 충족해야 합니다';
                          }
                          return null;
                        },
                      ),

                      // ── 비밀번호 정책 체크리스트 ──────────
                      if (_password.isNotEmpty)
                        _PasswordPolicyBox(
                          hasMinLength: _hasMinLength,
                          hasUppercase: _hasUppercase,
                          hasLowercase: _hasLowercase,
                          hasDigit: _hasDigit,
                          hasSpecial: _hasSpecial,
                        ),

                      const SizedBox(height: 16),

                      // ── 비밀번호 확인 ─────────────────────
                      TextFormField(
                        controller: _confirmCtrl,
                        focusNode: _confirmFocus,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        decoration: InputDecoration(
                          labelText: '비밀번호 확인',
                          hintText: '비밀번호 재입력',
                          prefixIcon: const Icon(Icons.lock_outline),
                          // 일치 여부 아이콘
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
                                  onPressed: () => setState(() =>
                                      _obscureConfirm = !_obscureConfirm),
                                ),
                          // 테두리 색상으로도 표시
                          enabledBorder: _confirmStarted
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _confirmMatch
                                        ? AppColors.success
                                        : AppColors.warning,
                                    width: 1.5,
                                  ),
                                )
                              : null,
                          focusedBorder: _confirmStarted
                              ? OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _confirmMatch
                                        ? AppColors.success
                                        : AppColors.warning,
                                    width: 2,
                                  ),
                                )
                              : null,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return '비밀번호를 다시 입력해주세요';
                          if (v != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다';
                          return null;
                        },
                      ),

                      // ── 일치 상태 메시지 ──────────────────
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

                      // ── 회원가입 버튼 ─────────────────────
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleRegister,
                        child: const Text('회원가입'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('이미 계정이 있으신가요?',
                              style: AppTextStyles.body2),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('로그인'),
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

// ── 비밀번호 정책 체크리스트 위젯 ─────────────────────────
class _PasswordPolicyBox extends StatelessWidget {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecial;

  const _PasswordPolicyBox({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '비밀번호 조건',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _PolicyRow(met: hasMinLength, label: '8자 이상'),
          _PolicyRow(met: hasUppercase, label: '영문 대문자 포함 (A-Z)'),
          _PolicyRow(met: hasLowercase, label: '영문 소문자 포함 (a-z)'),
          _PolicyRow(met: hasDigit, label: '숫자 포함 (0-9)'),
          _PolicyRow(
            met: hasSpecial,
            label: '특수문자 포함 (선택)',
            optional: true,
          ),
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final bool met;
  final String label;
  final bool optional;

  const _PolicyRow({
    required this.met,
    required this.label,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = met
        ? AppColors.success
        : optional
            ? AppColors.textTertiary
            : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(met),
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: met ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
