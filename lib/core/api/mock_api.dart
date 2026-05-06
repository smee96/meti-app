// Mock API - 백엔드 없이 회원가입/로그인 흐름 테스트용
// app_constants.dart의 useMock = true 로 전환

class MockUsers {
  static final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'email': 'test@meti.app',
      'password': 'Test1234!',
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
      'account_type': body['account_type'] ?? 'personal',
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
  static Map<String, dynamic> getPointWallet(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    return {
      'success': true,
      'data': {
        'balance': user['point_balance'] ?? 3500,
        'total_earned': 10000,
        'total_spent': 6500,
        'updated_at': DateTime.now().toIso8601String(),
      },
    };
  }

  // ── Mock 포인트 거래내역 ──────────────────────────────
  static Map<String, dynamic> getPointTransactions(String accessToken) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    return {
      'success': true,
      'data': [
        {
          'id': 1,
          'type': 'earn',
          'amount': 10000,
          'balance_after': 10000,
          'description': 'Pro 플랜 포인트 충전',
          'created_at': '2026-03-01T10:00:00Z',
        },
        {
          'id': 2,
          'type': 'spend',
          'amount': -5000,
          'balance_after': 5000,
          'description': 'Pro 플랜 구독 (1개월)',
          'created_at': '2026-03-01T10:01:00Z',
        },
        {
          'id': 3,
          'type': 'spend',
          'amount': -1500,
          'balance_after': 3500,
          'description': '그룹 명함 발급',
          'created_at': '2026-04-15T14:30:00Z',
        },
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 3, 'total_pages': 1, 'has_next': false},
    };
  }

  // ── Mock 명함 데이터 ──────────────────────────────────
  // 명함 한도: free=3장, pro=10장 (v2.5 플랜 정책)
  static final List<Map<String, dynamic>> _cards = [
    {
      'id': 1,
      'user_id': 1,
      'group_id': null,
      'card_type': 'personal',
      'name': '홍길동',
      'title': '시니어 개발자',
      'company': 'METI Corp',
      'email': 'test@meti.app',
      'phone': '010-1234-5678',
      'website': 'https://meti.app',
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

  /// 명함 생성 — 플랜별 한도 체크 (free=3, pro=10, business=무제한)
  static Map<String, dynamic> createCard(
      String accessToken, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    final user = _users.firstWhere((u) => u['email'] == email);
    final plan = user['plan'] as String? ?? 'free';

    // 플랜별 명함 한도 체크
    const limits = {'free': 3, 'pro': 10, 'business': -1};
    final limit = limits[plan] ?? 3;
    if (limit != -1 && _cards.length >= limit) {
      throw MockApiException(
        '명함 생성 한도를 초과했습니다.',
        422,
        errorCode: 'card_limit_exceeded',
        upgradeRequired: true,
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
  static Map<String, dynamic> invitePreview(String token) {
    // Mock: 토큰이 존재하면 그룹 정보 반환
    if (token.isEmpty) {
      throw MockApiException('유효하지 않은 초대 링크입니다.', 404);
    }
    return {
      'success': true,
      'data': {
        'token': token,
        'label': '일반 초대',
        'group': {
          'id': 1,
          'name': 'METI 개발자 모임',
          'description': 'Flutter & Dart 개발자 커뮤니티',
          'purpose': 'study',
          'visibility': 'public',
          'member_count': 24,
        },
        'expires_at': null,
        'max_uses': 100,
        'use_count': 3,
      },
    };
  }

  /// 초대링크로 즉시 가입 — 인증 필요, birth_date 포함
  static Map<String, dynamic> inviteJoin(
      String accessToken, String token, Map<String, dynamic> body) {
    final email = _accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    if (token.isEmpty) {
      throw MockApiException('유효하지 않은 초대 링크입니다.', 404);
    }
    return {
      'success': true,
      'data': {'group_id': 1, 'status': 'active'},
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
