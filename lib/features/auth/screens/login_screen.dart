// login_screen.dart — ELID 로그인 A (스플래시 연속형, 2026-07-08 확정 디자인)
// 상단 브랜드 히어로(네이비 라디얼 + 기요셰 + 심볼④ + 워드마크 + 태그라인)
// 하단 화이트 바텀 시트(골드 포커스 인풋, 그라데이션 로그인 버튼, 소셜, 무료 시작)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.login(
      email: _emailCtrl.text.trim().toLowerCase(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      // v2.5: 로그인 성공 후 pending 초대 토큰 확인
      final prefs = await SharedPreferences.getInstance();
      final pendingToken = prefs.getString('pending_invite_token');
      if (!mounted) return;
      if (pendingToken != null && pendingToken.isNotEmpty) {
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

  void _notReady() => showErrorSnackBar(context, '소셜 로그인은 준비 중입니다.');

  // ── 골드 포커스 인풋 데코레이션 ─────────────────────────
  InputDecoration _fieldDecoration({
    required String hint,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 1.5),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF98A1B0), fontSize: 15),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: border(const Color(0xFF0E1726).withValues(alpha: 0.12)),
      focusedBorder: border(AppColors.gold),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error),
    );
  }

  // 포커스 시 골드 4px 링
  BoxDecoration _focusRing(bool focused) => BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  spreadRadius: 4,
                ),
              ]
            : null,
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5B6577),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        resizeToAvoidBottomInset: true,
        body: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return LoadingOverlay(
              isLoading: auth.isLoading,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -1.2), // 120% 90% at 50% -10%
                    radius: 1.4,
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // 기요셰 사선 텍스처
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.5,
                        child: CustomPaint(
                          painter: GuillochePainter(spacing: 9),
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  // ── 브랜드 히어로 ──────────────
                                  Expanded(child: _buildHero()),
                                  // ── 화이트 바텀 시트 ───────────
                                  _buildSheet(auth),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildHero() {
    return SafeArea(
      bottom: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 240),
        padding: const EdgeInsets.only(top: 40, bottom: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ElidSymbol(size: 92),
            const SizedBox(height: 24),
            const ElidWordmark(fontSize: 32, onDark: true, wide: true),
            const SizedBox(height: 12),
            Text(
              '디지털 명함, 다시 우아하게',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet(AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, -18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이메일
            _label('이메일'),
            DecoratedBox(
              decoration: _focusRing(_emailFocus.hasFocus),
              child: TextFormField(
                controller: _emailCtrl,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                // 키보드 자동 대문자화 방지 (서버 노트 2026-07-22: 대문자 이메일 → 401)
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF0E1726)),
                decoration: _fieldDecoration(
                  hint: 'name@company.com',
                  prefixIcon: const Icon(Icons.mail_outline,
                      size: 19, color: Color(0xFF8B95A6)),
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
            ),
            const SizedBox(height: 13),

            // 비밀번호
            _label('비밀번호'),
            DecoratedBox(
              decoration: _focusRing(_passwordFocus.hasFocus),
              child: TextFormField(
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(),
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF0E1726)),
                decoration: _fieldDecoration(
                  hint: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline,
                      size: 19, color: Color(0xFF8B95A6)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: const Color(0xFF8B95A6),
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
                  if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 9),

            // 비밀번호 찾기
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.forgotPassword),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '비밀번호 찾기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDeep,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),

            // 로그인 버튼 (그라데이션 + 이너 하이라이트)
            _GradientLoginButton(
              onPressed: auth.isLoading ? null : _handleLogin,
            ),
            const SizedBox(height: 17),

            // "또는" 디바이더
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        const Color(0xFF0E1726).withValues(alpha: 0.1),
                      ]),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '또는',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B95A6),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFF0E1726).withValues(alpha: 0.1),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),

            // 소셜 로그인 3버튼
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'Google',
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    onPressed: _notReady,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _SocialButton(
                    label: 'Apple',
                    icon: const Icon(Icons.apple,
                        size: 18, color: Color(0xFF111111)),
                    onPressed: _notReady,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _SocialButton(
                    label: '카카오',
                    background: const Color(0xFFFEE500),
                    borderless: true,
                    foreground: const Color(0xFF191600),
                    icon: const Icon(Icons.chat_bubble,
                        size: 15, color: Color(0xFF191600)),
                    onPressed: _notReady,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 21),

            // 무료로 시작하기
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                child: Text.rich(
                  TextSpan(
                    text: '계정이 없으신가요? ',
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF5B6577)),
                    children: [
                      TextSpan(
                        text: '무료로 시작하기',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 로그인 버튼 (그라데이션 + 이너 하이라이트 + 레이어드 섀도) ───
class _GradientLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _GradientLoginButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.55),
            blurRadius: 26,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF16305B),
                      Color(0xFF0B1E40),
                      Color(0xFF081831),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // 이너 하이라이트 (상단 1px)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  child: const Center(
                    child: Text(
                      '로그인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 소셜 로그인 버튼 ─────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final Color? background;
  final Color? foreground;
  final bool borderless;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.background,
    this.foreground,
    this.borderless = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: background,
        gradient: background == null
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFC)],
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: borderless
            ? null
            : Border.all(
                color: const Color(0xFF0E1726).withValues(alpha: 0.10),
                width: 1.5,
              ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E1726).withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: foreground ?? const Color(0xFF0E1726),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
