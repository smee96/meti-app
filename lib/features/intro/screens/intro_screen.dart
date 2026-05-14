import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
    description: '종이 명함의 시대는 끝났습니다.\nMETI 디지털 명함 하나로 언어·국경을 넘어\n전 세계 비즈니스 파트너에게 나를 소개하세요.',
    exampleLabel: '이런 분들께 딱 맞아요',
    exampleText: '해외 컨퍼런스에서 만난 바이어에게\nQR 하나로 내 명함·포트폴리오 즉시 전달',
    bullets: ['이름·직책·연락처·SNS 한 곳에', '다국어 지원 & 글로벌 공유', '실시간 수정 — 항상 최신 정보'],
    gradient: [Color(0xFF0f2460), Color(0xFF1e3a8a)],
  ),

  // 2. QR & NFC
  _IntroPage(
    icon: Icons.nfc_rounded,
    badgeIcon: Icons.bolt,
    tag: 'ONE TOUCH SHARING',
    title: '터치 한 번,\n명함 교환 완료',
    description: 'QR 스캔 또는 NFC 태그 한 번으로\n명함이 즉시 상대방 앱에 저장됩니다.\n앱 설치 없이도 웹으로 바로 확인 가능.',
    exampleLabel: '현장에서 이렇게 쓰세요',
    exampleText: '네트워킹 행사에서 명함 100장 인쇄 대신\nNFC 카드 1장으로 전원에게 내 정보 전달',
    bullets: ['NFC 카드 태그로 즉시 공유', 'QR 스캔 — 카메라 앱으로 바로 인식', '링크 공유 — 카톡·메일·SNS 전송'],
    gradient: [Color(0xFF0f2460), Color(0xFF0369a1)],
  ),

  // 3. 그룹 & 커뮤니티
  _IntroPage(
    icon: Icons.groups_rounded,
    badgeIcon: Icons.verified,
    tag: 'COMMUNITY & GROUP',
    title: '동호회부터 팀까지\n그룹으로 묶다',
    description: '업종별 모임, 사내 팀, 동창회, 동호회까지\n목적에 맞는 그룹을 만들고 멤버를 초대하세요.\n그룹 내 명함 공유와 채팅이 한 번에.',
    exampleLabel: '활용 사례',
    exampleText: '테니스 동호회 개설 → 초대 링크 발송 →\n멤버 명함 자동 공유 → 그룹 채팅으로 일정 조율',
    bullets: ['초대 링크 한 번으로 멤버 모집', '그룹 내 명함 일괄 열람', '멤버 간 1:1 채팅 즉시 시작'],
    gradient: [Color(0xFF0f2460), Color(0xFF4338ca)],
  ),

  // 4. 레슨 & 클래스
  _IntroPage(
    icon: Icons.school_rounded,
    badgeIcon: Icons.star,
    tag: 'LESSON & CLASS',
    title: '강사·전문가를 위한\n스마트 운영 도구',
    description: '레슨, 코칭, 클래스를 운영하는 모든 전문가에게.\n수강생에게 명함과 일정을 한 번에 전달하고\n포인트로 간편하게 수업료를 처리하세요.',
    exampleLabel: '활용 사례',
    exampleText: '필라테스 강사가 신규 수강생에게\nNFC 카드 태그 → 내 명함 + 수업 일정 + 결제 링크 전달',
    bullets: ['명함에 레슨 일정·가격 정보 포함', '그룹으로 수강생 멤버 관리', '포인트 결제로 수업료 간소화'],
    gradient: [Color(0xFF0f2460), Color(0xFF065f46)],
  ),

  // 5. 행사 & 이벤트
  _IntroPage(
    icon: Icons.event_rounded,
    badgeIcon: Icons.nfc,
    tag: 'EVENT & NFC CHECK-IN',
    title: '행사 입장부터\n명함 교환까지 한 번에',
    description: '행사를 개설하고 참가자를 모집하세요.\nNFC 카드로 입장 체크인은 물론,\n현장에서 명함 교환까지 동시에 해결됩니다.',
    exampleLabel: '현장에서 이렇게 쓰세요',
    exampleText: 'B2B 전시회 입장 시 NFC 태그 →\n참가 확인 + 주최자 명함 자동 수신 + 네트워킹 시작',
    bullets: ['행사 개설·참가 신청 원스톱', 'NFC 입장 체크인 & 명함 교환 동시', '참가자 명함 목록 자동 저장'],
    gradient: [Color(0xFF0f2460), Color(0xFF92400e)],
  ),

  // 6. 시작 페이지
  _IntroPage(
    icon: Icons.rocket_launch_rounded,
    tag: 'GET STARTED',
    title: '지금 바로\n첫 명함을 만드세요',
    description: '무료로 시작하고, 필요할 때 확장하세요.\n전 세계 비즈니스 네트워크가\n당신의 손안에 있습니다.',
    exampleLabel: 'METI와 함께하는 변화',
    exampleText: '종이 명함 0장 · 분실 걱정 0% · 업데이트 즉시 반영\n글로벌 네트워크는 지금 이 순간도 연결 중',
    bullets: ['Free 플랜으로 무료 시작', '3분이면 첫 명함 완성', '언제든 플랜 업그레이드'],
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

          // ── 상단: METI 로고 + 닫기 ──────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // METI 로고
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'METI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
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
