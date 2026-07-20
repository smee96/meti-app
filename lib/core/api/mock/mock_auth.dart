// mock_auth.dart — 인증 관련 Mock API
// 포함: register, verifyEmail, login, getMe, updateProfile,
//        uploadAvatar, refreshToken, logout, invitePreview, inviteJoin

import 'mock_data.dart';

class MockAuth {
  MockAuth._();

  // ── 회원가입 ──────────────────────────────────────────────────
  static Map<String, dynamic> register(Map<String, dynamic> body) {
    final email    = body['email']    as String;
    final name     = body['name']     as String;
    final password = body['password'] as String;

    if (MockStore.users.any((u) => u['email'] == email)) {
      throw MockApiException('이미 사용 중인 이메일입니다.', 409);
    }
    if (password.length < 8) {
      throw MockApiException('비밀번호는 8자 이상이어야 합니다.', 422);
    }

    final userId      = MockStore.users.length + 1;
    // v3.0 보안패치: verifyToken은 내부 MockStore 저장용으로만 사용
    // 서버 응답에 포함하지 않음 (실서버와 동일하게 이메일로만 전달)
    final verifyToken = 'mock-verify-${DateTime.now().millisecondsSinceEpoch}';
    MockStore.users.add({
      'id': userId,
      'email': email,
      'password': password,
      'name': name,
      'role': 'user',
      'account_type': 'personal', // v2.8: 서버 자동 고정
      'plan': 'free',
      'is_verified': 0,
      'avatar_url': null,
      'created_at': DateTime.now().toIso8601String(),
      'point_balance': 0,
    });
    MockStore.verifyTokens[verifyToken] = email;

    return {
      'success': true,
      'data': {
        'user_id': userId,
        'email': email,
        // verify_token 제거 (v3.0 보안패치: 서버는 토큰을 이메일로만 전달)
      },
      'message': '회원가입이 완료되었습니다. 이메일을 확인해주세요.',
    };
  }

  // ── 이메일 인증 ───────────────────────────────────────────────
  static Map<String, dynamic> verifyEmail(String token) {
    final email = MockStore.verifyTokens[token];
    if (email == null) throw MockApiException('유효하지 않은 인증 토큰입니다.', 400);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);
    user['is_verified'] = 1;
    MockStore.verifyTokens.remove(token);

