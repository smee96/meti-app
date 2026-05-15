// Mock API - 백엔드 없이 회원가입/로그인 흐름 테스트용
// app_constants.dart의 useMock = true 로 전환

class MockUsers {
  static final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'email': 'test@meti.dev',
      'password': 'MetiTest1234!',
      'name': '홍길동',
      'role': 'user',
      'account_type': 'personal',
      'plan': 'free',
      'is_verified': 1,
      'avatar_url': null,
      'created_at': '2026-01-01 00:00:00',
      'point_balance': 3500,
    }
  ];

  static final Map<String, String> _verifyTokens = {};
  // ignore: unused_field
  static final Map<String, String> _resetTokens = {};
  static final Map<String, String> _accessTokens = {};
  static final Map<String, String> _refreshTokens = {};

  // ── 회원가입 ─────────────────────────────────────────
  static Map<String, dynamic> register(Map<String, dynamic> body) {
    final email = body['email'] as String;
    final name = body['name'] as String;
    final password = body['password'] as String;

    if (_users.any((u) => u['email'] == email)) {
      throw MockApiException('이미 사용 중인 이메일입니다.', 409);
    }
    if (password.length < 8) {
      throw MockApiException('비밀번호는 8자 이상이어야 합니다.', 422);
    }

    final userId = _users.length + 1;
    final verifyToken = 'mock-verify-${DateTime.now().millisecondsSinceEpoch}';
    _users.add({
      'id': userId,
      'email': email,
      'password': password,
      'name': name,
      'role': 'user',
      'account_type': 'personal', // v2.8: 서버 자동 고정 — body 값 무시
      'plan': 'free',
      'is_verified': 0,
      'avatar_url': null,
      'created_at': DateTime.now().toIso8601String(),
      'point_balance': 0,
    });
    _verifyTokens[verifyToken] = email;

    return {
      'success': true,
      'data': {
        'user_id': userId,
        'email': email,
        'verify_token': verifyToken,
      },
      'message': '회원가입이 완료되었습니다. 이메일을 확인해주세요.',
    };
  }

  // ── 이메일 인증 ───────────────────────────────────────
  static Map<String, dynamic> verifyEmail(String token) {
    final email = _verifyTokens[token];
    if (email == null) throw MockApiException('유효하지 않은 인증 토큰입니다.', 400);

    final user = _users.firstWhere((u) => u['email'] == email);
    user['is_verified'] = 1;
    _verifyTokens.remove(token);

    return {'success': true, 'data': null, 'message': '이메일 인증이 완료되었습니다.'};
  }

  // ── 로그인 ────────────────────────────────────────────
  static Map<String, dynamic> login(String email, String password) {
    final users = _users.where((u) => u['email'] == email).toList();
    if (users.isEmpty) throw MockApiException('이메일 또는 비밀번호가 올바르지 않습니다.', 401);

    final user = users.first;
    if (user['password'] != password) {
      throw MockApiException('이메일 또는 비밀번호가 올바르지 않습니다.', 401);
    }
    if (user['is_verified'] == 0) {
      throw MockApiException('이메일 인증이 필요합니다.', 403);
    }

    final accessToken = 'mock-access-${user['id']}-${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken = 'mock-refresh-${user['id']}-${DateTime.now().millisecondsSinceEpoch}';
    _accessTokens[accessToken] = email;
    _refreshTokens[refreshToken] = email;

    return {
      'success': true,
      'data': {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': 'Bearer',
        'user': {
          'id': user['id'],
          'email': user['email'],
          'name': user['name'],
          'role': user['role'] ?? 'user',
          'account_type': user['account_type'],
          'plan': user['plan'],
          'point_balance': user['point_balance'] ?? 0,
        },
      },
      'message': '로그인 성공',
    };
  }

  // ── 내 프로필 ─────────────────────────────────────────
  static Map<String, dynamic> getMe(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = _users.firstWhere((u) => u['email'] == email);
    return {
      'success': true,
      'data': {
        'id': user['id'],
        'email': user['email'],
        'name': user['name'],
        'role': user['role'] ?? 'user',
        'account_type': user['account_type'],
        'plan': user['plan'],
        'plan_expires_at': null,
        'avatar_url': user['avatar_url'],
        'is_verified': user['is_verified'],
        'created_at': user['created_at'],
        'point_balance': user['point_balance'] ?? 0,
      },
    };
  }

  // ── 토큰 갱신 ─────────────────────────────────────────
  static Map<String, dynamic> refreshToken(String refreshToken) {
    final email = _refreshTokens[refreshToken];
    if (email == null) throw MockApiException('유효하지 않은 토큰입니다.', 401);

    _refreshTokens.remove(refreshToken);
    final newAccess = 'mock-access-new-${DateTime.now().millisecondsSinceEpoch}';
    final newRefresh = 'mock-refresh-new-${DateTime.now().millisecondsSinceEpoch}';
    _accessTokens[newAccess] = email;
    _refreshTokens[newRefresh] = email;

    return {
      'success': true,
      'data': {
        'access_token': newAccess,
        'refresh_token': newRefresh,
        'token_type': 'Bearer',
      },
    };
  }

  // ── 로그아웃 ──────────────────────────────────────────
  static Map<String, dynamic> logout(String? accessToken) {
    if (accessToken != null) _accessTokens.remove(accessToken);
    return {'success': true, 'data': null, 'message': '로그아웃되었습니다.'};
  }

  // ── Mock 포인트 지갑 ──────────────────────────────────
  // v2.8: expiring_soon 구조 추가 (곧 만료 예정 포인트 안내)
  static Map<String, dynamic> getPointWallet(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    return {
      'success': true,
      'data': {
        'balance': user['point_balance'] ?? 3500,
        'expiring_soon': {
          'amount': 2000,
          'expires_at': '2026-06-01T00:00:00.000Z',
        },
      },
    };
  }

  /// 그룹 포인트 잔액 — GET /points/groups/:groupId/balance [v2.8]
  static Map<String, dynamic> getGroupPointBalance(int groupId) {
    final balance = _groupPointBalance[groupId] ?? 0;
    return {
      'success': true,
      'data': {
        'group_id': groupId,
        'group_name': 'METI 개발자 모임',
        'balance': balance,
      },
    };
  }

  // ── Mock 포인트 거래내역 ──────────────────────────────
  // v2.8 type 값: charge_subscription | charge_web | charge_admin
  //               use_event | use_admin | transfer_out | transfer_in
  // v2.8 point_type: subscription | charged | reward
  static Map<String, dynamic> getPointTransactions(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    return {
      'success': true,
      'data': [
        {
          'id': 1,
          'type': 'charge_subscription',  // v2.8: 구독으로 지급된 포인트
          'point_type': 'subscription',    // 다음 갱신일 만료
          'amount': 10000,
          'balance_after': 10000,
          'ref_type': 'subscription',
          'ref_id': null,
          'description': 'Pro 플랜 구독 포인트 지급',
          'created_at': '2026-03-01T10:00:00Z',
        },
        {
          'id': 2,
          'type': 'charge_web',           // v2.8: 웹 결제로 직접 충전
          'point_type': 'charged',         // 90일 후 만료
          'amount': 5000,
          'balance_after': 15000,
          'ref_type': 'payment',
          'ref_id': 'pay_mock_001',
          'description': '포인트 직접 충전',
          'created_at': '2026-02-28T10:01:00Z',
        },
        {
          'id': 3,
          'type': 'charge_admin',         // v2.8: 관리자 지급 (보상·환불)
          'point_type': 'reward',          // 90일 후 만료
          'amount': 2000,
          'balance_after': 17000,
          'ref_type': null,
          'ref_id': null,
          'description': '행사 취소 환불 포인트',
          'created_at': '2026-04-15T14:30:00Z',
        },
        {
          'id': 4,
          'type': 'transfer_out',         // v2.8: 그룹으로 포인트 이전
          'point_type': null,
          'amount': -1000,
          'balance_after': 16000,
          'ref_type': 'group',
          'ref_id': '1',
          'description': '그룹 포인트 이전',
          'created_at': '2026-04-21T09:00:00Z',
        },
        {
          'id': 5,
          'type': 'use_event',            // v2.8: 행사 참가비 차감
          'point_type': null,
          'amount': -13500,
          'balance_after': 3500,
          'ref_type': 'event',
          'ref_id': '10',
          'description': '그룹 명함 발급',
          'created_at': '2026-04-25T14:30:00Z',
        },
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 5, 'total_pages': 1, 'has_next': false},
    };
  }

  // ── Mock 명함 데이터 ──────────────────────────────────
  // 명함 한도: free=1장, pro=3장, business=10장 (v2.7 플랜 정책)
  static final List<Map<String, dynamic>> _cards = [
    {
      'id': 1,
      'user_id': 1,
      'group_id': null,
      'card_type': 'personal',
      'name': '홍길동',
      'title': '시니어 개발자',
      'company': 'METI Corp',
      'email': 'test@meti.dev',
      'phone': '010-1234-5678',
      'website': 'https://meti.dev',
      'bio': 'Flutter & Dart 개발자입니다.',
      'avatar_url': null,
      'template_id': 'modern_blue',
      'is_primary': 1,
      'is_public': 0,
      'is_active': 1,
      'created_at': '2026-01-01 00:00:00',
      'updated_at': '2026-01-01 00:00:00',
      'sns_count': 0,
    },
    {
      'id': 2,
      'user_id': 1,
      'group_id': null,
      'card_type': 'personal',
      'name': '홍길동 (공개)',
      'title': 'Flutter Developer',
      'company': 'METI Corp',
      'email': 'public@meti.app',
      'phone': null,
      'website': null,
      'bio': '공개 명함입니다.',
      'avatar_url': null,
      'template_id': 'minimal',
      'is_primary': 0,
      'is_public': 1,
      'is_active': 1,
      'created_at': '2026-02-01 00:00:00',
      'updated_at': '2026-02-01 00:00:00',
      'sns_count': 2,
    },
    {
      'id': 3,
      'user_id': 1,
      'group_id': null,
      'card_type': 'personal',
      'name': '홍길동 (다크)',
      'title': 'Tech Lead',
      'company': null,
      'email': 'tech@meti.app',
      'phone': '010-0000-0000',
      'website': null,
      'bio': null,
      'avatar_url': null,
      'template_id': 'dark',
      'is_primary': 0,
      'is_public': 0,
      'is_active': 1,
      'created_at': '2026-03-01 00:00:00',
      'updated_at': '2026-03-01 00:00:00',
      'sns_count': 0,
    },
  ];

  static Map<String, dynamic> getCards() {
    return {
      'success': true,
      'data': List<Map<String, dynamic>>.from(_cards),
      'pagination': {
        'page': 1, 'limit': 20,
        'total': _cards.length, 'total_pages': 1, 'has_next': false,
      },
    };
  }

  /// 명함 생성 — 플랜별 한도 체크 (free=1, pro=3, business=10) [v2.7]
  static Map<String, dynamic> createCard(
      String accessToken, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final plan = user['plan'] as String? ?? 'free';

    // 플랜별 명함 한도 체크 (v2.7: free=1, pro=3, business=10)
    const limits = {'free': 1, 'pro': 3, 'business': 10};
    final limit = limits[plan] ?? 1;
    final userCardCount = _cards.where((c) => c['user_id'] == user['id']).length;
    if (userCardCount >= limit) {
      throw MockApiException(
        '명함 생성 한도를 초과했습니다.',
        422,
        errorCode: 'card_limit_exceeded',
        upgradeRequired: true,
        extra: {
          'current': userCardCount,
          'limit': limit,
          'extra_price': 5000,
        },
      );
    }

    final newCard = {
      'id': DateTime.now().millisecondsSinceEpoch % 100000,
      'user_id': user['id'],
      'group_id': null,
      'card_type': body['card_type'] ?? 'personal',
      ...body,
      'is_active': 1,
      'sns_count': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    _cards.add(newCard);
    return {'success': true, 'data': newCard, 'message': '명함이 생성되었습니다.'};
  }

  // ── Mock 내 그룹 목록 ─────────────────────────────────
  static Map<String, dynamic> getMyGroups(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final plan = user['plan'] as String? ?? 'free';
    // v2.5: 플랜별 최대 멤버 수
    const memberLimits = {'free': 2, 'pro': 10, 'business': -1};
    final memberLimit = memberLimits[plan] ?? 2;
    return {
      'success': true,
      'data': [
        {
          'id': 1,
          'name': 'METI 개발자 모임',
          'description': 'Flutter & Dart 개발자 커뮤니티',
          'purpose': 'study',
          'visibility': 'public',
          'status': 'active',
          'admin_plan': plan,
          'member_count': memberLimit == -1 ? 24 : memberLimit,
          'max_group_members': memberLimit == -1 ? null : memberLimit,
          'my_role': 'admin',
          'admin_name': '홍길동',
        },
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 1, 'total_pages': 1, 'has_next': false},
    };
  }

  /// 초대링크 미리보기 — 인증 불필요, 그룹 정보 반환
  /// v2.8: GET /groups/invite/:token
  static Map<String, dynamic> invitePreview(String token) {
    if (token.isEmpty) {
      throw MockApiException('유효하지 않은 초대 링크입니다.', 404);
    }
    return {
      'success': true,
      'data': {
        'group_id': 1,
        'group_name': 'METI 개발자 모임',
        'label': '일반 초대',
        'max_uses': 100,
        'used_count': 3,
        'expires_at': null,
      },
    };
  }

  /// 초대링크로 즉시 가입 — 인증 필요
  /// v2.8: POST /auth/invite/:token/join (토큰은 path param, body 불필요)
  static Map<String, dynamic> inviteJoin(
      String accessToken, String token, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    if (token.isEmpty) {
      throw MockApiException('유효하지 않은 초대 링크입니다.', 404);
    }
    return {
      'success': true,
      'data': {'group_id': 1, 'group_name': 'METI 개발자 모임'},
      'message': '그룹에 가입되었습니다.',
    };
  }

  /// 개인 → 그룹 포인트 이체 (관리자 전용)
  static Map<String, dynamic> transferPoints(
      String accessToken, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);

    final amount = body['amount'] as int? ?? 0;
    if (amount <= 0) {
      throw MockApiException('이체 금액은 1P 이상이어야 합니다.', 422);
    }
    final current = (user['point_balance'] as int?) ?? 0;
    if (current < amount) {
      throw MockApiException(
        '포인트가 부족합니다.',
        422,
        errorCode: 'insufficient_points',
        extra: {
          'required': amount,
          'current': current,
          'short': amount - current,
        },
      );
    }
    // 차감
    user['point_balance'] = current - amount;
    return {
      'success': true,
      'data': {
        'transferred': amount,
        'personal_balance_after': user['point_balance'],
      },
      'message': '${amount}P가 그룹으로 이체되었습니다.',
    };
  }

  /// 행사 참가 신청 — 그룹 포인트 3,000P 차감 시뮬레이션 (insufficient_points)
  static Map<String, dynamic> joinEvent(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    const required = 3000;
    final current = (user['point_balance'] as int?) ?? 0;
    if (current < required) {
      throw MockApiException(
        '포인트가 부족합니다.',
        422,
        errorCode: 'insufficient_points',
        extra: {
          'required': required,
          'current': current,
          'short': required - current,
        },
      );
    }
    // 포인트 충분 → 차감 후 성공
    user['point_balance'] = current - required;
    return {'success': true, 'data': null, 'message': '행사 참가 신청이 완료되었습니다.'};
  }

  // ── v2.6 레슨 Mock 데이터 ─────────────────────────────
  static int _lessonIdSeq = 10;

  // 그룹별 레슨 목록 (groupId → List)
  static final Map<int, List<Map<String, dynamic>>> _lessons = {
    1: [
      {
        'id': 1,
        'group_id': 1,
        'instructor_id': 2,
        'instructor_name': '김철수',
        'title': '수영 초급 클래스',
        'description': '기초 호흡법과 자유형을 배웁니다.',
        'schedule_type': 'one-time',
        'scheduled_at': '2026-06-01T10:00:00',
        'duration_minutes': 60,
        'capacity': 10,
        'registered_count': 3,
        'location': '실내수영장 A레인',
        'point_cost': 500,
        'status': 'upcoming',
        'is_registered': false,
        'created_at': '2026-05-01T00:00:00Z',
      },
      {
        'id': 2,
        'group_id': 1,
        'instructor_id': 2,
        'instructor_name': '김철수',
        'title': '수영 중급 — 접영 특강',
        'description': '접영 기초 동작 집중 훈련',
        'schedule_type': 'one-time',
        'scheduled_at': '2026-06-08T10:00:00',
        'duration_minutes': 90,
        'capacity': 8,
        'registered_count': 8,
        'location': '실내수영장 B레인',
        'point_cost': 500,
        'status': 'upcoming',
        'is_registered': true,
        'created_at': '2026-05-02T00:00:00Z',
      },
      {
        'id': 3,
        'group_id': 1,
        'instructor_id': 2,
        'instructor_name': '김철수',
        'title': '4월 체험 레슨',
        'description': '무료 체험 레슨',
        'schedule_type': 'one-time',
        'scheduled_at': '2026-04-10T10:00:00',
        'duration_minutes': 45,
        'capacity': 15,
        'registered_count': 12,
        'location': '야외 수영장',
        'point_cost': 500,
        'status': 'ended',
        'is_registered': false,
        'created_at': '2026-04-01T00:00:00Z',
      },
    ],
  };

  // 수강 신청 목록 (lessonId → List<userId>)
  static final Map<int, List<int>> _lessonRegistrations = {
    2: [1], // 레슨 2에 userId=1 등록됨
  };

  /// 레슨 목록 조회 (그룹 멤버)
  static Map<String, dynamic> getLessons(int groupId,
      {String? status}) {
    final list = List<Map<String, dynamic>>.from(
        _lessons[groupId] ?? []);
    final filtered = status != null
        ? list.where((l) => l['status'] == status).toList()
        : list;
    return {
      'success': true,
      'data': filtered,
      'pagination': {
        'page': 1,
        'limit': 20,
        'total': filtered.length,
        'has_next': false,
      },
    };
  }

  /// 레슨 생성 — admin/sub_admin/instructor 전용, 그룹 포인트 500P 차감
  static Map<String, dynamic> createLesson(
      String accessToken, int groupId, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    // 그룹 포인트 잔액 체크 (Mock: 그룹 잔액을 별도 관리)
    // 간단히 _groupPointBalance 맵으로 시뮬레이션
    const cost = 500;
    final balance = _groupPointBalance[groupId] ?? 0;
    if (balance < cost) {
      throw MockApiException(
        '그룹 포인트가 부족합니다.',
        422,
        errorCode: 'insufficient_group_points',
        extra: {'required': cost, 'current': balance, 'shortage': cost - balance},
      );
    }
    _groupPointBalance[groupId] = balance - cost;

    _lessonIdSeq++;
    final newLesson = {
      'id': _lessonIdSeq,
      'group_id': groupId,
      'instructor_id': body['instructor_id'],
      'instructor_name': body['instructor_name'] ?? '강사',
      'title': body['title'] ?? '새 레슨',
      'description': body['description'],
      'schedule_type': body['schedule_type'] ?? 'one-time',
      'scheduled_at': body['scheduled_at'] ?? DateTime.now().toIso8601String(),
      'duration_minutes': body['duration_minutes'] ?? 60,
      'capacity': body['capacity'] ?? 10,
      'registered_count': 0,
      'location': body['location'],
      'point_cost': cost,
      'status': 'upcoming',
      'is_registered': false,
      'created_at': DateTime.now().toIso8601String(),
    };
    _lessons.putIfAbsent(groupId, () => []).add(newLesson);
    return {
      'success': true,
      'data': newLesson,
      'message': '레슨이 개설되었습니다. (그룹 포인트 ${cost}P 차감)',
    };
  }

  /// 레슨 수강 신청 (그룹 멤버)
  static Map<String, dynamic> registerLesson(
      String accessToken, int lessonId) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    // 레슨 찾기
    Map<String, dynamic>? lesson;
    for (final list in _lessons.values) {
      final idx = list.indexWhere((l) => l['id'] == lessonId);
      if (idx != -1) { lesson = list[idx]; break; }
    }
    if (lesson == null) throw MockApiException('레슨을 찾을 수 없습니다.', 404);

    final regs = _lessonRegistrations.putIfAbsent(lessonId, () => []);
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
    lesson['is_registered'] = true;

    return {'success': true, 'data': null, 'message': '수강 신청이 완료되었습니다.'};
  }

  /// 레슨 수강 취소
  static Map<String, dynamic> cancelLessonRegistration(
      String accessToken, int lessonId) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    Map<String, dynamic>? lesson;
    for (final list in _lessons.values) {
      final idx = list.indexWhere((l) => l['id'] == lessonId);
      if (idx != -1) { lesson = list[idx]; break; }
    }
    if (lesson == null) throw MockApiException('레슨을 찾을 수 없습니다.', 404);

    final regs = _lessonRegistrations[lessonId];
    if (regs == null || !regs.contains(userId)) {
      throw MockApiException('수강 신청 내역이 없습니다.', 404);
    }
    regs.remove(userId);
    lesson['registered_count'] = ((lesson['registered_count'] as int) - 1).clamp(0, 9999);
    lesson['is_registered'] = false;

    return {'success': true, 'data': null, 'message': '수강 신청이 취소되었습니다.'};
  }

  /// 레슨 취소 (admin/sub_admin 전용)
  static Map<String, dynamic> cancelLesson(
      String accessToken, int lessonId) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    for (final list in _lessons.values) {
      final idx = list.indexWhere((l) => l['id'] == lessonId);
      if (idx != -1) {
        list[idx] = Map<String, dynamic>.from(list[idx])
          ..['status'] = 'cancelled';
        return {'success': true, 'data': null, 'message': '레슨이 취소되었습니다.'};
      }
    }
    throw MockApiException('레슨을 찾을 수 없습니다.', 404);
  }

  // 그룹 포인트 잔액 (Mock)
  static final Map<int, int> _groupPointBalance = {1: 8000};

  // ── v2.6 이벤트 Mock 데이터 ──────────────────────────
  static int _eventIdSeq = 10;

  // 그룹별 이벤트 목록 (groupId → List)
  static final Map<int, List<Map<String, dynamic>>> _groupEvents = {
    1: [
      {
        'id': 1,
        'group_id': 1,
        'title': 'METI 개발자 네트워킹 밋업 2026',
        'description': 'Flutter & Dart 개발자들의 오프라인 네트워킹 모임입니다.',
        'location': '서울 강남구 테헤란로 123',
        'starts_at': '2026-07-10T18:00:00',
        'ends_at': '2026-07-10T21:00:00',
        'status': 'upcoming',
        'visibility': 'public',
        'registration_type': 'pre_required',
        'capacity': 30,
        'participant_count': 12,
        'is_joined': false,
        'entry_fee': 0,
        'group_name': 'METI 개발자 모임',
        'organizer_name': '홍길동',
        'creation_cost': 1000,
        'created_at': '2026-06-01T00:00:00Z',
      },
      {
        'id': 2,
        'group_id': 1,
        'title': '수영 특별 행사 — 여름 마라톤',
        'description': '그룹 회원 대상 수영 마라톤 대회',
        'location': '올림픽 수영장',
        'starts_at': '2026-08-15T09:00:00',
        'ends_at': '2026-08-15T17:00:00',
        'status': 'upcoming',
        'visibility': 'public',
        'registration_type': 'pre_required',
        'capacity': 80,
        'participant_count': 45,
        'is_joined': true,
        'entry_fee': 0,
        'group_name': 'METI 개발자 모임',
        'organizer_name': '홍길동',
        'creation_cost': 3000,
        'created_at': '2026-06-10T00:00:00Z',
      },
      {
        'id': 3,
        'group_id': 1,
        'title': '5월 정기 모임',
        'description': '그룹 정기 모임 및 성과 공유',
        'location': '강남 코워킹스페이스',
        'starts_at': '2026-05-20T19:00:00',
        'ends_at': '2026-05-20T21:00:00',
        'status': 'ended',
        'visibility': 'public',
        'registration_type': 'free',
        'capacity': 20,
        'participant_count': 18,
        'is_joined': false,
        'entry_fee': 0,
        'group_name': 'METI 개발자 모임',
        'organizer_name': '홍길동',
        'creation_cost': 1000,
        'created_at': '2026-05-01T00:00:00Z',
      },
    ],
  };

  // 이벤트 참가자 목록 (eventId → List<userId>)
  static final Map<int, List<int>> _eventParticipants = {
    2: [1], // 이벤트 2에 userId=1 참가
  };

  /// 그룹 이벤트 목록 조회
  static Map<String, dynamic> getGroupEvents(int groupId, {String? status}) {
    final list = List<Map<String, dynamic>>.from(_groupEvents[groupId] ?? []);
    final filtered =
        status != null ? list.where((e) => e['status'] == status).toList() : list;
    return {
      'success': true,
      'data': filtered,
      'pagination': {
        'page': 1,
        'limit': 20,
        'total': filtered.length,
        'has_next': false,
      },
    };
  }

  /// 이벤트 생성 — admin/sub_admin 전용, 그룹 포인트 차감
  /// 정원 기반 비용: ≤30 → 1,000P / 31-100 → 3,000P / >100 → 5,000P
  static Map<String, dynamic> createGroupEvent(
      String accessToken, int groupId, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final cap = body['capacity'] as int? ?? 30;
    final cost = cap <= 30 ? 1000 : cap <= 100 ? 3000 : 5000;

    final balance = _groupPointBalance[groupId] ?? 0;
    if (balance < cost) {
      throw MockApiException(
        '그룹 포인트가 부족합니다.',
        422,
        errorCode: 'insufficient_group_points',
        extra: {'required': cost, 'current': balance, 'shortage': cost - balance},
      );
    }
    _groupPointBalance[groupId] = balance - cost;

    _eventIdSeq++;
    final newEvent = {
      'id': _eventIdSeq,
      'group_id': groupId,
      'title': body['title'] ?? '새 이벤트',
      'description': body['description'],
      'location': body['location'],
      'starts_at': body['starts_at'] ?? DateTime.now().toIso8601String(),
      'ends_at': body['ends_at'],
      'status': 'upcoming',
      'visibility': body['visibility'] ?? 'public',
      'registration_type': body['registration_type'] ?? 'pre_required',
      'capacity': cap,
      'participant_count': 0,
      'is_joined': false,
      'entry_fee': body['entry_fee'] ?? 0,
      'group_name': 'METI 개발자 모임',
      'organizer_name': email,
      'creation_cost': cost,
      'created_at': DateTime.now().toIso8601String(),
    };
    _groupEvents.putIfAbsent(groupId, () => []).add(newEvent);
    return {
      'success': true,
      'data': newEvent,
      'message': '이벤트가 개설되었습니다. (그룹 포인트 ${cost}P 차감)',
    };
  }

  /// 이벤트 참가 신청 (사용자) — POST /events/:id/join
  static Map<String, dynamic> joinGroupEvent(
      String accessToken, int eventId) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    // 이벤트 찾기
    Map<String, dynamic>? event;
    for (final list in _groupEvents.values) {
      final idx = list.indexWhere((e) => e['id'] == eventId);
      if (idx != -1) {
        event = list[idx];
        break;
      }
    }
    if (event == null) throw MockApiException('이벤트를 찾을 수 없습니다.', 404);
    if (event['status'] != 'upcoming' && event['status'] != 'ongoing') {
      throw MockApiException('참가 신청이 불가한 이벤트입니다.', 422);
    }

    final participants = _eventParticipants.putIfAbsent(eventId, () => []);
    if (participants.contains(userId)) {
      throw MockApiException('이미 참가 신청한 이벤트입니다.', 409);
    }

    final cap = event['capacity'] as int?;
    final count = event['participant_count'] as int;
    if (cap != null && count >= cap) {
      throw MockApiException('참가 정원이 가득 찼습니다.', 409);
    }

    // 참가비 차감 (entry_fee > 0인 경우)
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
    event['is_joined'] = true;

    return {'success': true, 'data': null, 'message': '이벤트 참가 신청이 완료되었습니다.'};
  }

  /// 이벤트 참가 취소 (사용자) — DELETE /events/:id/join
  static Map<String, dynamic> leaveGroupEvent(
      String accessToken, int eventId) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    Map<String, dynamic>? event;
    for (final list in _groupEvents.values) {
      final idx = list.indexWhere((e) => e['id'] == eventId);
      if (idx != -1) {
        event = list[idx];
        break;
      }
    }
    if (event == null) throw MockApiException('이벤트를 찾을 수 없습니다.', 404);

    final participants = _eventParticipants[eventId];
    if (participants == null || !participants.contains(userId)) {
      throw MockApiException('참가 신청 내역이 없습니다.', 404);
    }

    participants.remove(userId);
    final count = event['participant_count'] as int;
    event['participant_count'] = (count - 1).clamp(0, 99999);
    event['is_joined'] = false;

    return {'success': true, 'data': null, 'message': '이벤트 참가 신청이 취소되었습니다.'};
  }

  /// 이벤트 취소 (admin/sub_admin 전용) — DELETE /events/groups/:gid/events/:id
  static Map<String, dynamic> cancelGroupEvent(
      String accessToken, int eventId) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    for (final list in _groupEvents.values) {
      final idx = list.indexWhere((e) => e['id'] == eventId);
      if (idx != -1) {
        list[idx] = Map<String, dynamic>.from(list[idx])
          ..['status'] = 'cancelled';
        return {'success': true, 'data': null, 'message': '이벤트가 취소되었습니다.'};
      }
    }
    throw MockApiException('이벤트를 찾을 수 없습니다.', 404);
  }

  // ── v2.6 상품/주문/결제 Mock 데이터 ─────────────────────
  static int _productIdSeq = 10;
  static int _orderIdSeq   = 100;

  // 그룹별 상품 목록
  static final Map<int, List<Map<String, dynamic>>> _products = {
    1: [
      {
        'id': 1,
        'group_id': 1,
        'name': '수영 강습 쿠폰 (10회)',
        'description': '10회 수강 가능한 강습 쿠폰입니다.',
        'type': 'service',
        'price': 5000,
        'stock': 20,
        'sold_count': 7,
        'is_active': true,
        'expires_at': '2026-12-31T23:59:59Z',
        'image_url': null,
        'created_by': '홍길동',
        'created_at': '2026-05-01T00:00:00Z',
      },
      {
        'id': 2,
        'group_id': 1,
        'name': 'METI 굿즈 — 에코백',
        'description': '그룹 로고가 새겨진 에코백입니다.',
        'type': 'physical',
        'price': 8000,
        'stock': 50,
        'sold_count': 12,
        'is_active': true,
        'expires_at': null,
        'image_url': null,
        'created_by': '홍길동',
        'created_at': '2026-05-10T00:00:00Z',
      },
      {
        'id': 3,
        'group_id': 1,
        'name': '프리미엄 명함 디자인 서비스',
        'description': '전문 디자이너가 1:1로 명함을 제작해드립니다.',
        'type': 'service',
        'price': 15000,
        'stock': null,   // 무제한
        'sold_count': 3,
        'is_active': true,
        'expires_at': null,
        'image_url': null,
        'created_by': '홍길동',
        'created_at': '2026-05-15T00:00:00Z',
      },
    ],
  };

  // 주문 목록 (userId → List<Order>)
  static final Map<int, List<Map<String, dynamic>>> _orders = {};

  /// 그룹 상품 목록 조회
  static Map<String, dynamic> getGroupProducts(int groupId) {
    final list = List<Map<String, dynamic>>.from(_products[groupId] ?? []);
    return {
      'success': true,
      'data': list,
      'pagination': {'page': 1, 'limit': 20, 'total': list.length, 'has_next': false},
    };
  }

  /// 상품 생성 — admin/sub_admin 전용
  static Map<String, dynamic> createProduct(
      String accessToken, int groupId, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    _productIdSeq++;
    final newProduct = {
      'id': _productIdSeq,
      'group_id': groupId,
      'name': body['name'] ?? '새 상품',
      'description': body['description'],
      'type': body['type'] ?? 'service',
      'price': body['price'] ?? 0,
      'stock': body['stock'],
      'sold_count': 0,
      'is_active': true,
      'expires_at': body['expires_at'],
      'image_url': null,
      'created_by': email,
      'created_at': DateTime.now().toIso8601String(),
    };
    _products.putIfAbsent(groupId, () => []).add(newProduct);
    return {'success': true, 'data': newProduct, 'message': '상품이 등록되었습니다.'};
  }

  /// 상품 활성/비활성 토글
  static Map<String, dynamic> toggleProductActive(
      String accessToken, int productId, bool isActive) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    for (final list in _products.values) {
      final idx = list.indexWhere((p) => p['id'] == productId);
      if (idx != -1) {
        list[idx] = Map<String, dynamic>.from(list[idx])
          ..['is_active'] = isActive;
        return {
          'success': true,
          'data': null,
          'message': isActive ? '상품이 활성화되었습니다.' : '상품이 비활성화되었습니다.',
        };
      }
    }
    throw MockApiException('상품을 찾을 수 없습니다.', 404);
  }

  /// 상품 주문 생성 — POST /orders
  /// 포인트 결제: 즉시 차감 + 완료
  /// 웹 결제: order 생성 후 WebView URL 반환
  static Map<String, dynamic> createOrder(
      String accessToken, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final productId = body['product_id'] as int? ?? 0;
    final paymentMethod = body['payment_method'] as String? ?? 'points';

    // 상품 조회
    Map<String, dynamic>? product;
    for (final list in _products.values) {
      final idx = list.indexWhere((p) => p['id'] == productId);
      if (idx != -1) { product = list[idx]; break; }
    }
    if (product == null) throw MockApiException('상품을 찾을 수 없습니다.', 404);
    if (product['is_active'] != true) {
      throw MockApiException('판매 중인 상품이 아닙니다.', 422);
    }
    final stock = product['stock'] as int?;
    final sold  = product['sold_count'] as int? ?? 0;
    if (stock != null && sold >= stock) {
      throw MockApiException('상품 재고가 없습니다.', 422, errorCode: 'out_of_stock');
    }

    final price = product['price'] as int? ?? 0;
    _orderIdSeq++;
    final orderId = _orderIdSeq;

    if (paymentMethod == 'points') {
      // 포인트 결제
      final balance = (user['point_balance'] as int?) ?? 0;
      if (balance < price) {
        throw MockApiException(
          '포인트가 부족합니다.',
          422,
          errorCode: 'insufficient_points',
          extra: {'required': price, 'current': balance, 'short': price - balance},
        );
      }
      user['point_balance'] = balance - price;
      // 재고 차감
      if (stock != null) {
        for (final list in _products.values) {
          final idx = list.indexWhere((p) => p['id'] == productId);
          if (idx != -1) {
            list[idx] = Map<String, dynamic>.from(list[idx])
              ..['sold_count'] = sold + 1;
            break;
          }
        }
      }
      final order = {
        'id': orderId,
        'product_id': productId,
        'product_name': product['name'],
        'amount': price,
        'status': 'paid',
        'payment_method': 'points',
        'created_at': DateTime.now().toIso8601String(),
        'web_payment_url': null,
      };
      _orders.putIfAbsent(userId, () => []).add(order);
      return {
        'success': true,
        'data': order,
        'message': '${price}P로 결제가 완료되었습니다.',
      };
    } else {
      // 웹 결제 — order 생성 후 결제 URL 반환
      final order = {
        'id': orderId,
        'product_id': productId,
        'product_name': product['name'],
        'amount': price,
        'status': 'pending',
        'payment_method': 'web_payment',
        'created_at': DateTime.now().toIso8601String(),
        'web_payment_url':
            'https://the-meti.pages.dev/payment?order_id=$orderId',
      };
      _orders.putIfAbsent(userId, () => []).add(order);
      return {
        'success': true,
        'data': order,
        'message': '주문이 생성되었습니다. 결제 페이지로 이동합니다.',
      };
    }
  }

  /// 주문 내역 조회
  static Map<String, dynamic> getMyOrders(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;
    final list = List<Map<String, dynamic>>.from(_orders[userId] ?? []);
    list.sort((a, b) => (b['created_at'] as String)
        .compareTo(a['created_at'] as String));
    return {
      'success': true,
      'data': list,
      'pagination': {'page': 1, 'limit': 20, 'total': list.length, 'has_next': false},
    };
  }

  /// 웹 결제 완료 검증 — POST /payments/verify-web
  static Map<String, dynamic> verifyWebPayment(
      String accessToken, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;
    final orderId = body['order_id'] as int? ?? 0;

    final orders = _orders[userId] ?? [];
    final idx = orders.indexWhere((o) => o['id'] == orderId);
    if (idx == -1) throw MockApiException('주문을 찾을 수 없습니다.', 404);

    // Mock: 항상 결제 성공으로 처리
    orders[idx] = Map<String, dynamic>.from(orders[idx])
      ..['status'] = 'paid';

    // 재고 차감
    final productId = orders[idx]['product_id'] as int;
    for (final list in _products.values) {
      final pidx = list.indexWhere((p) => p['id'] == productId);
      if (pidx != -1) {
        final sold = list[pidx]['sold_count'] as int? ?? 0;
        final stock = list[pidx]['stock'] as int?;
        if (stock != null) {
          list[pidx] = Map<String, dynamic>.from(list[pidx])
            ..['sold_count'] = sold + 1;
        }
        break;
      }
    }

    return {
      'success': true,
      'data': orders[idx],
      'message': '결제가 확인되었습니다.',
    };
  }

  // ── 구독 결제 (Apple/Google) ──────────────────────────
  /// 구독 영수증 검증 — POST /payments/subscription/verify
  /// 구독 영수증 검증 [v2.8]
  /// - Apple IAP: POST /payments/subscription/verify-apple
  /// - Google Play: POST /payments/subscription/verify-google
  static Map<String, dynamic> verifySubscription(
      String accessToken, Map<String, dynamic> body,
      {String platform = 'apple'}) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);

    // Apple: receipt_data 필드 / Google: purchase_token + product_id 필드
    final plan = platform == 'google'
        ? _planFromProductId(body['product_id'] as String? ?? '')
        : (body['plan'] as String? ?? 'pro');

    final pointsMap = {'pro': 10000, 'business': 500000};
    final points = pointsMap[plan] ?? 10000;

    // Mock: 플랜 업그레이드 + 포인트 지급
    user['plan'] = plan;
    final prev = (user['point_balance'] as int?) ?? 0;
    user['point_balance'] = prev + points;

    return {
      'success': true,
      'data': {
        'plan': plan,
        'platform': platform,
        'points_granted': points,
        'new_balance': user['point_balance'],
        'expires_at': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
      },
      'message': '구독이 활성화되었습니다. ${points}P가 지급되었습니다.',
    };
  }

  /// Google Play product_id → plan 변환 헬퍼
  static String _planFromProductId(String productId) {
    if (productId.contains('business')) return 'business';
    return 'pro';
  }

  /// 구독 취소 — DELETE /payments/subscription
  static Map<String, dynamic> cancelSubscription(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    user['plan'] = 'free';
    return {
      'success': true,
      'data': null,
      'message': '구독이 취소되었습니다. 다음 결제일부터 Free 플랜으로 전환됩니다.',
    };
  }

  // ── v2.7 결제 토큰 Mock 데이터 ────────────────────────
  // 일회성 결제 토큰: 5분 유효, 1회 사용 즉시 무효화
  static final Map<String, Map<String, dynamic>> _paymentTokens = {};

  /// 일회성 결제 토큰 발급 — POST /payments/payment-token [v2.7]
  /// 동일 order_id 토큰 재발급 시 이전 토큰 자동 무효화
  static Map<String, dynamic> issuePaymentToken(
      String accessToken, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final orderId = body['order_id'] as int? ?? 0;
    if (orderId == 0) throw MockApiException('order_id가 필요합니다.', 422);

    // 동일 order_id 기존 토큰 무효화
    _paymentTokens.removeWhere((_, v) => v['order_id'] == orderId);

    final token = 'mock-pay-token-${user['id']}-${DateTime.now().millisecondsSinceEpoch}';
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));
    _paymentTokens[token] = {
      'token': token,
      'user_id': user['id'],
      'user_name': user['name'],
      'user_email': user['email'],
      'order_id': orderId,
      'expires_at': expiresAt.toIso8601String(),
      'is_used': false,
    };

    return {
      'success': true,
      'data': {
        'token': token,
        'expires_in': 300,
        'expires_at': expiresAt.toIso8601String(),
        'payment_url': '/payment?token=$token',
      },
    };
  }

  /// 결제 토큰 검증 — GET /payments/payment-token/verify?token=xxx [v2.7]
  /// 검증 즉시 is_used=true 처리 — 재사용 불가
  static Map<String, dynamic> verifyPaymentToken(String token) {
    final data = _paymentTokens[token];
    if (data == null) {
      throw MockApiException('유효하지 않은 결제 토큰입니다.', 400,
          errorCode: 'invalid_payment_token');
    }
    if (data['is_used'] == true) {
      throw MockApiException('이미 사용된 결제 토큰입니다.', 400,
          errorCode: 'token_already_used');
    }
    final expiresAt = DateTime.tryParse(data['expires_at'] as String? ?? '');
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      _paymentTokens.remove(token);
      throw MockApiException('만료된 결제 토큰입니다.', 400,
          errorCode: 'token_expired');
    }
    // 즉시 사용 처리
    _paymentTokens[token] = Map<String, dynamic>.from(data)..['is_used'] = true;

    // 주문 정보 조회
    final orderId = data['order_id'] as int;
    final userId = data['user_id'] as int;
    Map<String, dynamic>? order;
    final userOrders = _orders[userId] ?? [];
    final idx = userOrders.indexWhere((o) => o['id'] == orderId);
    if (idx != -1) order = userOrders[idx];

    return {
      'success': true,
      'data': {
        'user_id': data['user_id'],
        'user_name': data['user_name'],
        'user_email': data['user_email'],
        'order_id': orderId,
        'total_amount': order?['amount'] ?? 0,
        'order_status': order?['status'] ?? 'pending',
      },
    };
  }

  // ── v2.7 포인트 충전 상품 Mock 데이터 ────────────────────
  static const List<Map<String, dynamic>> _pointChargeProducts = [
    {'id': 1, 'title': '포인트 10,000P',  'amount_krw': 10000,  'points': 10000,  'is_custom': 0},
    {'id': 2, 'title': '포인트 100,000P', 'amount_krw': 100000, 'points': 100000, 'is_custom': 0},
    {'id': 3, 'title': '포인트 500,000P', 'amount_krw': 500000, 'points': 500000, 'is_custom': 0},
    {'id': 4, 'title': '직접 입력',       'amount_krw': 0,      'points': 0,      'is_custom': 1,
     'min_amount': 10000},
  ];

  /// 포인트 충전 상품 목록 — GET /payments/point-charge-products [v2.7]
  static Map<String, dynamic> getPointChargeProducts(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    return {
      'success': true,
      'data': List<Map<String, dynamic>>.from(_pointChargeProducts),
    };
  }

  /// 그룹 가입 신청 — 플랜별 멤버 한도 체크 (v2.5)
  static Map<String, dynamic> joinGroup(
      String accessToken, int groupId, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    // Mock: 그룹 id=1은 관리자 플랜(=현재 유저 플랜)으로 한도 체크
    // 실제 서버에서는 그룹 관리자 플랜을 기준으로 검사
    final user = _users.firstWhere((u) => u['email'] == email);
    final plan = user['plan'] as String? ?? 'free';
    const memberLimits = {'free': 2, 'pro': 10, 'business': -1};
    final limit = memberLimits[plan] ?? 2;
    // Mock 시나리오: free 플랜은 이미 2명(한도 도달) → 한도 초과 에러
    if (limit != -1 && groupId == 1 && plan == 'free') {
      throw MockApiException(
        '플랜 멤버 한도에 도달했습니다. 플랜을 업그레이드해주세요.',
        422,
        errorCode: 'plan_member_limit_reached',
        upgradeRequired: true,
        extra: {'current': limit, 'limit': limit},
      );
    }
    return {'success': true, 'data': null, 'message': '그룹 가입 신청이 완료되었습니다.'};
  }
}

class MockApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;
  final bool upgradeRequired;
  final Map<String, dynamic>? extra;

  MockApiException(
    this.message,
    this.statusCode, {
    this.errorCode,
    this.upgradeRequired = false,
    this.extra,
  });

  @override
  String toString() => message;
}
