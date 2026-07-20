import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _buttonFadeAnim;

  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _buttonFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    // 로고 애니메이션 최소 표시 시간
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.checkAuthState();
    if (!mounted) return;

    // ── v2.5 딥링크: /invite/:token 감지 (Web URL 기반) ──
    // Flutter Web: Uri.base 로 현재 URL 확인
    // Native: SharedPreferences에 저장된 pending 토큰 확인
    final pendingToken = await _detectInviteToken();
    if (!mounted) return;

    final isAuth = auth.isAuthenticated;

    if (isAuth) {
      if (pendingToken != null && pendingToken.isNotEmpty) {
        // 로그인 상태 + 초대 토큰 → 즉시 InviteJoinScreen
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.inviteJoin,
          arguments: {'token': pendingToken},
        );
      } else {
        // 이미 로그인 상태 → 바로 메인으로
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } else {
      if (pendingToken != null && pendingToken.isNotEmpty) {
        // 비로그인 + 초대 토큰 → 토큰 저장 후 버튼 표시
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_invite_token', pendingToken);
        if (!mounted) return;
      }
      // 비로그인 → 버튼 표시
      setState(() => _showButtons = true);
    }
  }

  /// 초대 토큰 감지
  /// 1순위: 현재 URL 경로 (/invite/:token)
  /// 2순위: SharedPreferences에 저장된 pending 토큰
  Future<String?> _detectInviteToken() async {
    try {
      // Flutter Web: Uri.base로 URL 경로 확인
      // ignore: undefined_prefixed_name
      final uri = Uri.base;
      final segments = uri.pathSegments;
      // /invite/TOKEN 또는 /app/invite/TOKEN 형태
      final inviteIdx = segments.indexOf('invite');
      if (inviteIdx != -1 && inviteIdx + 1 < segments.length) {
        final token = segments[inviteIdx + 1];
        if (token.isNotEmpty) return token;
      }
    } catch (_) {
      // Native 환경에서는 Uri.base 미지원 → SharedPreferences 폴백
    }

    // SharedPreferences에서 pending 토큰 확인
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pending_invite_token');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // 배경: 네이비 라디얼 그라데이션 (스플래시 A)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.2),
                  radius: 1.4,
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                  stops: [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),
          // 기요셰 사선 텍스처
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: CustomPaint(painter: GuillochePainter(spacing: 9)),
            ),
          ),

          // 메인 콘텐츠
          SafeArea(
            child: Column(
              children: [
                // 로고 영역 (상단 중앙)
                Expanded(
                  flex: 5,
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 로고 심볼 ④ (명함 모티프)
                            const ElidSymbol(size: 96),
                            const SizedBox(height: 24),
                            const ElidWordmark(
                                fontSize: 36, onDark: true, wide: true),
                            const SizedBox(height: 12),
                            Text(
                              '디지털 명함, 다시 우아하게',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 버튼 영역 (하단)
                Expanded(
                  flex: 3,
                  child: _showButtons
                      ? FadeTransition(
                          opacity: _buttonFadeAnim,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 시작하기 버튼
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        AppRoutes.login,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      '시작하기',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // 둘러보기 버튼
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.intro,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      '둘러보기',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // 하단 로딩 인디케이터 (버튼 표시 전)
                if (!_showButtons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),

                // 하단 브랜드 표기
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'ELID by METI',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
