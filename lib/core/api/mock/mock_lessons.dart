// mock_lessons.dart — 레슨 + 그룹 행사(이벤트) Mock API
// 포함:
//   레슨: getLessons, createLesson, registerLesson,
//         cancelLessonRegistration, cancelLesson
//   행사: getGroupEvents, createGroupEvent, joinGroupEvent,
//         leaveGroupEvent, cancelGroupEvent

import 'mock_data.dart';

class MockLessons {
  MockLessons._();

  // ── 레슨 목록 조회 — GET /groups/:id/lessons ─────────────────
  static Map<String, dynamic> getLessons(int groupId, {String? status}) {
    final list = List<Map<String, dynamic>>.from(
        MockStore.lessons[groupId] ?? []);
    final filtered = status != null
        ? list.where((l) => l['status'] == status).toList()
        : list;
    return {
      'success': true,
      'data': filtered,
      'pagination': {
        'page': 1, 'limit': 20,
        'total': filtered.length, 'has_next': false,
      },
    };
  }

  // ── 레슨 생성 — POST /groups/:id/lessons ─────────────────────
  // admin/sub_admin/instructor 전용, 그룹 포인트 500P 차감
  static Map<String, dynamic> createLesson(
      String accessToken, int groupId, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    const cost    = 500;
    final balance = MockStore.groupPointBalance[groupId] ?? 0;
    if (balance < cost) {
      throw MockApiException(
        '그룹 포인트가 부족합니다.',
        422,
        errorCode: 'insufficient_group_points',
        extra: {'required': cost, 'current': balance, 'shortage': cost - balance},
      );
    }
    MockStore.groupPointBalance[groupId] = balance - cost;

    MockStore.lessonIdSeq++;
    final newLesson = {
      'id':               MockStore.lessonIdSeq,
      'group_id':         groupId,
      'instructor_id':    body['instructor_id'],
      'instructor_name':  body['instructor_name'] ?? '강사',
      'title':            body['title'] ?? '새 레슨',
      'description':      body['description'],
      'schedule_type':    body['schedule_type'] ?? 'one-time',
      'scheduled_at':     body['scheduled_at']  ?? DateTime.now().toIso8601String(),
      'duration_minutes': body['duration_minutes'] ?? 60,
      'capacity':         body['capacity'] ?? 10,
      'registered_count': 0,
      'location':         body['location'],
      'point_cost':       cost,
      'status':           'upcoming',
      'is_registered':    false,
      'created_at':       DateTime.now().toIso8601String(),
    };
    MockStore.lessons.putIfAbsent(groupId, () => []).add(newLesson);

    return {
      'success': true,
      'data': newLesson,
      'message': '레슨이 개설되었습니다. (그룹 포인트 ${cost}P 차감)',
    };
  }

  // ── 레슨 수강 신청 — POST /lessons/:id/register ──────────────
  static Map<String, dynamic> registerLesson(
      String accessToken, int lessonId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    Map<String, dynamic>? lesson;
    for (final list in MockStore.lessons.values) {
      final idx = list.indexWhere((l) => l['id'] == lessonId);
      if (idx != -1) { lesson = list[idx]; break; }
    }
    if (lesson == null) throw MockApiException('레슨을 찾을 수 없습니다.', 404);

    final regs = MockStore.lessonRegistrations.putIfAbsent(lessonId, () => []);
    if (regs.contains(userId)) {
      throw MockApiException('이미 수강 신청한 레슨입니다.', 409);
    }
    final registered = lesson['registered_count'] as int;
    final capacity   = lesson['capacity'] as int;
    if (registered >= capacity) {
      throw MockApiException('수강 정원이 가득 찼습니다.', 409);
    }

    regs.add(userId);
    lesson['registered_count'] = registered + 1;
    lesson['is_registered']    = true;

    return {'success': true, 'data': null, 'message': '수강 신청이 완료되었습니다.'};
  }

  // ── 레슨 수강 취소 — DELETE /lessons/:id/register ────────────
  static Map<String, dynamic> cancelLessonRegistration(
      String accessToken, int lessonId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    Map<String, dynamic>? lesson;
    for (final list in MockStore.lessons.values) {
      final idx = list.indexWhere((l) => l['id'] == lessonId);
      if (idx != -1) { lesson = list[idx]; break; }
    }
    if (lesson == null) throw MockApiException('레슨을 찾을 수 없습니다.', 404);

    final regs = MockStore.lessonRegistrations[lessonId];
    if (regs == null || !regs.contains(userId)) {
      throw MockApiException('수강 신청 내역이 없습니다.', 404);
    }
    regs.remove(userId);
    lesson['registered_count'] =
        ((lesson['registered_count'] as int) - 1).clamp(0, 9999);
    lesson['is_registered'] = false;

    return {'success': true, 'data': null, 'message': '수강 신청이 취소되었습니다.'};
  }

  // ── 레슨 취소 — DELETE /groups/:gid/lessons/:id ──────────────
  // admin/sub_admin 전용
  static Map<String, dynamic> cancelLesson(
      String accessToken, int lessonId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    for (final list in MockStore.lessons.values) {
      final idx = list.indexWhere((l) => l['id'] == lessonId);
      if (idx != -1) {
        list[idx] = Map<String, dynamic>.from(list[idx])
          ..['status'] = 'cancelled';
        return {'success': true, 'data': null, 'message': '레슨이 취소되었습니다.'};
      }
    }
    throw MockApiException('레슨을 찾을 수 없습니다.', 404);
  }

  // ────────────────────────────────────────────────────────────
  // 그룹 행사(이벤트)
  // ────────────────────────────────────────────────────────────

