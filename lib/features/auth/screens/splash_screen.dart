import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../cards/services/card_design_catalog.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
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
  late Animation<double> _buttonFadeAnim;

  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _buttonFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    // 명함 디자인 카탈로그 로드 (번들 폴백 내장 — 실패해도 진행)
    // 스플래시 대기와 병렬 수행
    final catalogFuture = CardDesignCatalog.instance.ensureLoaded();

    // 스플래시 최소 표시 시간 (제품 결정 2026-07-23: 입장 시 2초)
    await Future.delayed(const Duration(milliseconds: 2000));
    await catalogFuture;
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.checkAuthState();
    if (!mounted) return;

    // ── 온보딩 자동 노출 (핸드오프 2026-07-24 §4 + 노출 횟수 확장) ──
    // 최대 3회까지 노출하되, 3장을 끝까지 본 사용자에겐 더 띄우지 않는다.
    // (중간에 건너뛰면 아직 이해 못 한 것으로 보고 다음 실행에 다시 노출)
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone =
        prefs.getBool(AppConstants.keyOnboardingCompleted) ?? false;
    final shownCount =
        prefs.getInt(AppConstants.keyOnboardingShownCount) ?? 0;
    if (!onboardingDone &&
        shownCount < AppConstants.onboardingMaxAutoShows) {
      await prefs.setInt(
          AppConstants.keyOnboardingShownCount, shownCount + 1);
      if (!mounted) return;
      await Navigator.pushNamed(context, AppRoutes.intro);
      if (!mounted) return;
      // 온보딩에서 회원가입/로그인으로 화면을 교체한 경우, 스플래시가 뒤이어
      // 라우팅하면 사용자를 낚아채게 되므로 여기서 흐름을 끝낸다.
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    }

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
      backgroundColor: Colors.white,
      body: Stack(
        // 비배치 자식(Column)이 전폭이 아니어도 Stack이 화면 전체를 채우도록
        fit: StackFit.expand,
        children: [
          // 배경: 브랜드 스플래시 사진 (2026-07-23 elid_sp — 로고·태그라인 포함)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Image.asset(
                'assets/images/elid_splash.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),

          // 하단 가독성 스크림 (버튼·로딩 영역)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 300,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 하단 콘텐츠 (버튼 / 로딩)
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // 버튼 영역 (비로그인 시)
                if (_showButtons)
                  FadeTransition(
                    opacity: _buttonFadeAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      child: Column(
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
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
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
                                foregroundColor: AppColors.primary,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.6),
                                side: const BorderSide(
                                  color: AppColors.primary,
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
                  ),

                // 하단 로딩 인디케이터 (버튼 표시 전)
                if (!_showButtons)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 44),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                // 하단 브랜드 표기
                const Padding(
                  padding: EdgeInsets.only(bottom: 16, top: 12),
                  child: Text(
                    'ELID by METI',
                    style: TextStyle(
                      color: AppColors.textSecondary,
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
