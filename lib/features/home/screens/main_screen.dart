import 'package:flutter/material.dart';
import '../../cards/screens/cards_home_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../mypage/screens/mypage_screen.dart';
import '../../network/screens/network_screen.dart';
import '../../partnership/screens/partnership_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // IA 개편(2026-07-20): 그룹·이벤트·명함첩 → 네트워크로 통합, 제휴 탭 신설
  final List<Widget> _screens = const [
    CardsHomeScreen(),
    NetworkScreen(),
    ChatListScreen(),
    PartnershipScreen(),
    MyPageScreen(),
  ];

  // ELID 브랜드 킷(2026-07-20) 탭바 아이콘 — off(그레이)/on(잉크) PNG 세트
  final List<_NavItem> _navItems = const [
    _NavItem(asset: 'tab-home', label: '홈'),
    _NavItem(asset: 'tab-network', label: '네트워크'),
    _NavItem(asset: 'tab-chat', label: '채팅'),
    _NavItem(asset: 'tab-partner', label: '제휴'),
    _NavItem(asset: 'tab-my', label: '마이'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: _navItems
              .map((item) => BottomNavigationBarItem(
                    icon: _TabIcon(asset: item.asset, active: false),
                    activeIcon: _TabIcon(asset: item.asset, active: true),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String asset;
  final String label;
  const _NavItem({required this.asset, required this.label});
}

/// 브랜드 킷 탭바 PNG 아이콘 (색상은 이미지에 포함 — off 그레이 / on 잉크)
class _TabIcon extends StatelessWidget {
  final String asset;
  final bool active;
  const _TabIcon({required this.asset, required this.active});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/tabbar/$asset${active ? '-on' : ''}.png',
      width: 26,
      height: 26,
      // 원본 288px → 26dp 축소, 픽셀 계단 방지
      filterQuality: FilterQuality.medium,
    );
  }
}
