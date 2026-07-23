// card_design_catalog.dart — 명함 디자인 카탈로그 (서버 핸드오프 2026-07-22)
//
// 단일 소스: GET {webBaseUrl}/static/card-designs/catalog.json
// - 24종 디자인 = 7개 레이아웃 패밀리 × 큐레이션 팔레트. 색값은 카탈로그가 기준.
// - 소비 방식(회신 §8-3): 런타임 fetch → SharedPreferences 캐시 → 번들 스냅샷 폴백.
// - 레거시 해석(회신 §8-1, 비파괴): 저장된 template_id는 그대로 두고 렌더 시에만
//   exact → legacy_alias[전체] → legacy_alias[팔레트부] → default 순으로 치환.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// 카탈로그 한 항목 (색값은 파싱된 Color)
class CardDesignSpec {
  final String templateId;
  final String palette;
  final String layout; // solid | classic | split | serif | band | mono | edge
  final String nameKo;
  final String thumbnailPath; // 서버 상대 경로
  final Color bgPrimary;
  final Color bgSecondary;
  final Color onPrimary;
  final Color subPrimary;
  final Color onSecondary;
  final Color subSecondary;
  final Color accent;

  const CardDesignSpec({
    required this.templateId,
    required this.palette,
    required this.layout,
    required this.nameKo,
    required this.thumbnailPath,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.onPrimary,
    required this.subPrimary,
    required this.onSecondary,
    required this.subSecondary,
    required this.accent,
  });

  /// 밝은 배경 여부 (라이트 계열 → 잉크 텍스트)
  bool get isLight => bgPrimary.computeLuminance() > 0.5;

  /// 썸네일 절대 URL
  String get thumbnailUrl => '${AppConfig.webBaseUrl}$thumbnailPath';

  factory CardDesignSpec.fromJson(Map<String, dynamic> j) {
    final bgPrimary = _parseColor(j['bg_primary'] as String?) ??
        const Color(0xFF0F2A4A);
    return CardDesignSpec(
      templateId: j['template_id'] as String,
      palette: j['palette'] as String? ?? '',
      layout: j['layout'] as String? ?? 'solid',
      nameKo: j['name_ko'] as String? ?? j['template_id'] as String,
      thumbnailPath: j['thumbnail'] as String? ??
          '/static/card-designs/${j['template_id']}.png',
      bgPrimary: bgPrimary,
      bgSecondary: _parseColor(j['bg_secondary'] as String?) ?? bgPrimary,
      onPrimary: _parseColor(j['on_primary'] as String?) ?? _onFor(bgPrimary),
      subPrimary: _parseColor(j['sub_primary'] as String?) ??
          _onFor(bgPrimary).withValues(alpha: 0.72),
      onSecondary:
          _parseColor(j['on_secondary'] as String?) ?? _onFor(bgPrimary),
      subSecondary: _parseColor(j['sub_secondary'] as String?) ??
          _onFor(bgPrimary).withValues(alpha: 0.72),
      accent: _parseColor(j['accent'] as String?) ?? const Color(0xFFC9A86A),
    );
  }

  static Color _onFor(Color bg) => bg.computeLuminance() > 0.5
      ? const Color(0xFF0E1726)
      : const Color(0xFFFFFFFF);
}

/// `#RRGGBB` / `#RGB` / `rgba(r,g,b,a)` 파서
Color? _parseColor(String? s) {
  if (s == null || s.isEmpty) return null;
  final v = s.trim();
  if (v.startsWith('#')) {
    var hex = v.substring(1);
    if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
    final n = int.tryParse(hex, radix: 16);
    if (n == null) return null;
    return Color(0xFF000000 | n);
  }
  final m = RegExp(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)')
      .firstMatch(v);
  if (m != null) {
    final a = m.group(4) == null ? 1.0 : double.parse(m.group(4)!);
    return Color.fromRGBO(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!), a);
  }
  return null;
}

