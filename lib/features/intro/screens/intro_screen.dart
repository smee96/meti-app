import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_IntroPage> _pages = const [
    _IntroPage(
      icon: Icons.credit_card_rounded,
      title: '디지털 명함',
      subtitle: '나만의 글로벌 비즈니스 카드',
      description:
          '종이 명함은 이제 그만.\n스마트한 디지털 명함으로\n언제 어디서나 나를 소개하세요.',
      gradient: [Color(0xFF1e3a8a), Color(0xFF2563EB)],
    ),
    _IntroPage(
      icon: Icons.qr_code_rounded,
      title: 'QR & NFC 공유',
      subtitle: '한 번의 터치로 연결',
      description:
          'QR 코드 스캔 또는 NFC 태그 한 번으로\n명함을 즉시 교환하세요.\n글로벌 네트워킹이 이렇게 쉬워집니다.',
      gradient: [Color(0xFF1e3a8a), Color(0xFF0891B2)],
    ),
    _IntroPage(
      icon: Icons.groups_rounded,
      title: '그룹 & 이벤트',
      subtitle: '커뮤니티와 함께 성장',
      description:
          '업계 그룹에 참여하고\n비즈니스 이벤트에서 새로운 인연을\n만들어보세요.',
      gradient: [Color(0xFF1e3a8a), Color(0xFF7C3AED)],
    ),
    _IntroPage(
      icon: Icons.chat_bubble_rounded,
      title: '1:1 비즈니스 채팅',
      subtitle: '명함 저장 후 바로 대화',
      description:
          '저장한 명함으로 바로 채팅을 시작하세요.\n안전하고 프라이빗한 비즈니스 메시지로\n관계를 이어가세요.',
      gradient: [Color(0xFF1e3a8a), Color(0xFF059669)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 페이지뷰
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _IntroPageWidget(page: _pages[index]);
            },
          ),

          // 상단 닫기 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),

          // 하단 인디케이터 + 버튼
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 페이지 인디케이터
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 마지막 페이지면 시작하기 버튼, 아니면 다음 버튼
                    if (_currentPage == _pages.length - 1)
                      Column(
                        children: [
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
                                '지금 시작하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.register);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            child: const Text(
                              '아직 계정이 없으신가요? 회원가입',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          // 건너뛰기
                          TextButton(
                            onPressed: () {
                              _pageController.animateToPage(
                                _pages.length - 1,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            child: const Text('건너뛰기'),
                          ),
                          const Spacer(),
                          // 다음
                          ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  '다음',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 추후 화면 캡처 추가 예정 배너 (개발용)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '미리보기',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────── 데이터 모델 ────────────────

class _IntroPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
  });
}

// ──────────────── 페이지 위젯 ────────────────

class _IntroPageWidget extends StatelessWidget {
  final _IntroPage page;

  const _IntroPageWidget({required this.page});

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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),

              // 아이콘 컨테이너
              Container(
                width: size.width * 0.42,
                height: size.width * 0.42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: size.width * 0.3,
                    height: size.width * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      page.icon,
                      size: size.width * 0.15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // 타이틀
              Text(
                page.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // 서브타이틀
              Text(
                page.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 설명
              Text(
                page.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                  height: 1.75,
                ),
                textAlign: TextAlign.center,
              ),

              // 나중에 추가될 화면 캡처 영역
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '화면 캡처 추가 예정',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 160), // 하단 버튼 공간
            ],
          ),
        ),
      ),
    );
  }
}
