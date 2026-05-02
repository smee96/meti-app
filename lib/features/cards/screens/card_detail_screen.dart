import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../widgets/business_card_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _card = widget.card;
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
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardCreateScreen(existingCard: _card),
                  ),
                );
                if (result == true && mounted) {
                  final provider = context.read<CardsProvider>();
                  final cardId = _card.id;
                  final updated = await provider.getCardDetail(cardId);
                  if (updated != null && mounted) {
                    setState(() => _card = updated);
                  }
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
            // 명함 카드
            BusinessCardWidget(card: _card),
            const SizedBox(height: 24),

            // QR 버튼
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QrShowScreen(card: _card)),
              ),
              icon: const Icon(Icons.qr_code),
              label: const Text('QR 코드 표시'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 24),

            // 상세 정보
            _InfoSection(
              title: '기본 정보',
              items: [
                if (_card.title != null)
                  _InfoItem(icon: Icons.work_outline, label: '직책', value: _card.title!),
                if (_card.company != null)
                  _InfoItem(icon: Icons.business_outlined, label: '회사', value: _card.company!),
              ],
            ),

            _InfoSection(
              title: '연락처',
              items: [
                if (_card.email != null)
                  _InfoItem(
                    icon: Icons.email_outlined,
                    label: '이메일',
                    value: _card.email!,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _card.email!));
                      showSuccessSnackBar(context, '이메일이 복사되었습니다.');
                    },
                  ),
                if (_card.phone != null)
                  _InfoItem(
                    icon: Icons.phone_outlined,
                    label: '전화',
                    value: _card.phone!,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _card.phone!));
                      showSuccessSnackBar(context, '전화번호가 복사되었습니다.');
                    },
                  ),
                if (_card.website != null)
                  _InfoItem(
                    icon: Icons.language_outlined,
                    label: '웹사이트',
                    value: _card.website!,
                  ),
              ],
            ),

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

            // SNS 링크
            if (_card.snsLinks.isNotEmpty) ...[
              const Text('SNS', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _card.snsLinks
                    .map((sns) => Chip(
                          label: Text(sns.platform),
                          avatar: const Icon(Icons.link, size: 14),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            // 공개 상태
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
                    _card.isPublicCard ? Icons.public : Icons.lock_outline,
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
