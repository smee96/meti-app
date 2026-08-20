/// 파트너 제휴 서비스 모델 (서버 회신 v0.2, 2026-08-08)
/// GET /partner/services 응답 항목.
class PartnerService {
  final int id;
  final String name;
  final String? description;
  final String? webviewUrl;

  /// 'webview' = 인앱 웹뷰 / 'external' = 외부 브라우저
  /// (심사 이슈 시 서버 설정만으로 전환 가능 — 통합 가이드 §0)
  final String openMode;

  const PartnerService({
    required this.id,
    required this.name,
    this.description,
    this.webviewUrl,
    required this.openMode,
  });

  factory PartnerService.fromJson(Map<String, dynamic> json) {
    return PartnerService(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      webviewUrl: json['webview_url'] as String?,
      openMode: (json['open_mode'] ?? 'webview') as String,
    );
  }

  bool get isExternal => openMode == 'external';
}

/// POST /partner/services/:id/launch-token 응답.
/// 서버가 토큰을 붙인 진입 URL(launch_url)까지 만들어준다 — 앱은 그대로 연다.
class PartnerLaunchTicket {
  final String token;

  /// 초 단위 TTL (스펙 확정값 300초 = 5분)
  final int expiresIn;
  final String openMode;
  final String? launchUrl;

  const PartnerLaunchTicket({
    required this.token,
    required this.expiresIn,
    required this.openMode,
    this.launchUrl,
  });

  factory PartnerLaunchTicket.fromJson(Map<String, dynamic> json) {
    return PartnerLaunchTicket(
      token: (json['token'] ?? '') as String,
      expiresIn: (json['expires_in'] ?? 300) as int,
      openMode: (json['open_mode'] ?? 'webview') as String,
      launchUrl: json['launch_url'] as String?,
    );
  }
}

/// B-2 게임재화 잔액 (해피트리 → ELID 표시용, 확정 회신 v0.1 §2).
/// 필드명은 해피트리 확정 스펙 {stars, hearts, hearts_max, coins, level}.
class PartnerBalance {
  final int stars;
  final int hearts;
  final int heartsMax;
  final int coins;
  final int? level;

  const PartnerBalance({
    required this.stars,
    required this.hearts,
    required this.heartsMax,
    required this.coins,
    this.level,
  });

  factory PartnerBalance.fromJson(Map<String, dynamic> json) {
    return PartnerBalance(
      stars: (json['stars'] ?? 0) as int,
      hearts: (json['hearts'] ?? 0) as int,
      heartsMax: (json['hearts_max'] ?? 0) as int,
      coins: (json['coins'] ?? 0) as int,
      level: json['level'] as int?,
    );
  }
}

/// B-2 잔액 조회 상태 — 화면이 안내 문구를 고르는 기준.
enum PartnerBalanceStatus {
  /// 조회 대상 파트너가 목록에 없다 (잔액 바를 보이지 않음)
  idle,
  loading,
  ok,

  /// 아직 게임에 진입한 적이 없어 파트너 쪽에 플레이어가 없다 (404)
  notLinked,

  /// 서버가 파트너 잔액 조회를 아직 설정하지 못했다 — prod 키 대기 (503)
  unavailable,

  /// 일시적 실패 (네트워크·파트너 장애)
  error,
}
