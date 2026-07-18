import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../widgets/business_card_widget.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'card_create_screen.dart';
import 'nfc_applications_screen.dart';
import 'nfc_apply_screen.dart';
import 'qr_show_screen.dart';

class CardDetailScreen extends StatefulWidget {
  final CardModel card;
  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final ApiClient _api = ApiClient();
  late CardModel _card;

  // NFC 실물카드 (핸드오프 §5-2) — 내 명함일 때만 신청 버튼·상태 배지 노출
  int? _myUserId;
  Map<String, dynamic>? _nfcApplication;

  static const _resumeTypes = {'career', 'education'};
  List<CardTag> get _resumeTags =>
      _card.tags.where((t) => _resumeTypes.contains(t.tagType)).toList();
  List<CardTag> get _plainTags =>
      _card.tags.where((t) => !_resumeTypes.contains(t.tagType)).toList();

  bool get _isMyCard => _myUserId != null && _card.userId == _myUserId;

  bool get _nfcInProgress {
    final status = _nfcApplication?['status'] as String?;
    return status == 'pending' || status == 'approved';
  }

  String? get _nfcStatusLabel {
    switch (_nfcApplication?['status'] as String?) {
      case 'pending':
        return '신청됨';
      case 'approved':
        return '제작중';
      case 'issued':
        return '발급완료';
    }
    return null;
  }

  Color get _nfcStatusColor {
    switch (_nfcApplication?['status'] as String?) {
      case 'pending':
        return AppColors.info;
      case 'approved':
        return AppColors.accent;
      case 'issued':
        return AppColors.success;
    }
    return AppColors.textTertiary;
  }

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _loadNfcStatus();
  }

  /// 이 명함의 최근 NFC 신청 상태 조회 (내 명함일 때만)
  Future<void> _loadNfcStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final myId = prefs.getInt(AppConstants.keyUserId);
    if (!mounted) return;
    setState(() => _myUserId = myId);
    if (myId == null || _card.userId != myId) return;

    try {
      final response = await _api.get('/cards/nfc/applications');
      if (!mounted) return;
      if (response['success'] == true) {
        final forThisCard = (response['data'] as List)
            .where((a) => a['card_id'] == _card.id)
            .toList();
        setState(() => _nfcApplication = forThisCard.isNotEmpty
            ? Map<String, dynamic>.from(forThisCard.first as Map)
            : null);
      }
    } catch (_) {}
  }

  Future<void> _openNfc() async {
    if (_nfcInProgress) {
      // 진행 중 신청은 중복 신청(409) 대신 내역으로 이동
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NfcApplicationsScreen()),
      );
      _loadNfcStatus();
    } else {
      final applied = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NfcApplyScreen(card: _card)),
      );
      if (applied == true) _loadNfcStatus();
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

  // ── 명함 공유 ────────────────────────────────────────────
  // 공개 명함 링크를 시스템 공유 시트로 전송 (카톡·문자 등)
  Future<void> _handleShare() async {
    if (_card.isPublic != 1) {
      showErrorSnackBar(context, '비공개 명함은 공유할 수 없습니다.\n수정에서 공개로 전환한 뒤 공유해주세요.');
      return;
    }
    final url = _card.resolvedShareUrl;
    await Share.share(
      '[ELID] ${_card.name}님의 명함\n$url',
      subject: 'ELID 명함 — ${_card.name}',
    );
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
      appBar: AppBar(
        title: const Text('명함 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '명함 공유',
            onPressed: _handleShare,
          ),
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
                  // 단건 조회 실패 시 목록(updateCard가 갱신)에서 폴백
                  final updated = await provider.getCardDetail(cardId) ??
                      provider.myCards
                          .where((c) => c.id == cardId)
                          .firstOrNull;
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

            // ── NFC 실물카드 (내 명함만) ─────────────────────
            if (_isMyCard) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openNfc,
                icon: const Icon(Icons.nfc),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_nfcInProgress
                        ? 'NFC 카드 신청 내역'
                        : 'NFC 실물카드 신청'),
                    if (_nfcStatusLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _nfcStatusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _nfcStatusLabel!,
                          style: TextStyle(
                            fontSize: 11,
                            color: _nfcStatusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
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

            // ── 이력 (career/education 태그 — 공개 뷰어와 동일하게 분리 표시) ──
            if (_resumeTags.isNotEmpty) ...[
              const Text('이력', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              ..._resumeTags.map((tag) {
                final isCareer = tag.tagType == 'career';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          isCareer
                              ? Icons.work_outline
                              : Icons.school_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tag.tagValue, style: AppTextStyles.body1),
                            Text(
                              [
                                isCareer ? '경력' : '학력',
                                if (tag.tagPeriod != null &&
                                    tag.tagPeriod!.isNotEmpty)
                                  tag.tagPeriod!,
                              ].join(' · '),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // ── 태그 (이력 제외 일반 태그) ────────────────────
            if (_plainTags.isNotEmpty) ...[
              const Text('태그', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _plainTags.map((tag) {
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
