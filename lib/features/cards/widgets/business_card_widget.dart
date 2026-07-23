// business_card_widget.dart — 명함 렌더러 (카탈로그 24종 · 레이아웃 7종)
//
// 서버 핸드오프(2026-07-22): 디자인은 {palette}__{layout} 24종 고정 세트.
// 레이아웃 위젯 7개만 구현하고 색은 CardDesignSpec(카탈로그)에서 주입한다.
// 원본 PNG(더미 텍스트 미리보기)가 시각 기준 — 실데이터는 여기서 직접 렌더.
// 웹 레퍼런스: https://staging.the-meti.pages.dev/card/{id}

import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/card_design_catalog.dart';

/// 명함 비율 (원본 1653×1020)
const double kCardAspectRatio = 1653 / 1020;

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
    final spec = CardDesignCatalog.instance.resolve(card.templateId);

    if (isCompact) {
      return GestureDetector(onTap: onTap, child: _CompactCard(card: card, spec: spec));
    }

    final Widget face = switch (spec.layout) {
      'classic' => _ClassicFace(card: card, spec: spec),
      'split' => _SplitFace(card: card, spec: spec),
      'serif' => _SerifFace(card: card, spec: spec),
      'band' => _BandFace(card: card, spec: spec),
      'mono' => _MonoFace(card: card, spec: spec),
      'edge' => _EdgeFace(card: card, spec: spec),
      _ => _SolidFace(card: card, spec: spec),
    };

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: kCardAspectRatio,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: spec.isLight
                ? Border.all(color: const Color(0x1F0E1726))
                : null,
            boxShadow: [
              BoxShadow(
                color: spec.bgPrimary
                    .withValues(alpha: spec.isLight ? 0.15 : 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: face,
          ),
        ),
      ),
    );
  }
}

// ── 공통 소형 위젯 ──────────────────────────────────────────

/// 회사명 캡스 표기 (없으면 빈 위젯)
class _CompanyCaps extends StatelessWidget {
  final String? company;
  final Color color;
  final double size;
  const _CompanyCaps(this.company, this.color, {this.size = 12});

  @override
  Widget build(BuildContext context) {
    if (company == null || company!.isEmpty) return const SizedBox.shrink();
    return Text(
      company!.toUpperCase(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        height: 1.3,
      ),
    );
  }
}

