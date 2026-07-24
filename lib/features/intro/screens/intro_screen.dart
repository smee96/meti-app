import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

/// 온보딩(둘러보기) — 서버 핸드오프 2026-07-24 기준 간소화판
/// 원칙: 기능 나열 금지. 핵심 3동사만 — 만들고 → 주고받고 → 이어간다.
/// 카피는 웹 랜딩(#how)과 동일하게 유지할 것. 변경 시 양쪽 동기화.
class _IntroPage {
  final IconData icon;
  final String title;
  final String description;

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ── 온보딩 3장 (핸드오프 §2 문구 그대로) ────────────────────
const List<_IntroPage> _kPages = [
  _IntroPage(
    icon: Icons.credit_card_rounded,
    title: '내 명함 만들기',
    description: '이름·회사·연락처만 넣으면 1분 완성.\n종이 명함은 이제 안녕 👋',
  ),
  _IntroPage(
    icon: Icons.nfc_rounded,
    title: '폰 맞대고 교환',
    description: '폰을 맞대거나(NFC) QR을 찍으면 끝.\n받은 명함은 자동으로 명함첩에 정리돼요.',
  ),
  _IntroPage(
    icon: Icons.forum_rounded,
    title: '관계로 이어가기',
    description: '교환한 사람과 채팅·그룹·행사로 계속 연결.\n명함을 넘어, 진짜 인맥으로.',
  ),
];

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage >= _kPages.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  /// 마지막 장까지 봤으면 '완주'로 기록 → 이후 자동 노출 중단.
  /// (중간에 건너뛰면 기록하지 않아 다음 실행에 다시 노출된다)
  Future<void> _markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingCompleted, true);
  }

  void _onPageChanged(int i) {
    setState(() => _currentPage = i);
    if (i == _kPages.length - 1) _markCompleted();
  }

  /// 건너뛰기 — 온보딩을 벗어나 스플래시 시작화면으로 돌아간다.
  /// (최초 실행 시 스플래시에서 push 되므로 pop 하면 시작화면이 나온다)
  void _skip() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _start() =>
      Navigator.pushReplacementNamed(context, AppRoutes.register);

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _kPages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1E40), Color(0xFF1e3a8a)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── 상단: 로고 + 건너뛰기(상시 노출) ──────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        ElidSymbol(size: 28),
                        SizedBox(width: 8),
                        ElidWordmark(fontSize: 16, onDark: true),
                      ],
                    ),
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 한 줄 요약 (핸드오프 §1) ──────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: Column(
                  children: [
                    const Text(
                      'ELID는 폰으로 주고받는 디지털 명함이에요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '교환 · 정리 · 인맥 연결까지 한 곳에서.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.66),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3장 스와이프 ──────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _kPages.length,
                  itemBuilder: (_, i) => _PageContent(page: _kPages[i]),
                ),
              ),

              // ── 도트 인디케이터 ───────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _kPages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == i ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── 하단 CTA ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLast ? _start : _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isLast ? '시작하기' : '다음',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 마지막 장에서만 로그인 안내 (핸드오프 §3: 회원가입/로그인)
                    if (isLast)
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                            context, AppRoutes.login),
                        child: Text(
                          '이미 계정이 있으신가요?  로그인',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 개별 페이지 (아이콘 + 헤드라인 + 본문) ──────────────────
class _PageContent extends StatelessWidget {
  final _IntroPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(page.icon, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
