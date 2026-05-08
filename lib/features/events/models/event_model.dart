/// 이벤트 모델 (v2.6)
/// API: GET /events/groups/:gid/events
class Event {
  final int id;
  final int groupId;
  final String title;
  final String? description;
  final String? location;
  final String startsAt;
  final String? endsAt;
  final String status;          // upcoming | ongoing | ended | cancelled
  final String visibility;      // public | private
  final String registrationType; // free | pre_required | paid
  final int? capacity;          // null = 무제한
  final int participantCount;
  final bool isJoined;
  final int? entryFee;          // P 단위, 0 = 무료
  final String? groupName;
  final String? organizerName;

  const Event({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    this.location,
    required this.startsAt,
    this.endsAt,
    required this.status,
    this.visibility = 'public',
    this.registrationType = 'free',
    this.capacity,
    this.participantCount = 0,
    this.isJoined = false,
    this.entryFee,
    this.groupName,
    this.organizerName,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as int,
        groupId: json['group_id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        location: json['location'] as String?,
        startsAt: json['starts_at'] as String? ?? '',
        endsAt: json['ends_at'] as String?,
        status: json['status'] as String? ?? 'upcoming',
        visibility: json['visibility'] as String? ?? 'public',
        registrationType:
            json['registration_type'] as String? ?? 'free',
        capacity: json['capacity'] as int?,
        participantCount: json['participant_count'] as int? ?? 0,
        isJoined: json['is_joined'] == true || json['is_joined'] == 1,
        entryFee: json['entry_fee'] as int?,
        groupName: json['group_name'] as String?,
        organizerName: json['organizer_name'] as String?,
      );

  // ── 상태 표시 레이블 ──────────────────────────────────
  String get statusLabel {
    switch (status) {
      case 'upcoming':  return '예정';
      case 'ongoing':   return '진행중';
      case 'ended':     return '종료';
      case 'cancelled': return '취소됨';
      default:          return status;
    }
  }

  bool get isUpcoming  => status == 'upcoming';
  bool get isOngoing   => status == 'ongoing';
  bool get isEnded     => status == 'ended';
  bool get isCancelled => status == 'cancelled';
  bool get isActive    => isUpcoming || isOngoing;

  /// 정원 가득 여부 (capacity == null 이면 무제한)
  bool get isFull =>
      capacity != null && participantCount >= capacity!;

  /// 남은 자리 (무제한이면 null)
  int? get remaining =>
      capacity == null ? null : (capacity! - participantCount).clamp(0, capacity!);

  /// 이벤트 개설 비용 (v2.6: 정원 기반)
  /// ≤30명 → 1,000P / 31-100명 → 3,000P / >100명 → 5,000P
  static int creationCost(int cap) {
    if (cap <= 30)  return 1000;
    if (cap <= 100) return 3000;
    return 5000;
  }

  Event copyWith({bool? isJoined, int? participantCount, String? status}) =>
      Event(
        id: id,
        groupId: groupId,
        title: title,
        description: description,
        location: location,
        startsAt: startsAt,
        endsAt: endsAt,
        status: status ?? this.status,
        visibility: visibility,
        registrationType: registrationType,
        capacity: capacity,
        participantCount: participantCount ?? this.participantCount,
        isJoined: isJoined ?? this.isJoined,
        entryFee: entryFee,
        groupName: groupName,
        organizerName: organizerName,
      );
}
