// mock_schedules.dart — 레슨 일정 + 출석 관련 Mock API
// 포함: getSchedules, getScheduleDetail, createSchedule,
//        getAttendances, recordAttendances
// v3.0 신규: Lesson Schedule/Attendance API 5개 엔드포인트 완전 구현
//
// 엔드포인트 매핑:
//   GET  /schedules?group_id=:gid      → getSchedules(token, groupId, {status})
//   GET  /schedules/:id                → getScheduleDetail(token, scheduleId)
//   POST /schedules                    → createSchedule(token, body)
//   GET  /schedules/:id/attendances    → getAttendances(token, scheduleId)
//   PUT  /schedules/:id/attendances    → recordAttendances(token, scheduleId, body)
//
// MockStore 상태:
//   MockStore.lessonSchedules    — lesson_schedules 테이블 Mock (groupId → List)
//   MockStore.lessonAttendances  — lesson_attendances 테이블 Mock (scheduleId → List)
//   MockStore.scheduleIdSeq      — 자동 증가 ID

import 'mock_data.dart';

class MockSchedules {
  MockSchedules._(); // 인스턴스화 금지

  // ── 일정 목록 조회 — GET /schedules?group_id=:gid ─────────────
  // 쿼리 파라미터:
  //   group_id (필수): 조회할 그룹 ID
  //   status   (선택): 'scheduled' | 'completed' | 'cancelled' 필터
  // 반환: scheduled_at 오름차순 정렬
  static Map<String, dynamic> getSchedules(
      String accessToken, int groupId, {String? status}) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final list = List<Map<String, dynamic>>.from(
        MockStore.lessonSchedules[groupId] ?? []);

    final filtered = status != null
        ? list.where((s) => s['status'] == status).toList()
        : list;

    // scheduled_at 오름차순 정렬
    filtered.sort((a, b) {
      final aTime = DateTime.tryParse(a['scheduled_at'] as String? ?? '');
      final bTime = DateTime.tryParse(b['scheduled_at'] as String? ?? '');
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });

