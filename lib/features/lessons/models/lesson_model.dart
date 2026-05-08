// v2.6: 레슨 모델
// API: GET/POST /api/v1/lessons/groups/:groupId/lessons

class Lesson {
  final int id;
  final int groupId;
  final int? instructorId;
  final String instructorName;
  final String title;
  final String? description;
  final String scheduleType; // 'one-time' | 'recurring'
  final String scheduledAt;
  final int durationMinutes;
  final int capacity;
  final int registeredCount;
  final String? location;
  final int pointCost;       // 레슨 개설 시 그룹 포인트 차감액 (기본 500P)
  final String status;       // 'upcoming' | 'ongoing' | 'ended' | 'cancelled'
  final bool isRegistered;   // 현재 사용자 수강 신청 여부
  final String? createdAt;

  const Lesson({
    required this.id,
    required this.groupId,
    this.instructorId,
    required this.instructorName,
    required this.title,
    this.description,
    required this.scheduleType,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.capacity,
    required this.registeredCount,
    this.location,
    required this.pointCost,
    required this.status,
    required this.isRegistered,
    this.createdAt,
  });

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as int? ?? 0,
        groupId: j['group_id'] as int? ?? 0,
        instructorId: j['instructor_id'] as int?,
        instructorName: j['instructor_name'] as String? ?? '미지정',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        scheduleType: j['schedule_type'] as String? ?? 'one-time',
        scheduledAt: j['scheduled_at'] as String? ?? '',
        durationMinutes: j['duration_minutes'] as int? ?? 60,
        capacity: j['capacity'] as int? ?? 0,
        registeredCount: j['registered_count'] as int? ?? 0,
        location: j['location'] as String?,
        pointCost: j['point_cost'] as int? ?? 500,
        status: j['status'] as String? ?? 'upcoming',
        isRegistered: j['is_registered'] as bool? ?? false,
        createdAt: j['created_at'] as String?,
      );

  // 상태 레이블
  String get statusLabel {
    switch (status) {
      case 'upcoming':   return '예정';
      case 'ongoing':    return '진행중';
      case 'ended':      return '종료';
      case 'cancelled':  return '취소됨';
      default:           return status;
    }
  }

  bool get isUpcoming   => status == 'upcoming';
  bool get isCancelled  => status == 'cancelled';
  bool get isFull       => registeredCount >= capacity;

  // 남은 자리
  int get remaining => (capacity - registeredCount).clamp(0, capacity);
}
