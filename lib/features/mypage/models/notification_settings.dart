import 'package:shared_preferences/shared_preferences.dart';

/// 알림 설정 항목.
///
/// 서버에 설정 저장 엔드포인트가 아직 없어(현재 `notifications` 라우트는
/// 목록·읽음 처리만 제공) 로컬에 먼저 저장한다. FCM 키가 도착하고 서버에
/// `GET/PUT /notifications/settings`가 열리면 [toJson]/[fromJson]을 그대로
/// 실어 보내면 되도록 키 이름을 서버 제안 스펙과 맞춰 두었다.
enum NotificationChannel {
  chat('chat', '채팅 메시지', '새 메시지가 도착했을 때'),
  cardExchange('card_exchange', '명함 교환', '내 명함을 저장하거나 교환했을 때'),
  group('group', '그룹 활동', '가입 신청·승인, 공지 등'),
  event('event', '이벤트', '참여 중인 이벤트의 변경·리마인더'),
  schedule('schedule', '레슨 일정', '일정 시작 전 알림'),
  point('point', '포인트·구독', '포인트 적립·사용, 구독 상태 변경'),
  marketing('marketing', '혜택·소식', '제휴 혜택과 신규 기능 안내');

  const NotificationChannel(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;
}

class NotificationSettings {
  /// 전체 푸시 수신 여부. false면 개별 채널 설정과 무관하게 보내지 않는다.
  final bool pushEnabled;

  /// 채널별 수신 여부.
  final Map<NotificationChannel, bool> channels;

  const NotificationSettings({
    required this.pushEnabled,
    required this.channels,
  });

  /// 기본값 — 마케팅만 끄고 나머지는 켠 상태.
  factory NotificationSettings.defaults() => NotificationSettings(
        pushEnabled: true,
        channels: {
          for (final c in NotificationChannel.values)
            c: c != NotificationChannel.marketing,
        },
      );

  NotificationSettings copyWith({
    bool? pushEnabled,
    Map<NotificationChannel, bool>? channels,
  }) =>
      NotificationSettings(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        channels: channels ?? this.channels,
      );

  Map<String, dynamic> toJson() => {
        'push_enabled': pushEnabled,
        for (final entry in channels.entries) entry.key.key: entry.value,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final defaults = NotificationSettings.defaults();
    return NotificationSettings(
      pushEnabled: json['push_enabled'] as bool? ?? defaults.pushEnabled,
      channels: {
        for (final c in NotificationChannel.values)
          c: json[c.key] as bool? ?? defaults.channels[c]!,
      },
    );
  }

  // ── 로컬 저장 ───────────────────────────────────────────
  static const String _prefix = 'notify_';
  static const String _pushKey = '${_prefix}push_enabled';

  static Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = NotificationSettings.defaults();
    return NotificationSettings(
      pushEnabled: prefs.getBool(_pushKey) ?? defaults.pushEnabled,
      channels: {
        for (final c in NotificationChannel.values)
          c: prefs.getBool('$_prefix${c.key}') ?? defaults.channels[c]!,
      },
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, pushEnabled);
    for (final entry in channels.entries) {
      await prefs.setBool('$_prefix${entry.key.key}', entry.value);
    }
  }
}