/// T/E/W 라벨 연락처 행 (classic·split·edge)
class _LabeledContact extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  const _LabeledContact(this.label, this.value,
      {required this.labelColor, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: labelColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
          const SizedBox(width: 7),
          Flexible(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: valueColor, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

List<Widget> _tewContacts(CardModel c,
    {required Color labelColor, required Color valueColor}) {
  return [
    if ((c.phone ?? '').isNotEmpty)
      _LabeledContact('T', c.phone!, labelColor: labelColor, valueColor: valueColor),
    if ((c.email ?? '').isNotEmpty)
      _LabeledContact('E', c.email!, labelColor: labelColor, valueColor: valueColor),
    if ((c.website ?? '').isNotEmpty)
      _LabeledContact('W', c.website!, labelColor: labelColor, valueColor: valueColor),
  ];
}

// ── 1. solid — 단색 풀블리드 ────────────────────────────────
class _SolidFace extends StatelessWidget {
  final CardModel card;
  final CardDesignSpec spec;
  const _SolidFace({required this.card, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: spec.bgPrimary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompanyCaps(card.company, spec.subPrimary),
          const Spacer(),
          Text(card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: spec.onPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1)),
          if ((card.title ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(card.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: spec.subPrimary, fontSize: 12.5)),
            ),
          if ((card.email ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: spec.onPrimary.withValues(alpha: 0.85),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(card.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: spec.subPrimary, fontSize: 11.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── 2. classic — 다크 + 구분선 + T/E/W ──────────────────────
class _ClassicFace extends StatelessWidget {
  final CardModel card;
  final CardDesignSpec spec;
  const _ClassicFace({required this.card, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: spec.bgPrimary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CompanyCaps(card.company, spec.subPrimary),
                    if ((card.company ?? '').isNotEmpty)
                      Container(
                        width: 130,
                        height: 1,
                        margin: const EdgeInsets.only(top: 8),
                        color: spec.onPrimary.withValues(alpha: 0.25),
                      ),
                  ],
                ),
              ),
              Text('DIGITAL CARD',
                  style: TextStyle(
                      color: spec.subPrimary.withValues(alpha: 0.8),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          Text(card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: spec.onPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800)),
          if ((card.title ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(card.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: spec.subPrimary, fontSize: 12.5)),
            ),
          const Spacer(),
          ..._tewContacts(card,
              labelColor: spec.accent, valueColor: spec.subPrimary),
        ],
      ),
    );
  }
}

// ── 3. split — 좌 다크 / 우 라이트 세로 분할 ─────────────────
class _SplitFace extends StatelessWidget {
  final CardModel card;
  final CardDesignSpec spec;
  const _SplitFace({required this.card, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            color: spec.bgPrimary,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyCaps(card.company, spec.onPrimary, size: 11),
                Container(
                  width: 26,
                  height: 2,
                  margin: const EdgeInsets.only(top: 8),
                  color: spec.accent,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            color: spec.bgSecondary,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: spec.onSecondary,
                        fontSize: 21,
                        fontWeight: FontWeight.w800)),
                if ((card.title ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(card.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: spec.accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 12),
                ..._tewContacts(card,
                    labelColor: spec.onSecondary, valueColor: spec.subSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 4. serif — 라이트 중앙정렬 세리프 ───────────────────────
class _SerifFace extends StatelessWidget {
  final CardModel card;
  final CardDesignSpec spec;
  const _SerifFace({required this.card, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: spec.bgPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('EST. 2026 · SEOUL',
              style: TextStyle(
                  color: spec.subPrimary,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5)),
          const Spacer(),
          if ((card.company ?? '').isNotEmpty) ...[
            Text(card.company!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: spec.subPrimary,
                    fontSize: 12,
                    fontFamily: 'serif',
                    letterSpacing: 1.2)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('—',
                  style: TextStyle(color: spec.subPrimary, fontSize: 10)),
            ),
          ],
          Text(card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: spec.onPrimary,
                  fontSize: 26,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700)),
          if ((card.title ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(card.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: spec.subPrimary, fontSize: 11.5)),
            ),
          const Spacer(),
          Text(
            [card.phone, card.email]
                .where((s) => s != null && s.isNotEmpty)
                .join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: spec.subPrimary, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

// ── 5. band — 상단 다크밴드 / 하단 라이트밴드 ────────────────
class _BandFace extends StatelessWidget {
  final CardModel card;
  final CardDesignSpec spec;
  const _BandFace({required this.card, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 11,
          child: Container(
            color: spec.bgPrimary,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _CompanyCaps(card.company, spec.subPrimary,
                            size: 11)),
                    Text('STUDIO',
                        style: TextStyle(
                            color: spec.subPrimary.withValues(alpha: 0.8),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2)),
                  ],
                ),
                const Spacer(),
                Text(card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: spec.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 9,
          child: Container(
            color: spec.bgSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(card.title ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: spec.onSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if ((card.phone ?? '').isNotEmpty)
                      Text(card.phone!,
                          style: TextStyle(
                              color: spec.subSecondary, fontSize: 10.5)),
                    if ((card.email ?? '').isNotEmpty)
                      Text(card.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: spec.subSecondary, fontSize: 10.5)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── 6. mono — 미니멀 타이포 ─────────────────────────────────
class _MonoFace extends StatelessWidget {
  final CardModel card;
  final CardDesignSpec spec;
  const _MonoFace({required this.card, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: spec.bgPrimary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.company ?? card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: spec.onPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('DIGITAL BUSINESS CARD',
                        style: TextStyle(
                            color: spec.subPrimary,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2)),
                  ],
                ),
              ),
              Container(width: 2, height: 30, color: spec.accent),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: spec.onPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w800)),
                    if ((card.title ?? '').isNotEmpty)
                      Text(card.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: spec.subPrimary, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if ((card.phone ?? '').isNotEmpty)
                    Text(card.phone!,
                        style:
                            TextStyle(color: spec.subPrimary, fontSize: 10)),
                  if ((card.email ?? '').isNotEmpty)
                    Text(card.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: spec.subPrimary, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 7. edge — 라이트 + 모노그램 배지 ────────────────────────
class _EdgeFace extends StatelessWidget {
  final CardModel card;
  final CardDesignSpec spec;
  const _EdgeFace({required this.card, required this.spec});

  @override
  Widget build(BuildContext context) {
    final monogram = ((card.company ?? '').isNotEmpty
            ? card.company![0]
            : (card.name.isNotEmpty ? card.name[0] : 'E'))
        .toUpperCase();
    return Container(
      color: spec.bgPrimary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _CompanyCaps(card.company, spec.subPrimary, size: 10.5)),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: spec.accent, width: 1.2),
                ),
                child: Center(
                  child: Text(monogram,
                      style: TextStyle(
                          color: spec.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: spec.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          if ((card.title ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(card.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: spec.subPrimary, fontSize: 12)),
            ),
          const SizedBox(height: 10),
          ..._tewContacts(card,
              labelColor: spec.accent, valueColor: spec.subPrimary),
        ],
      ),
    );
  }
}

// ── 컴팩트형 (목록용, 기존 유지) ─────────────────────────────
class _CompactCard extends StatelessWidget {
  final CardModel card;
  final CardDesignSpec spec;
  const _CompactCard({required this.card, required this.spec});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: spec.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        border: spec.isLight
            ? Border.all(color: const Color(0x1F0E1726))
            : null,
        boxShadow: [
          BoxShadow(
            color:
                spec.bgPrimary.withValues(alpha: spec.isLight ? 0.12 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: spec.accent.withValues(alpha: spec.isLight ? 0.10 : 0.18),
                border:
                    Border.all(color: spec.accent.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  card.name.isNotEmpty ? card.name[0].toUpperCase() : 'E',
                  style: TextStyle(
                    color: spec.isLight ? spec.accent : spec.onPrimary,
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
                  Text(card.name,
                      style: TextStyle(
                          color: spec.onPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  if ((card.title ?? '').isNotEmpty)
                    Text(card.title!,
                        style:
                            TextStyle(color: spec.subPrimary, fontSize: 12)),
                  if ((card.company ?? '').isNotEmpty)
                    Text(card.company!,
                        style:
                            TextStyle(color: spec.subPrimary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: spec.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'ELID',
                style: TextStyle(
                  color: spec.isLight ? spec.accent : spec.onPrimary,
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
