// mock_groups.dart — 그룹 관련 Mock API
// 포함: getMyGroupsMine, joinGroup, leaveGroupPending
// v2.9 변경:
//   - GET /groups/mine (기존 /groups/me 대체) — my_status 필드 포함
//   - DELETE /groups/:id/leave (pending 신청 취소)
//   - POST /groups purpose 자유 텍스트 (category 제거)

import 'mock_data.dart';

class MockGroups {
  MockGroups._();

  // ── 내 그룹 목록 — GET /groups/mine ──────────────────────────
  // v2.9: my_status 필드 추가 (active / pending / group_pending)
  //   active:        정식 멤버
  //   pending:       내가 신청 → 관리자 승인 대기 중
  //   group_pending: 그룹이 나에게 초대 → 내 수락 대기 중
  static Map<String, dynamic> getMyGroupsMine(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user  = MockStore.users.firstWhere((u) => u['email'] == email);
    final plan  = user['plan'] as String? ?? 'free';

    // v2.5: 플랜별 최대 멤버 수
    const memberLimits = {'free': 2, 'pro': 10, 'business': -1};
    final memberLimit  = memberLimits[plan] ?? 2;

    return {
      'success': true,
      'data': [
        // ── 정식 멤버 그룹 (my_status: active) ──────────────────
        {
          'id':               1,
          'name':             'METI 개발자 모임',
          'description':      'Flutter & Dart 개발자 커뮤니티',
          'purpose':          '플러터와 다트 개발자들의 지식 공유 및 네트워킹 스터디 모임',
          'visibility':       'public',
          'status':           'active',
          'admin_plan':       plan,
          'member_count':     memberLimit == -1 ? 24 : memberLimit,
          'max_group_members': memberLimit == -1 ? null : memberLimit,
          'my_role':          'admin',
          'admin_name':       '홍길동',
          'my_status':        'active',   // v2.9 신규
        },
        // ── 가입 신청 중 그룹 (my_status: pending) ──────────────
        {
          'id':               2,
          'name':             'METI 디자이너 모임',
          'description':      'UI/UX 디자이너들의 포트폴리오 공유 그룹',
          'purpose':          '디자인 트렌드 공유 및 피드백 스터디',
          'visibility':       'public',
          'status':           'active',
          'admin_plan':       'pro',
          'member_count':     5,
          'max_group_members': 10,
          'my_role':          'member',
          'admin_name':       '이디자',
          'my_status':        'pending',  // v2.9 신규 — 승인 대기 중
        },
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 2, 'total_pages': 1, 'has_next': false},
    };
  }

  // ── 그룹 가입 신청 — POST /groups/:id/join ───────────────────
  // v2.5: 플랜별 멤버 한도 체크
  static Map<String, dynamic> joinGroup(
      String accessToken, int groupId, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user  = MockStore.users.firstWhere((u) => u['email'] == email);
    final plan  = user['plan'] as String? ?? 'free';

    // Mock: 그룹 관리자 플랜 기준 한도 체크
    const memberLimits = {'free': 2, 'pro': 10, 'business': -1};
    final limit = memberLimits[plan] ?? 2;

    // Mock 시나리오: free 플랜 → 이미 한도 도달(2/2)
    if (limit != -1 && groupId == 1 && plan == 'free') {
      throw MockApiException(
        '플랜 멤버 한도에 도달했습니다. 플랜을 업그레이드해주세요.',
        422,
        errorCode: 'plan_member_limit_reached',
        upgradeRequired: true,
        extra: {'current': limit, 'limit': limit},
      );
    }

    return {
      'success': true,
      'data': null,
      'message': '그룹 가입 신청이 완료되었습니다.',
    };
  }

  // ── 그룹 탈퇴 / pending 신청 취소 — DELETE /groups/:id/leave ─
  // v2.9 신규: pending 상태인 경우 가입 신청 취소로 동작
  static Map<String, dynamic> leaveGroup(
      String accessToken, int groupId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    // Mock: groupId=2 는 pending 상태의 그룹
    if (groupId == 2) {
      return {
        'success': true,
        'data': null,
        'message': '그룹 가입 신청이 취소되었습니다.',
      };
    }

    // groupId=1 은 정식 멤버 → 탈퇴 (관리자는 탈퇴 불가)
    return {
      'success': true,
      'data': null,
      'message': '그룹에서 탈퇴했습니다.',
    };
  }

  // ── 그룹 개설 — POST /groups ─────────────────────────────────
  // v2.9: category 제거, purpose 자유 텍스트(5자 이상) 필수
  //       플랜 무관 누구나 신청 가능
  static Map<String, dynamic> createGroup(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final purpose = body['purpose'] as String? ?? '';
    if (purpose.trim().length < 5) {
      throw MockApiException('그룹 목적은 5자 이상 입력해주세요.', 422);
    }

    final name = body['name'] as String? ?? '';
    if (name.trim().isEmpty) {
      throw MockApiException('그룹 이름을 입력해주세요.', 422);
    }

    final user = MockStore.users.firstWhere((u) => u['email'] == email);

    return {
      'success': true,
      'data': {
        'id':          99,
        'name':        name,
        'description': body['description'],
        'purpose':     purpose,
        'visibility':  body['visibility'] ?? 'public',
        'status':      'active',
        'admin_plan':  user['plan'],
        'member_count': 1,
        'my_role':     'admin',
        'my_status':   'active',
        'created_at':  DateTime.now().toIso8601String(),
      },
      'message': '그룹 개설 신청이 완료되었습니다.',
    };
  }
}
