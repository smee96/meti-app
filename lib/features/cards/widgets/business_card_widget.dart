import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../../../core/theme/app_theme.dart';

class BusinessCardWidget extends StatelessWidget {
  final CardModel card;
  final VoidCallback? onTap;
  final bool isCompact;

  const BusinessCardWidget({
    super.key,
    required this.card,
    this.onTap,
    this.isCompact = false,
  });

  Color _getTemplateColor() {
    switch (card.templateId) {
      case 'modern_blue':
        return const Color(0xFF1e3a8a);
      case 'classic':
        return const Color(0xFF1a1a2e);
      case 'minimal':
        return const Color(0xFFf8fafc);
      case 'dark':
        return const Color(0xFF0f172a);
      default:
        return AppColors.primary;
    }
  }

  bool get _isLight {
    return card.templateId == 'minimal';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getTemplateColor();
    final textColor = _isLight ? AppColors.textPrimary : Colors.white;
    final subColor = _isLight
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isCompact ? 100 : 180,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 배경 데코레이션
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // 콘텐츠
            Padding(
              padding: const EdgeInsets.all(20),
              child: isCompact
                  ? _buildCompactContent(textColor, subColor)
                  : _buildFullContent(textColor, subColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullContent(Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이름 + 메티 로고
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (card.title != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    card.title!,
                    style: TextStyle(color: subColor, fontSize: 13),
                  ),
                ],
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'METI',
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),

        // 회사
        if (card.company != null)
          Row(
            children: [
              Icon(Icons.business_outlined, size: 14, color: subColor),
              const SizedBox(width: 6),
              Text(card.company!, style: TextStyle(color: subColor, fontSize: 13)),
            ],
          ),
        const SizedBox(height: 6),

        // 이메일 / 전화
        Row(
          children: [
            if (card.email != null) ...[
              Icon(Icons.email_outlined, size: 14, color: subColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  card.email!,
                  style: TextStyle(color: subColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (card.phone != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.phone_outlined, size: 14, color: subColor),
              const SizedBox(width: 4),
              Text(card.phone!, style: TextStyle(color: subColor, fontSize: 12)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCompactContent(Color textColor, Color subColor) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.name,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (card.title != null)
              Text(card.title!, style: TextStyle(color: subColor, fontSize: 12)),
            if (card.company != null)
              Text(card.company!, style: TextStyle(color: subColor, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
