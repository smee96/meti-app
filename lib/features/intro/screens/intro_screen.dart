import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

// ── 페이지 데이터 모델 ─────────────────────────────────────
class _IntroPage {
  final IconData icon;
  final IconData? badgeIcon;
  final String tag;           // 상단 태그 (예: "GLOBAL NETWORK")
  final String title;
  final String description;
  final String exampleLabel;  // 실사용 예시 레이블
  final String exampleText;   // 실사용 예시 내용
  final List<String> bullets; // 핵심 기능 3가지
  final List<Color> gradient;

  const _IntroPage({
    required this.icon,
    this.badgeIcon,
    required this.tag,
    required this.title,
    required this.description,
    required this.exampleLabel,
    required this.exampleText,
    required this.bullets,
    required this.gradient,
  });
}

// ── 페이지 콘텐츠 정의 ─────────────────────────────────────
const List<_IntroPage> _kPages = [
  // 1. 디지털 명함
  _IntroPage(
    icon: Icons.credit_card_rounded,
    badgeIcon: Icons.public,
    tag: 'GLOBAL BUSINESS CARD',
    title: '세계 어디서나\n통하는 내 명함',
    description: 'QR·NFC 하나로 언어와 국경을 넘어\n전 세계 파트너에게 나를 소개하세요.',
    exampleLabel: '활용 예시',
    exampleText: '해외 컨퍼런스에서 QR 하나로\n명함·포트폴리오 즉시 전달',
    bullets: ['이름·직책·연락처 한 곳에', '실시간 수정 — 항상 최신 정보'],
    gradient: [Color(0xFF0f2460), Color(0xFF1e3a8a)],
  ),

  // 2. 그룹 & 레슨
  _IntroPage(
    icon: Icons.groups_rounded,
    badgeIcon: Icons.verified,
    tag: 'GROUP & LESSON',
    title: '동호회, 팀, 레슨\n그룹으로 한 번에',
    description: '초대 링크 하나로 멤버를 모으고\n명함 공유·채팅·일정을 함께 관리하세요.',
    exampleLabel: '활용 예시',
    exampleText: '테니스 동호회 · 필라테스 클래스 · 사내 팀\n초대 링크 → 멤버 명함 자동 공유',
    bullets: ['초대 링크로 간편 멤버 모집', '그룹 채팅 & 명함 일괄 열람'],
    gradient: [Color(0xFF0f2460), Color(0xFF4338ca)],
  ),

  // 3. 행사 & NFC
  _IntroPage(
    icon: Icons.event_rounded,
    badgeIcon: Icons.nfc,
    tag: 'EVENT & NFC CHECK-IN',
    title: 'NFC 태그 하나로\n입장 + 명함 교환',
    description: '행사 개설부터 참가 신청, NFC 체크인까지\n모든 과정이 ELID 안에 있습니다.',
    exampleLabel: '활용 예시',
    exampleText: 'B2B 전시회 NFC 태그 →\n입장 확인 + 주최자 명함 자동 수신',
    bullets: ['행사 개설·참가 신청 원스톱', 'NFC 체크인 & 명함 교환 동시'],
    gradient: [Color(0xFF0f2460), Color(0xFF065f46)],
  ),

  // 4. 시작
  _IntroPage(
    icon: Icons.rocket_launch_rounded,
    tag: 'GET STARTED',
    title: '지금 바로\n첫 명함을 만드세요',
    description: '3분이면 완성, 무료로 시작하세요.\n전 세계 네트워크가 손안에 있습니다.',
    exampleLabel: 'ELID와 함께',
    exampleText: '종이 명함 0장 · 분실 걱정 0%\n글로벌 네트워크는 지금도 연결 중',
    bullets: ['무료로 즉시 시작', '언제든 플랜 업그레이드'],
    gradient: [Color(0xFF0f2460), Color(0xFF1e3a8a)],
  ),
];

// ── 메인 위젯 ─────────────────────────────────────────────
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeCtrl.forward(from: 0);
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  void _skip() {
    _pageController.animateToPage(
      _kPages.length - 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _kPages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // ── PageView ────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _kPages.length,
            itemBuilder: (_, i) => _PageContent(
              page: _kPages[i],
              fadeAnim: _fadeAnim,
              isCurrent: i == _currentPage,
            ),
          ),

          // ── 상단: ELID 로고 + 닫기 ──────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ELID 로고
                  const Row(
                    children: [
                      ElidSymbol(size: 32),
                      SizedBox(width: 9),
                      ElidWordmark(fontSize: 18, onDark: true),
                    ],
                  ),
                  // 닫기
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '닫기',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 하단: 인디케이터 + 버튼 ─────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 페이지 인디케이터
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _kPages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
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
                    const SizedBox(height: 24),

                    // 마지막 페이지 버튼
                    if (isLast) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.register,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '무료로 시작하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        ),
                        child: Text(
                          '이미 계정이 있으신가요?  로그인',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ] else ...[
                      // 일반 페이지 버튼
                      Row(
                        children: [
                          // 건너뛰기
                          GestureDetector(
                            onTap: _skip,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              child: Text(
                                '건너뛰기',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // 다음
                          GestureDetector(
                            onTap: _next,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '다음',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primary,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 개별 페이지 위젯 ──────────────────────────────────────
class _PageContent extends StatelessWidget {
  final _IntroPage page;
  final Animation<double> fadeAnim;
  final bool isCurrent;

  const _PageContent({
    required this.page,
    required this.fadeAnim,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: page.gradient,
        ),
      ),
      child: Stack(
        children: [
          // 배경 장식 원
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.2,
            child: _DecorCircle(size: size.width * 0.75, opacity: 0.07),
          ),
          Positioned(
            bottom: size.height * 0.22,
            left: -size.width * 0.2,
            child: _DecorCircle(size: size.width * 0.6, opacity: 0.05),
          ),

          // 본문
          SafeArea(
            child: FadeTransition(
              opacity: isCurrent ? fadeAnim : const AlwaysStoppedAnimation(1),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 72, 28, 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 태그 배지 ──────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ade80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            page.tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 아이콘 ────────────────────────────
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            page.icon,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        if (page.badgeIcon != null)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ade80),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                page.badgeIcon,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── 제목 ──────────────────────────────
                    Text(
                      page.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 설명 ──────────────────────────────
                    Text(
                      page.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 15,
                        height: 1.75,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 핵심 기능 3가지 ──────────────────
                    ...page.bullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ade80)
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF4ade80),
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              b,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 실사용 예시 카드 ─────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ade80),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                page.exampleLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            page.exampleText,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 14,
                              height: 1.65,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 배경 장식 원 ──────────────────────────────────────────
class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1,
        ),
      ),
    );
  }
}
