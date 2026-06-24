import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../cards/screens/cards_home_screen.dart';
import '../../cards/screens/cardbook_hub_screen.dart';
import '../../cards/screens/qr_scan_screen.dart';
import '../../cards/screens/qr_show_screen.dart';
import '../../cards/providers/cards_provider.dart';
import '../../partners/screens/partner_screen.dart';
import '../../mypage/screens/mypage_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 하단 4탭 (중앙 교환 FAB는 별도) — 홈 · 명함첩 · 제휴 · 내명함
  final List<Widget> _screens = const [
    CardsHomeScreen(),
    CardbookHubScreen(),
    PartnerScreen(),
    MyPageScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
    _NavItem(
        icon: Icons.contacts_outlined,
        activeIcon: Icons.contacts,
        label: '명함첩'),
    _NavItem(
        icon: Icons.handshake_outlined,
        activeIcon: Icons.handshake,
        label: '제휴'),
    _NavItem(
        icon: Icons.badge_outlined, activeIcon: Icons.badge, label: '내명함'),
  ];

  // ── 교환 FAB → 바텀시트(QR 스캔 / 내 QR 보여주기) ──────────
  void _openExchangeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('명함 교환', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text('QR로 주고받아 명함을 교환하세요.',
                    style: AppTextStyles.body2),
                const SizedBox(height: 20),
                _ExchangeOption(
                  icon: Icons.qr_code_scanner,
                  title: 'QR 스캔으로 받기',
                  subtitle: '상대 명함 QR을 스캔합니다.',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QrScanScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ExchangeOption(
                  icon: Icons.qr_code_2,
                  title: '내 QR 보여주기',
                  subtitle: '내 명함 QR을 상대에게 보여줍니다.',
                  onTap: () => _showMyQr(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMyQr(BuildContext sheetCtx) {
    final cards = context.read<CardsProvider>().myCards;
    if (cards.isEmpty) {
      Navigator.pop(sheetCtx);
      showErrorSnackBar(context, '먼저 명함을 만들어주세요.');
      return;
    }
    // 대표 명함 우선, 없으면 첫 번째
    final card = cards.firstWhere(
      (c) => c.isPrimaryCard,
      orElse: () => cards.first,
    );
    Navigator.pop(sheetCtx);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QrShowScreen(card: card)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openExchangeSheet,
        backgroundColor: AppColors.primary,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        color: AppColors.surface,
        elevation: 12,
        child: Row(
          children: [
            _navButton(0),
            _navButton(1),
            const SizedBox(width: 56), // 중앙 FAB 자리
            _navButton(2),
            _navButton(3),
          ],
        ),
      ),
    );
  }

  Widget _navButton(int index) {
    final item = _navItems[index];
    final selected = _currentIndex == index;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkResponse(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? item.activeIcon : item.icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ExchangeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
