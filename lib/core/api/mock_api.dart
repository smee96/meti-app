/// Mock API - 백엔드 없이 회원가입/로그인 흐름 테스트용
/// app_constants.dart의 useMock = true 로 전환

class MockUsers {
  static final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'email': 'test@meti.app',
      'password': 'Test1234!',
      'name': '홍길동',
      'account_type': 'personal',
      'plan': 'free',
      'is_verified': 1,
      'avatar_url': null,
      'created_at': '2026-01-01 00:00:00',
    }
  ];

  static final Map<String, String> _verifyTokens = {};
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
      'account_type': body['account_type'] ?? 'personal',
      'plan': 'free',
      'is_verified': 0,
      'avatar_url': null,
      'created_at': DateTime.now().toIso8601String(),
    });
    _verifyTokens[verifyToken] = email;

    return {
      'success': true,
      'data': {
        'user_id': userId,
        'email': email,
        'verify_token': verifyToken, // 개발 환경 노출
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
          'account_type': user['account_type'],
          'plan': user['plan'],
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
        'account_type': user['account_type'],
        'plan': user['plan'],
        'plan_expires_at': null,
        'avatar_url': user['avatar_url'],
        'is_verified': user['is_verified'],
        'created_at': user['created_at'],
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

  // ── Mock 명함 데이터 ──────────────────────────────────
  static Map<String, dynamic> getCards() {
    return {
      'success': true,
      'data': [
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
          'is_public': 1,
          'is_active': 1,
          'created_at': '2026-01-01 00:00:00',
          'updated_at': '2026-01-01 00:00:00',
          'sns_count': 0,
        }
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 1, 'total_pages': 1, 'has_next': false},
    };
  }
}

class MockApiException implements Exception {
  final String message;
  final int statusCode;
  MockApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
