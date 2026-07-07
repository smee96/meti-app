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
      case 'green':
        return const Color(0xFF065f46);
      default:
        return AppColors.primary;
    }
  }

  bool get _isLight => card.templateId == 'minimal';

  @override
  Widget build(BuildContext context) {
    final bgColor = _getTemplateColor();
    final textColor = _isLight ? AppColors.textPrimary : Colors.white;
    final subColor = _isLight
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.75);

    if (isCompact) {
      return GestureDetector(
        onTap: onTap,
        child: _buildCompactCard(bgColor, textColor, subColor),
      );
    }

    // 세로형 명함 (기본)
    return GestureDetector(
      onTap: onTap,
      child: _buildVerticalCard(bgColor, textColor, subColor),
    );
  }

  // ── 세로형 명함 ──────────────────────────────────
  Widget _buildVerticalCard(
      Color bgColor, Color textColor, Color subColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 장식 원
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // 콘텐츠
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단: ELID 로고
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ELID',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    // v2.5: 공개/비공개 아이콘 🌐 / 🔒
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            card.isPublic == 1
                                ? Icons.public
                                : Icons.lock_outline,
                            size: 12,
                            color: textColor.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            card.isPublic == 1 ? '공개' : '비공개',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.75),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 아바타 + 이름/직책
                Row(
                  children: [
                    // 아바타
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          card.name.isNotEmpty
                              ? card.name[0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.name,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (card.title != null &&
                              card.title!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              card.title!,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (card.company != null &&
                              card.company!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              card.company!,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // 구분선
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.15),
                    height: 1,
                  ),
                ),

                // 연락처 정보
                if (card.email != null && card.email!.isNotEmpty)
                  _contactRow(
                      Icons.email_outlined, card.email!, textColor, subColor),
                if (card.phone != null && card.phone!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _contactRow(
                      Icons.phone_outlined, card.phone!, textColor, subColor),
                ],
                if (card.website != null && card.website!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _contactRow(Icons.language_outlined, card.website!,
                      textColor, subColor),
                ],

                // 약력/경력 섹션
                if (card.careers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.15),
                      height: 1,
                    ),
                  ),
                  Text(
                    '약력',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...card.careers.take(5).map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 6, right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: textColor.withValues(alpha: 0.5),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.title,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (c.period != null &&
                                        c.period!.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        [c.period, c.detail]
                                            .where((s) =>
                                                s != null && s.isNotEmpty)
                                            .join(' · '),
                                        style: TextStyle(
                                          color: subColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (card.careers.length > 5)
                    Text(
                      '외 ${card.careers.length - 5}개',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 11,
                      ),
                    ),
                ],

                // 자기소개
                if (card.bio != null && card.bio!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.15),
                      height: 1,
                    ),
                  ),
                  Text(
                    card.bio!,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 12,
                      height: 1.6,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(
      IconData icon, String text, Color textColor, Color subColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: subColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: subColor, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── 컴팩트형 (목록용) ────────────────────────────
  Widget _buildCompactCard(
      Color bgColor, Color textColor, Color subColor) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 아바타
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  card.name.isNotEmpty ? card.name[0].toUpperCase() : 'M',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (card.title != null && card.title!.isNotEmpty)
                    Text(
                      card.title!,
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                  if (card.company != null && card.company!.isNotEmpty)
                    Text(
                      card.company!,
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                ],
              ),
            ),
            // ELID 태그
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'ELID',
                style: TextStyle(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
