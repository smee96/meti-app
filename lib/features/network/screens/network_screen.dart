import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../cards/screens/contacts_screen.dart';
import '../../events/screens/events_screen.dart';
import '../../groups/screens/groups_screen.dart';

/// 네트워크 탭 — 명함첩·그룹·이벤트를 한 곳에 (IA 개편 2026-07-20)
/// 이벤트는 그룹 파생 행사라 그룹과 같은 맥락으로 묶는다.
class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('네트워크'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: '명함첩'),
              Tab(text: '그룹'),
              Tab(text: '이벤트'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _KeepAlive(child: ContactsScreen(embedded: true)),
            _KeepAlive(child: GroupsScreen(embedded: true)),
            _KeepAlive(child: EventsScreen(embedded: true)),
          ],
        ),
      ),
    );
  }
}

/// 탭 전환 시 각 화면의 상태(목록·스크롤)를 유지
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