    return {
      'success': true,
      'data': filtered,
      'pagination': {
        'page': 1, 'limit': 20,
        'total': filtered.length, 'total_pages': 1, 'has_next': false,
      },
    };
  }

  // ── 일정 상세 조회 — GET /schedules/:id ───────────────────────
  // 모든 그룹의 schedules를 탐색하여 id 일치 항목 반환
  static Map<String, dynamic> getScheduleDetail(
      String accessToken, int scheduleId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    for (final list in MockStore.lessonSchedules.values) {
      final idx = list.indexWhere((s) => s['id'] == scheduleId);
      if (idx != -1) {
        return {
          'success': true,
          'data': Map<String, dynamic>.from(list[idx]),
        };
      }
    }
    throw MockApiException('일정을 찾을 수 없습니다.', 404);
  }

  // ── 일정 생성 — POST /schedules ───────────────────────────────
  // body 필수 필드:
  //   group_id        (int)    : 그룹 ID
  //   title           (String) : 일정 제목
  //   scheduled_at    (String) : ISO8601 시작 시각
  //   duration_minutes(int)    : 소요 시간 (분)
  // body 선택 필드:
  //   description     (String?)
  //   location        (String?)
  //   capacity        (int)    기본값 10
  //   instructor_id   (int?)
  //   instructor_name (String?)
  static Map<String, dynamic> createSchedule(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);

    // 필수 필드 검증
    final groupId     = body['group_id']     as int?;
    final title       = (body['title']       as String?)?.trim() ?? '';
    final scheduledAt = (body['scheduled_at'] as String?)?.trim() ?? '';

    if (groupId == null) {
      throw MockApiException('group_id는 필수입니다.', 422);
    }
    if (title.isEmpty) {
      throw MockApiException('일정 제목을 입력해주세요.', 422);
    }
    if (scheduledAt.isEmpty || DateTime.tryParse(scheduledAt) == null) {
      throw MockApiException('올바른 scheduled_at 형식을 입력해주세요. (ISO8601)', 422);
    }

    final newId = MockStore.scheduleIdSeq++;
    final now   = DateTime.now().toUtc().toIso8601String();

    final newSchedule = <String, dynamic>{
      'id':               newId,
      'group_id':         groupId,
      'instructor_id':    body['instructor_id'] ?? user['id'],
      'instructor_name':  body['instructor_name'] ?? user['name'] ?? '강사',
      'title':            title,
      'description':      body['description'],
      'scheduled_at':     scheduledAt,
      'duration_minutes': body['duration_minutes'] ?? 60,
      'location':         body['location'],
      'capacity':         body['capacity']  ?? 10,
      'status':           'scheduled',
      'attendance_count': 0,
      'created_at':       now,
    };

    MockStore.lessonSchedules.putIfAbsent(groupId, () => []).add(newSchedule);

    return {
      'success': true,
      'data': newSchedule,
      'message': '레슨 일정이 등록되었습니다.',
    };
  }

  // ── 출석 목록 조회 — GET /schedules/:id/attendances ──────────
  // scheduleId 에 해당하는 출석 기록 전체 반환
  // 출석 기록이 없으면 빈 배열 반환 (404 아님)
  static Map<String, dynamic> getAttendances(
      String accessToken, int scheduleId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    // 일정 존재 여부 확인
    bool found = false;
    for (final list in MockStore.lessonSchedules.values) {
      if (list.any((s) => s['id'] == scheduleId)) { found = true; break; }
    }
    if (!found) throw MockApiException('일정을 찾을 수 없습니다.', 404);

    final records = List<Map<String, dynamic>>.from(
        MockStore.lessonAttendances[scheduleId] ?? []);

    return {
      'success': true,
      'data': records,
      'pagination': {
        'page': 1, 'limit': 100,
        'total': records.length, 'total_pages': 1, 'has_next': false,
      },
    };
  }

  // ── 출석 일괄 기록/수정 — PUT /schedules/:id/attendances ──────
  // body: { attendances: [ { student_id, status, note? }, ... ] }
  // status: 'present' | 'absent' | 'late' | 'excused'
  // 동작:
  //   - 기존 scheduleId 출석 전체 교체(upsert 아닌 replace)
  //   - 일정 status → 'completed' 로 변경
  //   - attendance_count 갱신 (present + late 합산)
  // 권한: instructor 또는 admin (Mock에서는 로그인 사용자 누구나)
  static Map<String, dynamic> recordAttendances(
      String accessToken, int scheduleId, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    // 일정 존재 여부 확인 + 참조 획득
    Map<String, dynamic>? targetSchedule;
    for (final list in MockStore.lessonSchedules.values) {
      final idx = list.indexWhere((s) => s['id'] == scheduleId);
      if (idx != -1) { targetSchedule = list[idx]; break; }
    }
    if (targetSchedule == null) {
      throw MockApiException('일정을 찾을 수 없습니다.', 404);
    }
    if (targetSchedule['status'] == 'cancelled') {
      throw MockApiException('취소된 일정의 출석은 기록할 수 없습니다.', 422,
          errorCode: 'schedule_cancelled');
    }

    // body 파싱
    final rawList = body['attendances'];
    if (rawList == null || rawList is! List) {
      throw MockApiException('attendances 배열이 필요합니다.', 422);
    }

    final validStatuses = {'present', 'absent', 'late', 'excused'};
    final now           = DateTime.now().toUtc().toIso8601String();
    final newRecords    = <Map<String, dynamic>>[];

    for (final item in rawList) {
      if (item is! Map) continue;
      final studentId = item['student_id'] as int?;
      final status    = item['status']     as String?;

      if (studentId == null) {
        throw MockApiException('student_id는 필수입니다.', 422);
      }
      if (status == null || !validStatuses.contains(status)) {
        throw MockApiException(
            'status는 present | absent | late | excused 중 하나여야 합니다.', 422);
      }

      // 학생 이름 조회 (없으면 기본값)
      final studentUser = MockStore.users.cast<Map<String, dynamic>?>().firstWhere(
        (u) => u!['id'] == studentId,
        orElse: () => null,
      );

      newRecords.add({
        'student_id':   studentId,
        'student_name': studentUser?['name'] ?? '(알 수 없음)',
        'avatar_url':   studentUser?['avatar_url'],
        'status':       status,
        'note':         item['note'],
        'recorded_at':  now,
      });
    }

    // 기존 출석 기록 전체 교체
    MockStore.lessonAttendances[scheduleId] = newRecords;

    // 출석 카운트 갱신 (present + late)
    final attendedCount =
        newRecords.where((r) => r['status'] == 'present' || r['status'] == 'late').length;
    targetSchedule['attendance_count'] = attendedCount;

    // 일정 상태 → completed
    targetSchedule['status'] = 'completed';

    return {
      'success': true,
      'data': {
        'schedule_id':      scheduleId,
        'total':            newRecords.length,
        'attended':         attendedCount,
        'absent':           newRecords.where((r) => r['status'] == 'absent').length,
        'late':             newRecords.where((r) => r['status'] == 'late').length,
        'excused':          newRecords.where((r) => r['status'] == 'excused').length,
        'schedule_status':  'completed',
      },
      'message': '출석이 기록되었습니다.',
    };
  }
}
