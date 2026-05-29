// guardian_model.dart — 보호자 연결 모델
// API: GET /guardians/my-guardians, GET /guardians/my-students
// v3.0 신규

// ── 유저 요약 (보호자 또는 학생) ──────────────────────────────────
class GuardianUserSummary {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;

  const GuardianUserSummary({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory GuardianUserSummary.fromJson(Map<String, dynamic> j) =>
      GuardianUserSummary(
        id:        j['id']         as int?    ?? 0,
        name:      j['name']       as String? ?? '(알 수 없음)',
        email:     j['email']      as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
      );
}

// ── 보호자 연결 링크 ──────────────────────────────────────────────
// user_guardians 테이블 1행에 대응
class GuardianLink {
  final int id;
  final String relation;   // 'parent' | 'guardian' | 'other'
  final String status;     // 'pending' | 'accepted' | 'rejected'
  final String invitedAt;
  final String? acceptedAt;

  /// getMyGuardians() 응답 시 존재 — 보호자 정보
  final GuardianUserSummary? guardian;

  /// getMyStudents() 응답 시 존재 — 학생 정보
  final GuardianUserSummary? student;

  const GuardianLink({
    required this.id,
    required this.relation,
    required this.status,
    required this.invitedAt,
    this.acceptedAt,
    this.guardian,
    this.student,
  });

  factory GuardianLink.fromJson(Map<String, dynamic> j) {
    final guardianJson = j['guardian'] as Map<String, dynamic>?;
    final studentJson  = j['student']  as Map<String, dynamic>?;
    return GuardianLink(
      id:          j['id']          as int?    ?? 0,
      relation:    j['relation']    as String? ?? 'parent',
      status:      j['status']      as String? ?? 'pending',
      invitedAt:   j['invited_at']  as String? ?? '',
      acceptedAt:  j['accepted_at'] as String?,
      guardian: guardianJson != null
          ? GuardianUserSummary.fromJson(guardianJson)
          : null,
      student: studentJson != null
          ? GuardianUserSummary.fromJson(studentJson)
          : null,
    );
  }

  // ── 편의 getter ─────────────────────────────────────────────────
  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  String get relationLabel {
    switch (relation) {
      case 'parent':   return '부모';
      case 'guardian': return '보호자';
      case 'other':    return '기타';
      default:         return relation;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':  return '수락 대기';
      case 'accepted': return '연결됨';
      case 'rejected': return '거절됨';
      default:         return status;
    }
  }
}
