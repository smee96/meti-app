// schedule_model.dart — 레슨 일정 + 출석 모델
// API: GET/POST /schedules, GET /schedules/:id
//      GET/PUT /schedules/:id/attendances
// v3.0 신규

// ── 출석 기록 ─────────────────────────────────────────────────────
// lesson_attendances 테이블 1행에 대응
class AttendanceRecord {
  final int studentId;
  final String studentName;
  final String? avatarUrl;
  final String status;     // 'present' | 'absent' | 'late' | 'excused'
  final String? note;
  final String? recordedAt;

  const AttendanceRecord({
    required this.studentId,
    required this.studentName,
    this.avatarUrl,
    required this.status,
    this.note,
    this.recordedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) =>
      AttendanceRecord(
        studentId:   j['student_id']   as int?    ?? 0,
        studentName: j['student_name'] as String? ?? '(알 수 없음)',
        avatarUrl:   j['avatar_url']   as String?,
        status:      j['status']       as String? ?? 'absent',
        note:        j['note']         as String?,
        recordedAt:  j['recorded_at']  as String?,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'status':     status,
        if (note != null) 'note': note,
      };

  // ── 편의 getter ─────────────────────────────────────────────────
  bool get isPresent  => status == 'present';
  bool get isAbsent   => status == 'absent';
  bool get isLate     => status == 'late';
  bool get isExcused  => status == 'excused';
  bool get isAttended => isPresent || isLate;

  String get statusLabel {
    switch (status) {
      case 'present': return '출석';
      case 'absent':  return '결석';
      case 'late':    return '지각';
      case 'excused': return '공결';
      default:        return status;
    }
  }

  AttendanceRecord copyWith({String? status, String? note}) =>
      AttendanceRecord(
        studentId:   studentId,
        studentName: studentName,
        avatarUrl:   avatarUrl,
        status:      status ?? this.status,
        note:        note   ?? this.note,
        recordedAt:  recordedAt,
      );
}

// ── 레슨 일정 ─────────────────────────────────────────────────────
// lesson_schedules 테이블 1행에 대응
class LessonSchedule {
  final int id;
  final int groupId;
  final int? instructorId;
  final String instructorName;
  final String title;
  final String? description;
  final String scheduledAt;      // ISO8601
  final int durationMinutes;
  final String? location;
  final int capacity;
  final String status;           // 'scheduled' | 'completed' | 'cancelled'
  final int attendanceCount;
  final String? createdAt;

  const LessonSchedule({
    required this.id,
    required this.groupId,
    this.instructorId,
    required this.instructorName,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.durationMinutes,
    this.location,
    required this.capacity,
    required this.status,
    required this.attendanceCount,
    this.createdAt,
  });

  factory LessonSchedule.fromJson(Map<String, dynamic> j) => LessonSchedule(
        id:               j['id']               as int?    ?? 0,
        groupId:          j['group_id']          as int?    ?? 0,
        instructorId:     j['instructor_id']     as int?,
        instructorName:   j['instructor_name']   as String? ?? '미지정',
        title:            j['title']             as String? ?? '',
        description:      j['description']       as String?,
        scheduledAt:      j['scheduled_at']      as String? ?? '',
        durationMinutes:  j['duration_minutes']  as int?    ?? 60,
        location:         j['location']          as String?,
        capacity:         j['capacity']          as int?    ?? 0,
        status:           j['status']            as String? ?? 'scheduled',
        attendanceCount:  j['attendance_count']  as int?    ?? 0,
        createdAt:        j['created_at']        as String?,
      );

  // ── 편의 getter ─────────────────────────────────────────────────
  bool get isScheduled  => status == 'scheduled';
  bool get isCompleted  => status == 'completed';
  bool get isCancelled  => status == 'cancelled';

  String get statusLabel {
    switch (status) {
      case 'scheduled':  return '예정';
      case 'completed':  return '완료';
      case 'cancelled':  return '취소됨';
      default:           return status;
    }
  }

  /// scheduledAt을 DateTime으로 파싱 (실패 시 null)
  DateTime? get scheduledDateTime =>
      DateTime.tryParse(scheduledAt)?.toLocal();

  /// 종료 예정 시각
  DateTime? get endDateTime =>
      scheduledDateTime?.add(Duration(minutes: durationMinutes));
}
