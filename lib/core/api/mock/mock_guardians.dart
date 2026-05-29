// mock_guardians.dart — 보호자 연결 관련 Mock API
// 포함: getMyGuardians, getMyStudents, invite, accept, reject, cancel, remove
// v3.0 신규: Guardian API 7개 엔드포인트 완전 구현
//
// 엔드포인트 매핑:
//   GET    /guardians/my-guardians   → getMyGuardians(token)
//   GET    /guardians/my-students    → getMyStudents(token)
//   POST   /guardians/invite         → invite(token, body)
//   PUT    /guardians/:id/accept     → accept(token, linkId)
//   PUT    /guardians/:id/reject     → reject(token, linkId)
//   DELETE /guardians/:id/cancel     → cancel(token, linkId)
//   DELETE /guardians/:id            → remove(token, linkId)
//
// MockStore 상태:
//   MockStore.guardianLinks     — user_guardians 테이블 Mock
//   MockStore.guardianLinkIdSeq — 자동 증가 ID

import 'mock_data.dart';

class MockGuardians {
  MockGuardians._(); // 인스턴스화 금지

  // ── 내 보호자 목록 — GET /guardians/my-guardians ──────────────
  // 현재 로그인 유저를 학생(user_id)으로 삼는 링크만 반환
  // status 무관 전체 반환 (pending 포함)
  static Map<String, dynamic> getMyGuardians(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final links = MockStore.guardianLinks
        .where((l) => l['user_id'] == userId)
        .toList();

    final data = links.map((l) {
      // 보호자 사용자 정보 조회 (없을 수 있음 — 초대 수락 전 외부 이메일)
      final guardianUser = MockStore.users.cast<Map<String, dynamic>?>().firstWhere(
        (u) => u!['id'] == l['guardian_user_id'],
        orElse: () => null,
      );

      return {
        'id':                 l['id'],
        'relation':           l['relation'],
        'status':             l['status'],
        'invited_at':         l['invited_at'],
        'accepted_at':        l['accepted_at'],
        'guardian': guardianUser == null
            ? null
            : {
                'id':         guardianUser['id'],
                'name':       guardianUser['name'],
                'email':      guardianUser['email'],
                'avatar_url': guardianUser['avatar_url'],
              },
      };
    }).toList();

    return {
      'success': true,
      'data': data,
      'pagination': {
        'page': 1, 'limit': 20,
        'total': data.length, 'total_pages': 1, 'has_next': false,
      },
    };
  }

  // ── 내 학생 목록 — GET /guardians/my-students ─────────────────
  // 현재 로그인 유저를 보호자(guardian_user_id)로 삼는 링크만 반환
  // status = 'accepted' 인 건만 반환
  static Map<String, dynamic> getMyStudents(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user              = MockStore.users.firstWhere((u) => u['email'] == email);
    final guardianUserId    = user['id'] as int;

    final links = MockStore.guardianLinks
        .where((l) =>
            l['guardian_user_id'] == guardianUserId &&
            l['status'] == 'accepted')
        .toList();

    final data = links.map((l) {
      final studentUser = MockStore.users.cast<Map<String, dynamic>?>().firstWhere(
        (u) => u!['id'] == l['user_id'],
        orElse: () => null,
      );

      return {
        'id':          l['id'],
        'relation':    l['relation'],
        'status':      l['status'],
        'accepted_at': l['accepted_at'],
        'student': studentUser == null
            ? null
            : {
                'id':         studentUser['id'],
                'name':       studentUser['name'],
                'email':      studentUser['email'],
                'avatar_url': studentUser['avatar_url'],
              },
      };
    }).toList();

    return {
      'success': true,
      'data': data,
      'pagination': {
        'page': 1, 'limit': 20,
        'total': data.length, 'total_pages': 1, 'has_next': false,
      },
    };
  }

  // ── 보호자 초대 — POST /guardians/invite ─────────────────────
  // body: { guardian_email: String, relation: String }
  // 동작:
  //   1. guardian_email 로 기존 유저 검색
  //   2. 이미 연결(pending 포함)된 경우 409
  //   3. 신규 링크 생성 (status: pending)
  static Map<String, dynamic> invite(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final guardianEmail = (body['guardian_email'] as String?)?.trim() ?? '';
    final relation      = (body['relation']       as String?)?.trim() ?? 'parent';

    if (guardianEmail.isEmpty) {
      throw MockApiException('보호자 이메일을 입력해주세요.', 422);
    }
    if (guardianEmail == email) {
      throw MockApiException('자기 자신을 보호자로 등록할 수 없습니다.', 422);
    }

    // 초대 대상 유저 조회 (Mock 유저 DB에서 검색)
    final guardianUser = MockStore.users.cast<Map<String, dynamic>?>().firstWhere(
      (u) => u!['email'] == guardianEmail,
      orElse: () => null,
    );
    final guardianUserId = guardianUser?['id'] as int? ?? -1;

    // 중복 체크: 동일 (user_id, guardian_user_id) 쌍이 이미 pending/accepted 상태
    final alreadyExists = MockStore.guardianLinks.any((l) =>
        l['user_id'] == userId &&
        l['guardian_user_id'] == guardianUserId &&
        (l['status'] == 'pending' || l['status'] == 'accepted'));

    if (alreadyExists) {
      throw MockApiException('이미 초대하거나 연결된 보호자입니다.', 409);
    }

    final newId  = MockStore.guardianLinkIdSeq++;
    final now    = DateTime.now().toUtc().toIso8601String();

    final newLink = <String, dynamic>{
      'id':                newId,
      'user_id':           userId,
      'guardian_user_id':  guardianUserId,   // 미가입자는 -1
      'relation':          relation,
      'status':            'pending',
      'invited_at':        now,
      'accepted_at':       null,
    };
    MockStore.guardianLinks.add(newLink);

    return {
      'success': true,
      'data': {
        'id':             newId,
        'guardian_email': guardianEmail,
        'relation':       relation,
        'status':         'pending',
        'invited_at':     now,
      },
      'message': '보호자 초대를 보냈습니다.',
    };
  }

