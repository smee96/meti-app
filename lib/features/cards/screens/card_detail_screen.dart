import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../widgets/business_card_widget.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../chat/screens/chat_room_screen.dart';
import 'card_create_screen.dart';
import 'qr_show_screen.dart';

class CardDetailScreen extends StatefulWidget {
  final CardModel card;
  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late CardModel _card;
  final ApiClient _api = ApiClient();
  int? _myUserId;
  bool _isStartingChat = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _loadMyUserId();
  }

  Future<void> _loadMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _myUserId = prefs.getInt(AppConstants.keyUserId));
  }

  /// 내 명함이 아닌 상대방 명함일 때만 채팅 가능
  bool get _isMyCard => _myUserId != null && _card.userId == _myUserId;

  // ── 채팅하기 — POST /chat/direct 로 1:1 방 생성/조회 후 입장 ──
  Future<void> _startChat() async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);
    try {
      final response = await _api.post('/chat/direct',
          body: {'target_user_id': _card.userId});
      if (!mounted) return;
      if (response['success'] == true) {
        final roomId = response['data']['room_id'] as int;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              roomId: roomId,
              roomName: _card.name,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  // ── 명함 사진 변경 (v2.9) ────────────────────────────────
  Future<void> _handleChangeAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;

    final provider = context.read<CardsProvider>();
    final newUrl =
        await provider.uploadCardAvatar(_card.id, picked.path);
    if (!mounted) return;
    if (newUrl != null) {
      setState(() => _card = _card.copyWith(avatarUrl: newUrl));
      showSuccessSnackBar(context, '명함 사진이 업데이트되었습니다.');
    } else {
      showErrorSnackBar(context, '사진 업로드에 실패했습니다.');
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('명함 삭제'),
        content: const Text('이 명함을 삭제하시겠습니까?\n삭제된 명함은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final provider = context.read<CardsProvider>();
    final success = await provider.deleteCard(_card.id);
    if (!mounted) return;
    if (success) {
      showSuccessSnackBar(context, '명함이 삭제되었습니다.');
      Navigator.pop(context, true);
    } else {
      showErrorSnackBar(context, '명함 삭제에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상대방 명함일 때만 하단 채팅 버튼 노출
      bottomNavigationBar: _isMyCard
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isStartingChat ? null : _startChat,
                    icon: _isStartingChat
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.chat_bubble_outline),
                    label: const Text('채팅하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      appBar: AppBar(
        title: const Text('명함 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: 'QR 코드',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QrShowScreen(card: _card),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                // await 이전에 provider 캡처
                final provider = context.read<CardsProvider>();
                final cardId = _card.id;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardCreateScreen(existingCard: _card),
                  ),
                );
                if (!mounted) return;
                if (result == true) {
                  final updated = await provider.getCardDetail(cardId);
                  if (mounted) setState(() => _card = updated ?? _card);
                }
              } else if (value == 'delete') {
                _handleDelete();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('수정'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('삭제', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 명함 사진 (avatar_url) ──────────────────────
            if (_card.avatarUrl != null && _card.avatarUrl!.isNotEmpty) ...[
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: NetworkImage(_card.avatarUrl!),
                    ),
                    // 사진 변경 버튼
                    GestureDetector(
                      onTap: () => _handleChangeAvatar(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── 명함 카드 ───────────────────────────────────
            BusinessCardWidget(card: _card),
            const SizedBox(height: 24),

            // ── QR 버튼 ─────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => QrShowScreen(card: _card)),
              ),
              icon: const Icon(Icons.qr_code),
              label: const Text('QR 코드 표시'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 24),

            // ── 기본 정보 ────────────────────────────────────
            _InfoSection(
              title: '기본 정보',
              items: [
                if (_card.title != null)
                  _InfoItem(
                      icon: Icons.work_outline,
                      label: '직책',
                      value: _card.title!),
                if (_card.company != null)
                  _InfoItem(
                      icon: Icons.business_outlined,
                      label: '회사',
                      value: _card.company!),
              ],
            ),

            // ── 연락처 ───────────────────────────────────────
            _InfoSection(
              title: '연락처',
              items: [
                if (_card.email != null)
                  _InfoItem(
                    icon: Icons.email_outlined,
                    label: '이메일',
                    value: _card.email!,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: _card.email!));
                      showSuccessSnackBar(context, '이메일이 복사되었습니다.');
                    },
                  ),
                if (_card.phone != null)
                  _InfoItem(
                    icon: Icons.phone_outlined,
                    label: '전화',
                    value: _card.phone!,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: _card.phone!));
                      showSuccessSnackBar(context, '전화번호가 복사되었습니다.');
                    },
                  ),
                if (_card.website != null)
                  _InfoItem(
                    icon: Icons.language_outlined,
                    label: '웹사이트',
                    value: _card.website!,
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: _card.website!));
                      showSuccessSnackBar(context, 'URL이 복사되었습니다.');
                    },
                  ),
              ],
            ),

            // ── 자기소개 ─────────────────────────────────────
            if (_card.bio != null && _card.bio!.isNotEmpty) ...[
              const Text('자기소개', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_card.bio!, style: AppTextStyles.body1),
              ),
              const SizedBox(height: 20),
            ],

            // ── 태그 (tags[]) ────────────────────────────────
            if (_card.tags.isNotEmpty) ...[
              const Text('태그', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _card.tags.map((tag) {
                  final label = tag.tagValue.isNotEmpty
                      ? tag.tagValue
                      : tag.tagType;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tag.tagType.isNotEmpty) ...[
                          Text(
                            tag.tagType,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary
                                  .withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 1,
                            height: 10,
                            color:
                                AppColors.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // ── SNS 링크 (sns_links[]) ───────────────────────
            if (_card.snsLinks.isNotEmpty) ...[
              const Text('SNS 링크', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: _card.snsLinks
                      .asMap()
                      .entries
                      .map((entry) {
                        final sns = entry.value;
                        final isLast =
                            entry.key == _card.snsLinks.length - 1;
                        return Column(
                          children: [
                            ListTile(
                              leading: _SnsDetailIcon(
                                  platform: sns.platform),
                              title: Text(sns.platform,
                                  style: AppTextStyles.body1),
                              subtitle: Text(
                                sns.url,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy,
                                    size: 16,
                                    color: AppColors.textTertiary),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: sns.url));
                                  showSuccessSnackBar(
                                      context, 'URL이 복사되었습니다.');
                                },
                              ),
                              dense: true,
                            ),
                            if (!isLast)
                              const Divider(height: 1, indent: 56),
                          ],
                        );
                      })
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── 공개 상태 ────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card.isPublicCard
                    ? AppColors.success.withValues(alpha: 0.06)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _card.isPublicCard
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _card.isPublicCard
                        ? Icons.public
                        : Icons.lock_outline,
                    color: _card.isPublicCard
                        ? AppColors.success
                        : AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _card.isPublicCard ? '공개 명함' : '비공개 명함',
                    style: AppTextStyles.body1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h4),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: items
                .map((item) => _buildItem(item))
                .expand((w) => [w, const Divider(height: 1)])
                .toList()
              ..removeLast(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildItem(_InfoItem item) {
    return ListTile(
      leading: Icon(item.icon, size: 20, color: AppColors.primary),
      title: Text(item.label, style: AppTextStyles.label),
      subtitle: Text(item.value, style: AppTextStyles.body1),
      trailing: item.onTap != null
          ? const Icon(Icons.copy, size: 16, color: AppColors.textTertiary)
          : null,
      onTap: item.onTap,
      dense: true,
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
}

// ── SNS 아이콘 (card_detail 전용) ──────────────────────────
class _SnsDetailIcon extends StatelessWidget {
  final String platform;
  const _SnsDetailIcon({required this.platform});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(_iconFor(platform), size: 18, color: AppColors.primary),
    );
  }

  IconData _iconFor(String p) {
    switch (p.toLowerCase()) {
      case 'instagram':  return Icons.camera_alt_outlined;
      case 'linkedin':   return Icons.business_center_outlined;
      case 'github':     return Icons.code_outlined;
      case 'twitter/x': return Icons.flutter_dash;
      case 'facebook':   return Icons.facebook_outlined;
      case 'youtube':    return Icons.play_circle_outline;
      case 'tiktok':     return Icons.music_video_outlined;
      case 'blog':       return Icons.article_outlined;
      case 'kakao':      return Icons.chat_bubble_outline;
      default:           return Icons.link;
    }
  }
}
