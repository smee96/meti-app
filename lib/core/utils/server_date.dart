/// 서버 날짜 문자열 파싱 유틸
///
/// staging 서버는 타임존 표기가 섞여 내려온다:
/// - `"2026-07-18 10:36:47"` (D1 기본 — 타임존 없음, 실제로는 UTC)
/// - `"2026-07-19T00:00:00.000Z"` (ISO 8601 UTC)
/// Dart의 DateTime.parse는 타임존이 없으면 로컬로 해석하므로
/// 그대로 쓰면 KST 기준 9시간 어긋난다 → 타임존 없는 값은 UTC로 간주한다.
DateTime? tryParseServerDate(String? value) {
  if (value == null || value.isEmpty) return null;
  var s = value.trim().replaceFirst(' ', 'T');
  final hasTimezone =
      s.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
  if (!hasTimezone) s = '${s}Z';
  return DateTime.tryParse(s)?.toLocal();
}