  // ── 초대 수락 — PUT /guardians/:id/accept ────────────────────
  // 현재 로그인 유저가 guardian_user_id 인 링크를 accepted 로 변경
  // 본인 확인: guardian_user_id == 현재 유저 id
  static Map<String, dynamic> accept(String accessToken, int linkId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final link = MockStore.guardianLinks.cast<Map<String, dynamic>?>().firstWhere(
      (l) => l!['id'] == linkId,
      orElse: () => null,
    );
    if (link == null) throw MockApiException('초대를 찾을 수 없습니다.', 404);
    if (link['guardian_user_id'] != userId) {
      throw MockApiException('권한이 없습니다.', 403);
    }
    if (link['status'] != 'pending') {
      throw MockApiException('수락할 수 없는 상태입니다.', 409,
          errorCode: 'invalid_status');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    link['status']      = 'accepted';
    link['accepted_at'] = now;

    return {
      'success': true,
      'data': {
        'id':          linkId,
        'status':      'accepted',
        'accepted_at': now,
      },
      'message': '보호자 초대를 수락했습니다.',
    };
  }

  // ── 초대 거절 — PUT /guardians/:id/reject ────────────────────
  // 현재 로그인 유저가 guardian_user_id 인 pending 링크를 rejected 로 변경
  static Map<String, dynamic> reject(String accessToken, int linkId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final link = MockStore.guardianLinks.cast<Map<String, dynamic>?>().firstWhere(
      (l) => l!['id'] == linkId,
      orElse: () => null,
    );
    if (link == null) throw MockApiException('초대를 찾을 수 없습니다.', 404);
    if (link['guardian_user_id'] != userId) {
      throw MockApiException('권한이 없습니다.', 403);
    }
    if (link['status'] != 'pending') {
      throw MockApiException('거절할 수 없는 상태입니다.', 409,
          errorCode: 'invalid_status');
    }

    link['status'] = 'rejected';

    return {
      'success': true,
      'data': null,
      'message': '보호자 초대를 거절했습니다.',
    };
  }

  // ── 초대 취소 — DELETE /guardians/:id/cancel ─────────────────
  // 초대를 보낸 학생(user_id)이 pending 상태의 초대를 취소
  static Map<String, dynamic> cancel(String accessToken, int linkId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final index = MockStore.guardianLinks.indexWhere(
      (l) => l['id'] == linkId,
    );
    if (index == -1) throw MockApiException('초대를 찾을 수 없습니다.', 404);

    final link = MockStore.guardianLinks[index];
    if (link['user_id'] != userId) {
      throw MockApiException('권한이 없습니다.', 403);
    }
    if (link['status'] != 'pending') {
      throw MockApiException('취소할 수 없는 상태입니다. (이미 수락/거절됨)', 409,
          errorCode: 'invalid_status');
    }

    MockStore.guardianLinks.removeAt(index);

    return {
      'success': true,
      'data': null,
      'message': '보호자 초대를 취소했습니다.',
    };
  }

  // ── 연결 삭제 — DELETE /guardians/:id ────────────────────────
  // accepted 상태의 링크를 완전 삭제
  // 학생(user_id) 또는 보호자(guardian_user_id) 양쪽 모두 삭제 가능
  static Map<String, dynamic> remove(String accessToken, int linkId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final index = MockStore.guardianLinks.indexWhere(
      (l) => l['id'] == linkId,
    );
    if (index == -1) throw MockApiException('연결 정보를 찾을 수 없습니다.', 404);

    final link = MockStore.guardianLinks[index];

    // 요청자가 학생 또는 보호자여야 함
    final isStudent  = link['user_id']          == userId;
    final isGuardian = link['guardian_user_id'] == userId;
    if (!isStudent && !isGuardian) {
      throw MockApiException('권한이 없습니다.', 403);
    }
    if (link['status'] != 'accepted') {
      throw MockApiException('수락된 연결만 삭제할 수 있습니다. 취소는 /cancel을 이용하세요.', 409,
          errorCode: 'invalid_status');
    }

    MockStore.guardianLinks.removeAt(index);

    return {
      'success': true,
      'data': null,
      'message': '보호자 연결이 해제되었습니다.',
    };
  }
}
