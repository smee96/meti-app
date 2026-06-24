import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../groups/screens/groups_screen.dart';
import '../../events/screens/events_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import 'contacts_screen.dart';

/// 명함첩 허브
/// 상단 세그먼트로 [명함첩 | 그룹 | 행사]를 묶고, 우상단에 채팅 진입 아이콘을 둔다.
/// 채팅은 명함첩·그룹·커뮤니티에서 만난 사람들과의 대화이므로 이 허브에 위치.
class CardbookHubScreen extends StatefulWidget {
  const CardbookHubScreen({super.key});

  @override
  State<CardbookHubScreen> createState() => _CardbookHubScreenState();
}

class _CardbookHubScreenState extends State<CardbookHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('명함첩'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '명함첩'),
            Tab(text: '그룹'),
            Tab(text: '행사'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: '채팅',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ContactsScreen(embedded: true),
          GroupsScreen(embedded: true),
          EventsScreen(embedded: true),
        ],
      ),
    );
  }
}