  // ── 행사 목록 조회 — GET /groups/:id/events ──────────────────
  static Map<String, dynamic> getGroupEvents(int groupId, {String? status}) {
    final list = List<Map<String, dynamic>>.from(
        MockStore.groupEvents[groupId] ?? []);
    final filtered = status != null
        ? list.where((e) => e['status'] == status).toList()
        : list;
    return {
      'success': true,
      'data': filtered,
      'pagination': {
        'page': 1, 'limit': 20,
        'total': filtered.length, 'has_next': false,
      },
    };
  }

  // ── 행사 생성 — POST /groups/:id/events ──────────────────────
  // 정원 기반 포인트 차감: ≤30 → 1,000P / 31-100 → 3,000P / >100 → 5,000P
  static Map<String, dynamic> createGroupEvent(
      String accessToken, int groupId, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final cap  = body['capacity'] as int? ?? 30;
    final cost = cap <= 30 ? 1000 : cap <= 100 ? 3000 : 5000;

    final balance = MockStore.groupPointBalance[groupId] ?? 0;
    if (balance < cost) {
      throw MockApiException(
        '그룹 포인트가 부족합니다.',
        422,
        errorCode: 'insufficient_group_points',
        extra: {'required': cost, 'current': balance, 'shortage': cost - balance},
      );
    }
    MockStore.groupPointBalance[groupId] = balance - cost;

    MockStore.eventIdSeq++;
    final newEvent = {
      'id':                MockStore.eventIdSeq,
      'group_id':          groupId,
      'title':             body['title'] ?? '새 이벤트',
      'description':       body['description'],
      'location':          body['location'],
      'starts_at':         body['starts_at'] ?? DateTime.now().toIso8601String(),
      'ends_at':           body['ends_at'],
      'status':            'upcoming',
      'visibility':        body['visibility']        ?? 'public',
      'registration_type': body['registration_type'] ?? 'pre_required',
      'capacity':          cap,
      'participant_count': 0,
      'is_joined':         false,
      'entry_fee':         body['entry_fee'] ?? 0,
      'group_name':        'ELID 개발자 모임',
      'organizer_name':    email,
      'creation_cost':     cost,
      'created_at':        DateTime.now().toIso8601String(),
    };
    MockStore.groupEvents.putIfAbsent(groupId, () => []).add(newEvent);

    return {
      'success': true,
      'data': newEvent,
      'message': '이벤트가 개설되었습니다. (그룹 포인트 ${cost}P 차감)',
    };
  }

  // ── 행사 참가 신청 — POST /events/:id/join ───────────────────
  static Map<String, dynamic> joinGroupEvent(
      String accessToken, int eventId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    Map<String, dynamic>? event;
    for (final list in MockStore.groupEvents.values) {
      final idx = list.indexWhere((e) => e['id'] == eventId);
      if (idx != -1) { event = list[idx]; break; }
    }
    if (event == null) throw MockApiException('이벤트를 찾을 수 없습니다.', 404);
    if (event['status'] != 'upcoming' && event['status'] != 'ongoing') {
      throw MockApiException('참가 신청이 불가한 이벤트입니다.', 422);
    }

    final participants =
        MockStore.eventParticipants.putIfAbsent(eventId, () => []);
    if (participants.contains(userId)) {
      throw MockApiException('이미 참가 신청한 이벤트입니다.', 409);
    }

    final cap   = event['capacity'] as int?;
    final count = event['participant_count'] as int;
    if (cap != null && count >= cap) {
      throw MockApiException('참가 정원이 가득 찼습니다.', 409);
    }

    // 참가비 차감
    final fee = event['entry_fee'] as int? ?? 0;
    if (fee > 0) {
      final balance = (user['point_balance'] as int?) ?? 0;
      if (balance < fee) {
        throw MockApiException(
          '포인트가 부족합니다.',
          422,
          errorCode: 'insufficient_points',
          extra: {'required': fee, 'current': balance, 'short': fee - balance},
        );
      }
      user['point_balance'] = balance - fee;
    }

    participants.add(userId);
    event['participant_count'] = count + 1;
    event['is_joined']         = true;

    return {'success': true, 'data': null, 'message': '이벤트 참가 신청이 완료되었습니다.'};
  }

  // ── 행사 참가 취소 — DELETE /events/:id/join ─────────────────
  static Map<String, dynamic> leaveGroupEvent(
      String accessToken, int eventId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    Map<String, dynamic>? event;
    for (final list in MockStore.groupEvents.values) {
      final idx = list.indexWhere((e) => e['id'] == eventId);
      if (idx != -1) { event = list[idx]; break; }
    }
    if (event == null) throw MockApiException('이벤트를 찾을 수 없습니다.', 404);

    final participants = MockStore.eventParticipants[eventId];
    if (participants == null || !participants.contains(userId)) {
      throw MockApiException('참가 신청 내역이 없습니다.', 404);
    }
    participants.remove(userId);
    final count = event['participant_count'] as int;
    event['participant_count'] = (count - 1).clamp(0, 99999);
    event['is_joined']         = false;

    return {'success': true, 'data': null, 'message': '이벤트 참가 신청이 취소되었습니다.'};
  }

  // ── 행사 취소 — DELETE /events/groups/:gid/events/:id ────────
  // admin/sub_admin 전용
  static Map<String, dynamic> cancelGroupEvent(
      String accessToken, int eventId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    for (final list in MockStore.groupEvents.values) {
      final idx = list.indexWhere((e) => e['id'] == eventId);
      if (idx != -1) {
        list[idx] = Map<String, dynamic>.from(list[idx])
          ..['status'] = 'cancelled';
        return {'success': true, 'data': null, 'message': '이벤트가 취소되었습니다.'};
      }
    }
    throw MockApiException('이벤트를 찾을 수 없습니다.', 404);
  }
}
