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

/// 템플릿 목록 — 디자인 킷 공식 팔레트 (tokens.json) 기반
/// 마감재(cardFinish): navy(#1C3D72→#06122A) · midnight(#2A2E38→#070809) · teal(#0C5163→#021C23)
/// 악센트(accentOptions): gold #C9A86A · mint #6ABE9F · coral #E58773 · violet #9283DC
const List<CardTemplateStyle> kCardTemplateStyles = [
  // ── 킷 공식 조합 ────────────────────────────────────────
  CardTemplateStyle(
    id: 'default',
    name: '엘리드',
    start: Color(0xFF1C3D72), // navy glow
    end: Color(0xFF06122A),   // navy deep
    accent: Color(0xFFC9A86A), // gold
  ),
  CardTemplateStyle(
    id: 'dark',
    name: '미드나잇',
    start: Color(0xFF2A2E38), // midnight glow
    end: Color(0xFF070809),   // midnight deep
    accent: Color(0xFFC9A86A), // gold
  ),
  CardTemplateStyle(
    id: 'ocean_coral',
    name: '틸 코랄',
    start: Color(0xFF0C5163), // teal glow
    end: Color(0xFF021C23),   // teal deep
    accent: Color(0xFFE58773), // coral (oklch 0.72 0.12 33)
  ),
  CardTemplateStyle(
    id: 'forest_gold',
    name: '민트',
    start: Color(0xFF1C3D72), // navy glow
    end: Color(0xFF06122A),
    accent: Color(0xFF6ABE9F), // mint (oklch 0.74 0.095 168)
  ),
  CardTemplateStyle(
    id: 'violet_amber',
    name: '바이올렛',
    start: Color(0xFF1C3D72), // navy glow
    end: Color(0xFF06122A),
    accent: Color(0xFF9283DC), // violet (oklch 0.66 0.13 290)
  ),

  // ── 라이트 & 레거시 조합 ────────────────────────────────
  CardTemplateStyle(
    id: 'minimal',
    name: '미니멀',
    start: Color(0xFFffffff),
    end: Color(0xFFe2e8f0),
    accent: Color(0xFF0B1E40),
    isLight: true,
  ),
  CardTemplateStyle(
    id: 'ivory_navy',
    name: '아이보리',
    start: Color(0xFFfdf6ec),
    end: Color(0xFFf0e6d2),
    accent: Color(0xFF0B1E40),
    isLight: true,
  ),
  CardTemplateStyle(
    id: 'burgundy_rose',
    name: '버건디',
    start: Color(0xFF4c0519),
    end: Color(0xFF9f1239),
    accent: Color(0xFFfda4af),
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
    accent: Color(0xFFe2b04a),
  ),
];

/// id → 스타일 조회 (알 수 없는 id는 기본 템플릿)
CardTemplateStyle cardTemplateStyle(String id) {
  return kCardTemplateStyles.firstWhere(
    (t) => t.id == id,
    orElse: () => kCardTemplateStyles.first,
  );
}
