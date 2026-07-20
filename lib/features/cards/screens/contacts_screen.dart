import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../widgets/business_card_widget.dart';
import '../models/card_model.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../chat/screens/chat_room_screen.dart';
import 'card_detail_screen.dart';
import 'qr_scan_screen.dart';

class ContactsScreen extends StatefulWidget {
  /// true면 네트워크 탭 안에 임베드 — 자체 Scaffold/AppBar 없이 본문만 렌더
  final bool embedded;
  const ContactsScreen({super.key, this.embedded = false});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ApiClient _api = ApiClient();
  bool _isStartingChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardsProvider>().loadContacts();
    });
  }

  Widget _buildBody() {
    return Consumer<CardsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.contacts.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (provider.contacts.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.contacts_outlined,
            title: '저장된 명함이 없어요',
            subtitle: 'QR 스캔이나 명함 상세에서 명함을\n저장해보세요.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => provider.loadContacts(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final card = provider.contacts[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BusinessCardWidget(
                    card: card,
                    isCompact: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CardDetailScreen(card: card)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _startChat(card),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('채팅하기'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// 명함 주인과 1:1 채팅 시작 — 명함 미교환 상대는 서버가 403 반환
  Future<void> _startChat(CardModel card) async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);
    try {
      final response = await _api
          .post('/chat/direct', body: {'target_user_id': card.userId});
      if (!mounted) return;
      if (response['success'] == true) {
        // 서버 응답: {room_id, is_new} (구 mock 호환으로 id도 허용)
        final room = response['data'] as Map<String, dynamic>;
        final roomId = (room['room_id'] ?? room['id']) as int;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: roomId,
              roomName: card.name,
              otherUserId: card.userId,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403) {
        _showExchangeRequiredDialog(e.message);
      } else {
        showErrorSnackBar(context, e.message);
      }
    } catch (_) {}
    if (mounted) setState(() => _isStartingChat = false);
  }

  /// 403(명함 미교환) → 명함 교환 유도
  void _showExchangeRequiredDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('명함 교환이 필요해요'),
        content: Text('$message\nQR 스캔으로 서로 명함을 교환하면 채팅할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScanScreen()),
              );
            },
            child: const Text('QR 스캔'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();
    return Scaffold(
      appBar: AppBar(title: const Text('명함첩')),
      body: _buildBody(),
    );
  }
}