    return {'success': true, 'data': null, 'message': '이메일 인증이 완료되었습니다.'};
  }

  // ── 로그인 ────────────────────────────────────────────────────
  static Map<String, dynamic> login(String email, String password) {
    final users = MockStore.users.where((u) => u['email'] == email).toList();
    if (users.isEmpty) {
      throw MockApiException('이메일 또는 비밀번호가 올바르지 않습니다.', 401);
    }

    final user = users.first;
    if (user['password'] != password) {
      throw MockApiException('이메일 또는 비밀번호가 올바르지 않습니다.', 401);
    }
    if (user['is_verified'] == 0) {
      throw MockApiException('이메일 인증이 필요합니다.', 403);
    }

    final accessToken  = 'mock-access-${user['id']}-${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken = 'mock-refresh-${user['id']}-${DateTime.now().millisecondsSinceEpoch}';
    MockStore.accessTokens[accessToken]   = email;
    MockStore.refreshTokens[refreshToken] = email;

    return {
      'success': true,
      'data': {
        'access_token':  accessToken,
        'refresh_token': refreshToken,
        'token_type': 'Bearer',
        'user': {
          'id':           user['id'],
          'email':        user['email'],
          'name':         user['name'],
          'role':         user['role'] ?? 'user',
          'account_type': user['account_type'],
          'plan':         user['plan'],
          'point_balance': user['point_balance'] ?? 0,
        },
      },
      'message': '로그인 성공',
    };
  }

  // ── 내 프로필 조회 — GET /auth/me ────────────────────────────
  // v2.9: avatar_url 포함 (v2.8에서 누락됐던 필드)
  static Map<String, dynamic> getMe(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);
    return {
      'success': true,
      'data': {
        'id':             user['id'],
        'email':          user['email'],
        'name':           user['name'],
        'role':           user['role'] ?? 'user',
        'account_type':   user['account_type'],
        'plan':           user['plan'],
        'plan_expires_at': null,
        'avatar_url':     user['avatar_url'],   // v2.9: 추가
        'is_verified':    user['is_verified'],
        'created_at':     user['created_at'],
        'point_balance':  user['point_balance'] ?? 0,
      },
    };
  }

  // ── 프로필 수정 — PATCH /auth/me ─────────────────────────────
  // v2.9 신규: name 변경 지원
  static Map<String, dynamic> updateProfile(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);
    if (body.containsKey('name')) {
      final name = body['name'] as String?;
      if (name == null || name.trim().isEmpty) {
        throw MockApiException('이름은 비워둘 수 없습니다.', 422);
      }
      user['name'] = name.trim();
    }

    return {
      'success': true,
      'data': {
        'id':           user['id'],
        'email':        user['email'],
        'name':         user['name'],
        'avatar_url':   user['avatar_url'],
        'plan':         user['plan'],
        'account_type': user['account_type'],
      },
      'message': '프로필이 수정되었습니다.',
    };
  }

  // ── 프로필 사진 업로드 — POST /auth/me/avatar ────────────────
  // v2.9 신규: multipart/form-data, field name = avatar
  // Mock: 실제 파일 처리 없이 더미 URL 반환
  static Map<String, dynamic> uploadAvatar(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);
    // Mock: Cloudflare R2 더미 URL 생성
    final dummyUrl =
        'https://pub-9e92c640989d47f69f8e3f749c4de9c0.r2.dev/avatars/user_${user['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    user['avatar_url'] = dummyUrl;

    return {
      'success': true,
      'data': {'avatar_url': dummyUrl},
      'message': '프로필 사진이 업로드되었습니다.',
    };
  }

  // ── 토큰 갱신 — POST /auth/refresh ──────────────────────────
  static Map<String, dynamic> refreshToken(String refreshToken) {
    final email = MockStore.refreshTokens[refreshToken];
    if (email == null) throw MockApiException('유효하지 않은 토큰입니다.', 401);

    MockStore.refreshTokens.remove(refreshToken);
    final newAccess  = 'mock-access-new-${DateTime.now().millisecondsSinceEpoch}';
    final newRefresh = 'mock-refresh-new-${DateTime.now().millisecondsSinceEpoch}';
    MockStore.accessTokens[newAccess]   = email;
    MockStore.refreshTokens[newRefresh] = email;

    return {
      'success': true,
      'data': {
        'access_token':  newAccess,
        'refresh_token': newRefresh,
        'token_type': 'Bearer',
      },
    };
  }

  // ── 웹 세션 원타임 토큰 — POST /auth/web-session-token ────────
  // 외부 브라우저 웹 충전 페이지 자동 로그인용 (서버 회신 2026-07-16 §C-2)
  // 1회용 · 5분 만료. 앱은 발급만 하고 교환은 웹이 수행.
  static int _webSessionTokenSeq = 0;

  static Map<String, dynamic> issueWebSessionToken(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    return {
      'success': true,
      'data': {
        'token': 'mock-ott-${++_webSessionTokenSeq}',
        'expires_in': 300,
      },
    };
  }

  // ── 로그아웃 — POST /auth/logout ─────────────────────────────
  static Map<String, dynamic> logout(String? accessToken) {
    if (accessToken != null) MockStore.accessTokens.remove(accessToken);
    return {'success': true, 'data': null, 'message': '로그아웃되었습니다.'};
  }

  // ── 초대링크 미리보기 — GET /groups/invite/:token ────────────
  // v2.8: 인증 불필요
  static Map<String, dynamic> invitePreview(String token) {
    if (token.isEmpty) {
      throw MockApiException('유효하지 않은 초대 링크입니다.', 404);
    }
    return {
      'success': true,
      'data': {
        'group_id':   1,
        'group_name': 'ELID 개발자 모임',
        'label':      '일반 초대',
        'max_uses':   100,
        'used_count': 3,
        'expires_at': null,
      },
    };
  }

  // ── 초대링크로 즉시 가입 — POST /auth/invite/:token/join ──────
  // v2.8: 토큰은 path param, body 불필요
  static Map<String, dynamic> inviteJoin(
      String accessToken, String token, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    if (token.isEmpty) {
      throw MockApiException('유효하지 않은 초대 링크입니다.', 404);
    }
    return {
      'success': true,
      'data': {'group_id': 1, 'group_name': 'ELID 개발자 모임'},
      'message': '그룹에 가입되었습니다.',
    };
  }
}
