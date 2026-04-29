import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _rooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRooms());
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get('/chat');
      if (response['success'] == true) {
        setState(() => _rooms = response['data'] as List);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
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
                  onAction: () {},
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: ListView.separated(
                    itemCount: _rooms.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (_, i) {
                      final room = _rooms[i];
                      final members = room['members'] as List? ?? [];
                      final otherMember =
                          members.isNotEmpty ? members.first : null;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              roomId: room['id'] as int,
                              roomName: otherMember?['name'] ?? '채팅',
                            ),
                          ),
                        ).then((_) => _loadRooms()),
                      );
                    },
                  ),
                ),
    );
  }
}
