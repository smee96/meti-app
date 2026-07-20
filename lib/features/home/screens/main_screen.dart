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

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈'),
    _NavItem(icon: Icons.people_alt_outlined, activeIcon: Icons.people_alt, label: '네트워크'),
    _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: '채팅'),
    _NavItem(icon: Icons.handshake_outlined, activeIcon: Icons.handshake, label: '제휴'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: '마이'),
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
                    icon: Icon(item.icon),
                    activeIcon: Icon(item.activeIcon),
                    label: item.label,
                  ))
              .toList(),
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
