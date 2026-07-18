import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../cards/screens/contacts_screen.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  // 서버 폴링 가이드: 목록 화면은 10초 간격, 백그라운드 진입 시 중단
  static const _pollInterval = Duration(seconds: 10);

  final ApiClient _api = ApiClient();
  List<dynamic> _rooms = [];
  bool _isLoading = false;
  int _retentionDays = 0; // 0 = 무제한(안내 숨김)
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRooms(initial: true);
      _startPolling();
    });
  }

  @override
  void dispose() {
    _stopPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRooms();
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _loadRooms());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// initial=true일 때만 로딩 인디케이터 표시 (폴링은 조용히 갱신)
  Future<void> _loadRooms({bool initial = false}) async {
    if (initial) setState(() => _isLoading = true);
    try {
      final response = await _api.get('/chat');
      if (!mounted) return;
      if (response['success'] == true) {
        setState(() {
          _rooms = response['data'] as List;
          _retentionDays = response['chat_retention_days'] as int? ?? 0;
        });
      }
    } catch (_) {}
    if (initial && mounted) setState(() => _isLoading = false);
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
      if (diff.inDays == 1) return '어제';
      return DateFormat('MM/dd').format(dt);
    } catch (_) {
      return '';
    }
  }

  void _openRoom(dynamic room) {
    final members = room['members'] as List? ?? [];
    final otherMember = members.isNotEmpty ? members.first : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          roomId: room['id'] as int,
          roomName: otherMember?['name'] ?? '채팅',
          otherUserId: otherMember?['user_id'] as int?,
        ),
      ),
    ).then((_) => _loadRooms());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('채팅')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _rooms.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.chat_bubble_outline,
                  title: '채팅방이 없어요',
                  subtitle: '명함을 교환한 상대방과\n채팅을 시작해보세요.',
                  actionLabel: '명함첩 보기',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactsScreen()),
                  ),
                )
              : Column(
                  children: [
                    if (_retentionDays > 0) _buildRetentionBanner(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadRooms,
                        child: ListView.separated(
                          itemCount: _rooms.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (_, i) => _buildRoomTile(_rooms[i]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// 무료 플랜 메시지 보관기간 안내 (chat_retention_days > 0일 때만)
  Widget _buildRetentionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.accent.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '무료 플랜은 대화가 $_retentionDays일 후 사라집니다.',
              style: AppTextStyles.caption.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(dynamic room) {
    final members = room['members'] as List? ?? [];
    final otherMember = members.isNotEmpty ? members.first : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: UserAvatar(
        name: otherMember?['name'] ?? '?',
        avatarUrl: otherMember?['avatar_url'] as String?,
        size: 48,
      ),
      title: Text(
        otherMember?['name'] ?? '알 수 없음',
        style: AppTextStyles.h4,
      ),
      subtitle: Text(
        room['last_message'] ?? '메시지가 없습니다',
        style: AppTextStyles.body2,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(room['last_message_at'] as String?),
            style: AppTextStyles.caption,
          ),
          if ((room['unread_count'] as int? ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${room['unread_count']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => _openRoom(room),
    );
  }
}
