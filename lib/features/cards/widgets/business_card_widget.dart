import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'card_template_styles.dart';

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

  @override
  Widget build(BuildContext context) {
    final style = cardTemplateStyle(card.templateId);
    final textColor = style.textColor;
    final subColor = style.subColor;

    if (isCompact) {
      return GestureDetector(
        onTap: onTap,
        child: _buildCompactCard(style, textColor, subColor),
      );
    }

    // 세로형 명함 — 디자인(레이아웃)별 분기 (template_id의 `__디자인` 접미사)
    final design = cardDesignIdOf(card.templateId);
    final Widget body = switch (design) {
      'center' => _buildCenterCard(style, textColor, subColor),
      'leftbar' => _buildLeftbarCard(style, textColor, subColor),
      _ => _buildVerticalCard(style, textColor, subColor),
    };
    return GestureDetector(onTap: onTap, child: body);
  }

  // ── 공용 카드 프레임 — 브랜드 킷(2026-07-20) 명함 비주얼 DNA ──
  // 라디얼 그라데이션(우상단 글로우→딥) + 골드 포일 헤어라인(.45) + 기요셰 사선 텍스처
  Widget _cardFrame(CardTemplateStyle style,
      {required Widget child, double radius = 20}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.8, -1.1),
          radius: 1.8,
          colors: [style.start, style.end],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: style.accent.withValues(alpha: style.isLight ? 0.30 : 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: style.start.withValues(alpha: style.isLight ? 0.15 : 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _GuillochePainter(
                  (style.isLight ? const Color(0xFF0E1726) : Colors.white)
                      .withValues(alpha: 0.05),
                ),
              ),
            ),
            // Stack의 loose constraint로 콘텐츠가 좌상단에 붙지 않도록 전체 폭 강제
            SizedBox(width: double.infinity, child: child),
          ],
        ),
      ),
    );
  }

  // ── 센터형: 아바타·이름·연락처 중앙 정렬, 장식 없이 미니멀 ──
  Widget _buildCenterCard(
      CardTemplateStyle style, Color textColor, Color subColor) {
    return _cardFrame(
      style,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 아바타
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.accent
                    .withValues(alpha: style.isLight ? 0.10 : 0.18),
                border: Border.all(
                    color: style.accent.withValues(alpha: 0.45), width: 2),
              ),
              child: Center(
                child: Text(
                  card.name.isNotEmpty ? card.name[0].toUpperCase() : 'E',
                  style: TextStyle(
                    color: style.isLight ? style.accent : textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              card.name,
              style: TextStyle(
                  color: textColor, fontSize: 22, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if ((card.title ?? '').isNotEmpty || (card.company ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [card.title, card.company]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' · '),
                  style: TextStyle(color: subColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            // 악센트 짧은 구분선
            Container(
              width: 36,
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 16),
              color: style.accent.withValues(alpha: 0.7),
            ),
            if (card.email != null && card.email!.isNotEmpty)
              _centerContactRow(Icons.email_outlined, card.email!, subColor),
            if (card.phone != null && card.phone!.isNotEmpty)
              _centerContactRow(Icons.phone_outlined, card.phone!, subColor),
            if (card.website != null && card.website!.isNotEmpty)
              _centerContactRow(
                  Icons.language_outlined, card.website!, subColor),
            if (card.bio != null && card.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                card.bio!,
                style: TextStyle(color: subColor, fontSize: 12, height: 1.6),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'ELID',
              style: TextStyle(
                color: style.accent,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerContactRow(IconData icon, String text, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: subColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: subColor, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── 라인형: 좌측 악센트 세로 바 + 좌측 정렬 콘텐츠 ──
  Widget _buildLeftbarCard(
      CardTemplateStyle style, Color textColor, Color subColor) {
    return _cardFrame(
      style,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 악센트 바
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: style.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ELID',
                      style: TextStyle(
                        color: style.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      card.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((card.title ?? '').isNotEmpty ||
                        (card.company ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [card.title, card.company]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(' · '),
                          style: TextStyle(color: subColor, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 18),
                    if (card.email != null && card.email!.isNotEmpty)
                      _contactRow(Icons.email_outlined, card.email!,
                          textColor, subColor),
                    if (card.phone != null && card.phone!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _contactRow(Icons.phone_outlined, card.phone!,
                          textColor, subColor),
                    ],
                    if (card.website != null && card.website!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _contactRow(Icons.language_outlined, card.website!,
                          textColor, subColor),
                    ],
                    if (card.bio != null && card.bio!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        card.bio!,
                        style: TextStyle(
                            color: subColor, fontSize: 12, height: 1.6),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 세로형 명함 (클래식) ──────────────────────────
  Widget _buildVerticalCard(
      CardTemplateStyle style, Color textColor, Color subColor) {
    return _cardFrame(
      style,
      child: Padding(
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
                        color: style.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: style.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'ELID',
                        style: TextStyle(
                          color: style.accent,
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
                        color: style.accent.withValues(
                            alpha: style.isLight ? 0.10 : 0.18),
                        border: Border.all(
                          color: style.accent.withValues(alpha: 0.45),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          card.name.isNotEmpty
                              ? card.name[0].toUpperCase()
                              : 'E',
                          style: TextStyle(
                            color: style.isLight ? style.accent : textColor,
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
                    color: textColor.withValues(alpha: 0.15),
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
      CardTemplateStyle style, Color textColor, Color subColor) {
    return SizedBox(
      height: 90,
      child: _cardFrame(
        style,
        radius: 14,
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
                color: style.accent.withValues(
                    alpha: style.isLight ? 0.10 : 0.18),
                border: Border.all(
                    color: style.accent.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  card.name.isNotEmpty ? card.name[0].toUpperCase() : 'E',
                  style: TextStyle(
                    color: style.isLight ? style.accent : textColor,
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
                color: style.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'ELID',
                style: TextStyle(
                  color: style.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// 기요셰 사선 텍스처 — 킷 스펙: repeating 115deg, 1px 라인 / 9px 간격
// ════════════════════════════════════════════════════════════
class _GuillochePainter extends CustomPainter {
  final Color color;
  const _GuillochePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(25 * math.pi / 180); // 115deg 그라데이션 축 ⟂ 라인
    for (double x = -diag; x <= diag; x += 9) {
      canvas.drawLine(Offset(x, -diag), Offset(x, diag), paint);
    }
  }

  @override
  bool shouldRepaint(_GuillochePainter oldDelegate) =>
      oldDelegate.color != color;
}