class CardDesignCatalog {
  CardDesignCatalog._();
  static final CardDesignCatalog instance = CardDesignCatalog._();

  static const _prefsKey = 'card_design_catalog_json';
  static const _bundleAsset = 'assets/card_design_catalog.json';

  int _version = 0;
  String _defaultId = 'deepblue__classic';
  List<CardDesignSpec> _designs = const [];
  Map<String, String> _legacyAlias = const {};
  final Map<String, CardDesignSpec> _byId = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get version => _version;
  List<CardDesignSpec> get designs => _designs;
  String get defaultId => _defaultId;

  /// 앱 시작 시 1회 호출 (스플래시). 실패해도 번들 폴백으로 항상 로드됨.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    // 1) 번들 스냅샷 먼저 (즉시 렌더 보장)
    try {
      _apply(json.decode(await rootBundle.loadString(_bundleAsset)));
    } catch (e) {
      debugPrint('CardDesignCatalog: bundle load failed: $e');
    }
    // 2) 캐시가 더 최신이면 교체
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefsKey);
      if (cached != null) {
        final j = json.decode(cached) as Map<String, dynamic>;
        if ((j['version'] as int? ?? 0) > _version) _apply(j);
      }
    } catch (_) {}
    // 3) mock 모드가 아니면 서버에서 갱신 (실패 무시)
    if (!AppConfig.useMock) {
      try {
        final res = await http
            .get(Uri.parse(
                '${AppConfig.webBaseUrl}/static/card-designs/catalog.json'))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final j = json.decode(utf8.decode(res.bodyBytes))
              as Map<String, dynamic>;
          if ((j['version'] as int? ?? 0) >= _version) {
            _apply(j);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefsKey, utf8.decode(res.bodyBytes));
          }
        }
      } catch (e) {
        debugPrint('CardDesignCatalog: fetch failed (fallback 유지): $e');
      }
    }
  }

  void _apply(Map<String, dynamic> j) {
    _version = j['version'] as int? ?? 0;
    _defaultId = j['default'] as String? ?? _defaultId;
    _designs = (j['designs'] as List? ?? const [])
        .map((d) => CardDesignSpec.fromJson(Map<String, dynamic>.from(d as Map)))
        .toList(growable: false);
    _legacyAlias = Map<String, String>.from(j['legacy_alias'] as Map? ?? {});
    _byId
      ..clear()
      ..addEntries(_designs.map((d) => MapEntry(d.templateId, d)));
    _loaded = _designs.isNotEmpty;
  }

  /// template_id → 디자인 스펙 (레거시 alias 비파괴 해석)
  /// exact → alias[전체 id] → alias[팔레트부] → default
  CardDesignSpec resolve(String templateId) {
    final exact = _byId[templateId];
    if (exact != null) return exact;
    final full = _legacyAlias[templateId];
    if (full != null && _byId.containsKey(full)) return _byId[full]!;
    // 구 합성 id(`default__center` 등, 2026-07-20 §3)는 팔레트부만 alias 조회
    final palettePart = templateId.split('__').first;
    final byPalette = _legacyAlias[palettePart];
    if (byPalette != null && _byId.containsKey(byPalette)) {
      return _byId[byPalette]!;
    }
    return _byId[_defaultId] ?? _fallbackSpec;
  }

  /// 카탈로그가 아예 비었을 때의 최후 폴백 (딥블루 클래식)
  static const CardDesignSpec _fallbackSpec = CardDesignSpec(
    templateId: 'deepblue__classic',
    palette: 'deepblue',
    layout: 'classic',
    nameKo: '딥블루',
    thumbnailPath: '/static/card-designs/deepblue__classic.png',
    bgPrimary: Color(0xFF0F2A4A),
    bgSecondary: Color(0xFF0F2A4A),
    onPrimary: Color(0xFFFFFFFF),
    subPrimary: Color(0xB8FFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    subSecondary: Color(0xB8FFFFFF),
    accent: Color(0xFF2A4360),
  );
}
