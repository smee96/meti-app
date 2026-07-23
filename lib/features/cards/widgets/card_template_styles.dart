// card_template_styles.dart — (호환 심) 구 템플릿 스타일 → 카탈로그 위임
//
// 2026-07-22 서버 핸드오프로 디자인이 카탈로그 24종으로 전면 교체됨.
// 신규 코드는 CardDesignCatalog/CardDesignSpec을 직접 쓰고,
// 이 파일은 기존 화면(public_card_screen 등)의 CardTemplateStyle 소비처를
// 깨지 않기 위한 어댑터만 남긴다.

import 'package:flutter/material.dart';
import '../services/card_design_catalog.dart';

class CardTemplateStyle {
  final String id;
  final String name;
  final Color start;   // 배경 (구 그라데이션 시작 — 현재는 단색)
  final Color end;     // 배경 (구 그라데이션 끝)
  final Color accent;  // 포인트 컬러
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

/// template_id → 스타일 (카탈로그 해석: exact → legacy_alias → default)
CardTemplateStyle cardTemplateStyle(String id) {
  final spec = CardDesignCatalog.instance.resolve(id);
  return CardTemplateStyle(
    id: spec.templateId,
    name: spec.nameKo,
    start: spec.bgPrimary,
    end: spec.bgPrimary,
    accent: spec.accent,
    isLight: spec.isLight,
  );
}
