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

  // 템플릿별 명함 바탕재(stock) 기본색
  Color _baseColor() {
    switch (card.templateId) {
      case 'classic':
        return const Color(0xFF14161C); // midnight
      case 'minimal':
        return const Color(0xFFF8FAFC);
      case 'dark':
        return const Color(0xFF06303A); // teal-ish
      case 'green':
        return const Color(0xFF0C5163);
      case 'modern_blue':
      default:
        return AppColors.navy; // #0B1E40
    }
  }

  bool get _isLight => card.templateId == 'minimal';

  // ── 명함 그라데이션 (glow → base → deep) ───────────────
  Gradient _cardGradient() {
    final base = _baseColor();
    final isNavy =
        card.templateId == 'modern_blue' || card.templateId == 'default';
    final glow = isNavy ? AppColors.navyGlow : _lighten(base, 0.13);
    final deep = isNavy ? AppColors.navyDeep : _darken(base, 0.10);
    return RadialGradient(
      center: const Alignment(0.56, -1.1), // 78% -10%
      radius: 1.3,
      colors: [glow, base, deep],
      stops: const [0.0, 0.42, 1.0],
    );
  }

  static Color _lighten(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amt).clamp(0.0, 1.0)).toColor();
  }

  static Color _darken(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isLight ? AppColors.textPrimary : Colors.white;
    final subColor = _isLight
        ? AppColors.textSecondary
        : Colors.white.withValues(alpha: 0.78);
    // 골드 악센트 (밝은 명함에선 진한 골드)
    final goldAccent = _isLight ? AppColors.goldDeep : AppColors.gold;

    return GestureDetector(
      onTap: onTap,
      child: isCompact
          ? _buildCompactCard(textColor, subColor, goldAccent)
          : _buildVerticalCard(textColor, subColor, goldAccent),
    );
  }

  // ── 금박 워드마크 (MET + 골드 I) ──────────────────────
  Widget _wordmark(Color textColor, Color goldAccent,
      {double fontSize = 10, double letterSpacing = 2}) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: letterSpacing,
        ),
        children: [
          TextSpan(text: 'MET', style: TextStyle(color: textColor)),
          TextSpan(text: 'I', style: TextStyle(color: goldAccent)),
        ],
      ),
    );
  }

  // ── 명함 공통 데코레이션 (그라데이션 + 금박 테두리 + 그림자) ──
  BoxDecoration _cardDecoration(double radius) {
    return BoxDecoration(
      gradient: _isLight ? null : _cardGradient(),
      color: _isLight ? _baseColor() : null,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        // 금박 가장자리 (헤어라인)
        color: _isLight
            ? AppColors.border
            : AppColors.gold.withValues(alpha: 0.4),
        width: 1,
      ),
      boxShadow: _isLight
          ? [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
          : [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.55),
                blurRadius: 40,
                spreadRadius: -12,
                offset: const Offset(0, 18),
              ),
            ],
    );
  }

  // 기요셰(보안 인쇄) 미세 사선 텍스처 오버레이
  Widget _guillocheOverlay(double radius) {
    if (_isLight) return const SizedBox.shrink();
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _GuillochePainter(
            Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
    );
  }

  // ── 세로형 명함 ──────────────────────────────────
  Widget _buildVerticalCard(
      Color textColor, Color subColor, Color goldAccent) {
    const radius = 22.0;
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(radius),
      child: Stack(
        children: [
          // 우상단 sheen
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
          // 기요셰 텍스처
          _guillocheOverlay(radius),

          // 콘텐츠
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단: METI 워드마크 + 공개여부
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _wordmark(textColor, goldAccent,
                        fontSize: 12, letterSpacing: 3),
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
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.55),
                          width: 1.5,
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
                            const SizedBox(height: 3),
                            // 회사명 = 골드 + 점 prefix
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: goldAccent,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    card.company!,
                                    style: TextStyle(
                                      color: goldAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
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
                    color: AppColors.gold.withValues(alpha: 0.18),
                    height: 1,
                  ),
                ),

                // 연락처 정보
                if (card.email != null && card.email!.isNotEmpty)
                  _contactRow(
                      Icons.email_outlined, card.email!, subColor, goldAccent),
                if (card.phone != null && card.phone!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _contactRow(
                      Icons.phone_outlined, card.phone!, subColor, goldAccent),
                ],
                if (card.website != null && card.website!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _contactRow(Icons.language_outlined, card.website!,
                      subColor, goldAccent),
                ],

                // 약력/경력 섹션
                if (card.careers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      height: 1,
                    ),
                  ),
                  Text(
                    '약력',
                    style: TextStyle(
                      color: goldAccent.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                                  color: goldAccent.withValues(alpha: 0.7),
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
                      color: AppColors.gold.withValues(alpha: 0.18),
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
      IconData icon, String text, Color subColor, Color goldAccent) {
    return Row(
      children: [
        Icon(icon, size: 14, color: goldAccent.withValues(alpha: 0.85)),
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
      Color textColor, Color subColor, Color goldAccent) {
    const radius = 16.0;
    return Container(
      height: 92,
      decoration: _cardDecoration(radius),
      child: Stack(
        children: [
          _guillocheOverlay(radius),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 아바타
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
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
                          style: TextStyle(
                            color: goldAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                // METI 워드마크
                _wordmark(textColor, goldAccent,
                    fontSize: 10, letterSpacing: 1.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 기요셰(보안 인쇄) 미세 사선 텍스처
class _GuillochePainter extends CustomPainter {
  final Color lineColor;
  _GuillochePainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const gap = 8.0;
    // 약 115도 사선 반복
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GuillochePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
