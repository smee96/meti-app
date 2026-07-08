// card_template_styles.dart — 명함 템플릿 컬러 시스템
// 각 템플릿 = 2컬러 그라데이션(start→end) + 악센트 1색 조합.
// template_id는 서버에 문자열로 저장되므로 id는 변경하지 않는다.

import 'package:flutter/material.dart';

class CardTemplateStyle {
  final String id;
  final String name;
  final Color start;   // 그라데이션 시작
  final Color end;     // 그라데이션 끝
  final Color accent;  // 포인트 컬러 (배지·이니셜·라인)
  final bool isLight;  // 밝은 배경 → 어두운 텍스트

  const CardTemplateStyle({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.accent,
    this.isLight = false,
  });

  LinearGradient get gradient => LinearGradient(
        colors: [start, end],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Color get textColor => isLight ? const Color(0xFF0f172a) : Colors.white;
  Color get subColor => isLight
      ? const Color(0xFF64748b)
      : Colors.white.withValues(alpha: 0.75);
}

/// 템플릿 목록 — 기존 5종(id 유지) + 2컬러 조합 신규 5종
const List<CardTemplateStyle> kCardTemplateStyles = [
  // 기존 템플릿 (id 유지, 스타일만 업그레이드)
  CardTemplateStyle(
    id: 'default',
    name: '엘리드',
    start: Color(0xFF0B1E40), // ELID Navy
    end: Color(0xFF1C3D72),   // Navy Glow
    accent: Color(0xFFC9A86A), // ELID Gold — 네이비×골드
  ),
  CardTemplateStyle(
    id: 'modern_blue',
    name: '모던 블루',
    start: Color(0xFF1e3a8a),
    end: Color(0xFF3b82f6),
    accent: Color(0xFF93c5fd),
  ),
  CardTemplateStyle(
    id: 'classic',
    name: '클래식',
    start: Color(0xFF1a1a2e),
    end: Color(0xFF16213e),
    accent: Color(0xFFe2b04a), // 잉크×앤틱골드
  ),
  CardTemplateStyle(
    id: 'minimal',
    name: '미니멀',
    start: Color(0xFFffffff),
    end: Color(0xFFe2e8f0),
    accent: Color(0xFF0B1E40),
    isLight: true,
  ),
  CardTemplateStyle(
    id: 'dark',
    name: '다크',
    start: Color(0xFF0f172a),
    end: Color(0xFF334155),
    accent: Color(0xFF38bdf8), // 블랙×아이스블루
  ),

  // ── 신규 2컬러 조합 ─────────────────────────────────────
  CardTemplateStyle(
    id: 'forest_gold',
    name: '포레스트',
    start: Color(0xFF064e3b),
    end: Color(0xFF047857),
    accent: Color(0xFFd4af37), // 딥그린×골드
  ),
  CardTemplateStyle(
    id: 'burgundy_rose',
    name: '버건디',
    start: Color(0xFF4c0519),
    end: Color(0xFF9f1239),
    accent: Color(0xFFfda4af), // 버건디×로즈
  ),
  CardTemplateStyle(
    id: 'ocean_coral',
    name: '오션',
    start: Color(0xFF134e4a),
    end: Color(0xFF0d9488),
    accent: Color(0xFFfb923c), // 틸×코랄
  ),
  CardTemplateStyle(
    id: 'violet_amber',
    name: '바이올렛',
    start: Color(0xFF4c1d95),
    end: Color(0xFF7c3aed),
    accent: Color(0xFFfbbf24), // 바이올렛×앰버
  ),
  CardTemplateStyle(
    id: 'ivory_navy',
    name: '아이보리',
    start: Color(0xFFfdf6ec),
    end: Color(0xFFf0e6d2),
    accent: Color(0xFF0B1E40), // 아이보리×네이비
    isLight: true,
  ),
];

/// id → 스타일 조회 (알 수 없는 id는 기본 템플릿)
CardTemplateStyle cardTemplateStyle(String id) {
  return kCardTemplateStyles.firstWhere(
    (t) => t.id == id,
    orElse: () => kCardTemplateStyles.first,
  );
}
