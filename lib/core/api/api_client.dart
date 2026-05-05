import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'mock_api.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;        // 'card_limit_exceeded', 'plan_member_limit_reached' 등
  final bool upgradeRequired;     // true 시 업그레이드 다이얼로그 표시
  final Map<String, dynamic>? extra; // 추가 정보 (current, limit 등)

  ApiException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.upgradeRequired = false,
    this.extra,
  });

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  bool _isRefreshing = false;

  // ─── Tokens ───────────────────────────────────────────
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAccessToken);
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyRefreshToken);
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, accessToken);
    await prefs.setString(AppConstants.keyRefreshToken, refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAccessToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyIsLoggedIn);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserPlan);
  }

  // ─── Mock 분기 처리 ───────────────────────────────────
  Future<Map<String, dynamic>> _mockDispatch(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    // 약간의 지연으로 실제 API처럼 느끼게
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      // 인증이 필요한 경로는 토큰 확인
      String? accessToken;
      if (auth) {
        accessToken = await _getAccessToken();
        if (accessToken == null) {
          throw MockApiException('인증이 필요합니다.', 401);
        }
      }

      // ── POST 라우팅 ──
      if (method == 'POST') {
        if (path == '/auth/register') return MockUsers.register(body!);
        if (path == '/auth/verify-email') {
          return MockUsers.verifyEmail(body!['token'] as String);
        }
        if (path == '/auth/login') {
          return MockUsers.login(
            body!['email'] as String,
            body['password'] as String,
          );
        }
        if (path == '/auth/refresh') {
          return MockUsers.refreshToken(body!['refresh_token'] as String);
        }
        if (path == '/auth/logout') return MockUsers.logout(accessToken);
        if (path == '/auth/forgot-password') {
          return {
            'success': true,
            'data': {'reset_token': 'mock-reset-token-123'},
            'message': '비밀번호 재설정 이메일이 발송되었습니다.',
          };
        }
        if (path == '/auth/reset-password') {
          return {'success': true, 'data': null, 'message': '비밀번호가 변경되었습니다.'};
        }

        // 명함 생성 (v2.5: 플랜별 한도 체크)
        if (path == '/cards') {
          return MockUsers.createCard(accessToken!, body!);
        }

        // QR 토큰 생성
        if (path.endsWith('/qr-token')) {
          return {
            'success': true,
            'data': {
              'token': 'mock-qr-token-${DateTime.now().millisecondsSinceEpoch}',
              'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
              'qr_url': '/cards/qr/mock-qr-token',
            },
          };
        }

        // 명함 저장
        if (path.endsWith('/save')) {
          return {'success': true, 'data': null, 'message': '명함첩에 저장되었습니다.'};
        }

        // 그룹 가입 (v2.5: 플랜별 멤버 한도 체크)
        if (path.endsWith('/join') && path.startsWith('/groups')) {
          // /groups/:id/join 에서 groupId 추출
          final parts = path.split('/');
          final gid = int.tryParse(parts.length >= 3 ? parts[2] : '0') ?? 0;
          return MockUsers.joinGroup(accessToken!, gid, body ?? {});
        }

        // 이벤트 참가
        if (path.endsWith('/join') && path.startsWith('/events')) {
          return {'success': true, 'data': null, 'message': '참가 신청이 완료되었습니다.'};
        }

        // 채팅 메시지 전송
        if (path.endsWith('/messages')) {
          return {
            'success': true,
            'data': {
              'id': DateTime.now().millisecondsSinceEpoch % 100000,
              'room_id': 1,
              'sender_id': 1,
              'message_type': 'text',
              'content': body!['content'],
              'created_at': DateTime.now().toIso8601String(),
            },
          };
        }
      }

      // ── GET 라우팅 ──
      if (method == 'GET') {
        if (path == '/auth/me') return MockUsers.getMe(accessToken!);
        if (path == '/cards') return MockUsers.getCards();
        if (path == '/cards/contacts/list') {
          return {'success': true, 'data': [], 'pagination': {'page': 1, 'limit': 20, 'total': 0}};
        }
        if (path == '/groups') return _mockGroups();
        if (path == '/groups/me') return MockUsers.getMyGroups(accessToken!);
        if (path.startsWith('/groups/') && path.endsWith('/members')) {
          return {'success': true, 'data': _mockGroupMembers()};
        }
        if (path.startsWith('/groups/') && path.endsWith('/invite-links')) {
          return {'success': true, 'data': _mockInviteLinks()};
        }
        if (path == '/events') return _mockEvents();
        if (path == '/chat') return {'success': true, 'data': []};
        if (path.startsWith('/chat/') && path.endsWith('/messages')) {
          return {'success': true, 'data': []};
        }
        // 포인트 API
        if (path == '/points/me') return MockUsers.getPointWallet(accessToken!);
        if (path == '/points/me/transactions') return MockUsers.getPointTransactions(accessToken!);
        if (path.startsWith('/points/groups/') && path.endsWith('/wallet')) {
          return {
            'success': true,
            'data': {'balance': 0, 'total_earned': 0, 'total_spent': 0},
          };
        }
      }

      // ── PATCH 라우팅 ──
      if (method == 'PATCH') {
        if (path.startsWith('/cards/')) {
          return {'success': true, 'data': body, 'message': '명함이 수정되었습니다.'};
        }
      }

      // ── DELETE 라우팅 ──
      if (method == 'DELETE') {
        if (path.startsWith('/cards/')) {
          return {'success': true, 'data': null, 'message': '명함이 삭제되었습니다.'};
        }
        if (path.contains('/invite-links/')) {
          return {'success': true, 'data': null, 'message': '초대 링크가 삭제되었습니다.'};
        }
      }

      // ── 그룹 POST 라우팅 (멤버 승인/거절/내보내기, 초대링크 생성) ──
      if (method == 'POST') {
        if (path.contains('/members/') && path.endsWith('/approve')) {
          return {'success': true, 'data': null, 'message': '가입을 승인했습니다.'};
        }
        if (path.contains('/members/') && path.endsWith('/reject')) {
          return {'success': true, 'data': null, 'message': '가입 요청을 거절했습니다.'};
        }
        if (path.contains('/members/') && path.endsWith('/kick')) {
          return {'success': true, 'data': null, 'message': '멤버를 내보냈습니다.'};
        }
        if (path.endsWith('/invite-links')) {
          return {
            'success': true,
            'data': {
              'id': DateTime.now().millisecondsSinceEpoch % 10000,
              'token': 'mock-invite-${DateTime.now().millisecondsSinceEpoch}',
              'max_uses': body?['max_uses'] ?? 100,
              'use_count': 0,
              'is_active': true,
              'expires_at': body?['expires_at'],
              'created_at': DateTime.now().toIso8601String(),
            },
            'message': '초대 링크가 생성되었습니다.',
          };
        }
      }

      return {'success': true, 'data': null};
    } on MockApiException catch (e) {
      throw ApiException(
        e.message,
        statusCode: e.statusCode,
        errorCode: e.errorCode,
        upgradeRequired: e.upgradeRequired,
        extra: e.extra,
      );
    }
  }

  List<Map<String, dynamic>> _mockGroupMembers() => [
    {
      'id': 1, 'user_id': 1, 'name': '홍길동', 'email': 'test@meti.app',
      'role': 'admin', 'status': 'active',
      'joined_at': '2026-01-01T00:00:00Z',
    },
    {
      'id': 2, 'user_id': 2, 'name': '김철수', 'email': 'chulsoo@meti.app',
      'role': 'member', 'status': 'active',
      'joined_at': '2026-02-15T00:00:00Z',
    },
    {
      'id': 3, 'user_id': 3, 'name': '이영희', 'email': 'younghee@meti.app',
      'role': 'member', 'status': 'active',
      'joined_at': '2026-03-10T00:00:00Z',
    },
  ];

  List<Map<String, dynamic>> _mockInviteLinks() => [
    {
      'id': 1,
      'token': 'abc12345xyz',
      'max_uses': 50,
      'use_count': 7,
      'is_active': true,
      'expires_at': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
  ];

  Map<String, dynamic> _mockGroups() => {
    'success': true,
    'data': [
      {
        'id': 1, 'name': 'METI 개발자 모임', 'description': 'Flutter & Dart 개발자 커뮤니티',
        'category': 'club', 'visibility': 'public', 'status': 'active',
        'plan': 'free', 'member_count': 24, 'admin_name': '홍길동',
      },
      {
        'id': 2, 'name': '글로벌 비즈니스 네트워크', 'description': '해외 비즈니스 기회를 탐색하는 모임',
        'category': 'association', 'visibility': 'public', 'status': 'active',
        'plan': 'pro', 'member_count': 158, 'admin_name': 'John Kim',
      },
      {
        'id': 3, 'name': 'K-스타트업 커뮤니티', 'description': '스타트업 창업자들의 정보 공유',
        'category': 'club', 'visibility': 'public', 'status': 'active',
        'plan': 'free', 'member_count': 72, 'admin_name': '이창업',
      },
    ],
    'pagination': {'page': 1, 'limit': 20, 'total': 3, 'total_pages': 1, 'has_next': false},
  };

  Map<String, dynamic> _mockEvents() => {
    'success': true,
    'data': [
      {
        'id': 1, 'title': 'METI 네트워킹 밋업 2026', 'description': '글로벌 비즈니스 네트워킹 이벤트',
        'location': '서울 강남구 테헤란로', 'starts_at': '2026-06-15T18:00:00Z',
        'ends_at': '2026-06-15T21:00:00Z', 'status': 'upcoming',
        'visibility': 'public', 'registration_type': 'free',
        'group_name': 'METI 개발자 모임', 'organizer_name': '홍길동',
        'participant_count': 34, 'max_participants': 100,
      },
      {
        'id': 2, 'title': '비즈니스 카드 디자인 워크샵', 'description': '명함 디자인 실습 워크샵',
        'location': '서울 마포구', 'starts_at': '2026-05-20T14:00:00Z',
        'ends_at': '2026-05-20T17:00:00Z', 'status': 'upcoming',
        'visibility': 'public', 'registration_type': 'pre_required',
        'group_name': '글로벌 비즈니스 네트워크', 'organizer_name': 'John Kim',
        'participant_count': 12, 'max_participants': 30,
      },
      {
        'id': 3, 'title': '스타트업 피칭 데이', 'description': '투자자 대상 스타트업 발표 행사',
        'location': '판교 스타트업 캠퍼스', 'starts_at': '2026-04-10T10:00:00Z',
        'ends_at': '2026-04-10T18:00:00Z', 'status': 'ended',
        'visibility': 'public', 'registration_type': 'free',
        'group_name': 'K-스타트업 커뮤니티', 'organizer_name': '이창업',
        'participant_count': 89, 'max_participants': 100,
      },
    ],
    'pagination': {'page': 1, 'limit': 20, 'total': 3, 'total_pages': 1, 'has_next': false},
  };

  // ─── Headers ──────────────────────────────────────────
  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── Token Refresh ────────────────────────────────────
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      if (AppConstants.useMock) {
        final result = MockUsers.refreshToken(refreshToken);
        final data = result['data'] as Map<String, dynamic>;
        await _saveTokens(data['access_token'], data['refresh_token']);
        return true;
      }

      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _saveTokens(data['data']['access_token'], data['data']['refresh_token']);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // ─── Response Handler ─────────────────────────────────
  Future<Map<String, dynamic>> _handleResponse(
    http.Response response, {
    bool isRetry = false,
    Future<http.Response> Function()? retryRequest,
  }) async {
    if (response.statusCode == 401 && !isRetry) {
      final refreshed = await _refreshToken();
      if (refreshed && retryRequest != null) {
        final retried = await retryRequest();
        return _handleResponse(retried, isRetry: true);
      } else {
        await clearTokens();
        throw ApiException('인증이 만료되었습니다. 다시 로그인해주세요.', statusCode: 401);
      }
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    final errMsg = body['error'] ?? body['message'] ?? '알 수 없는 오류가 발생했습니다.';
    throw ApiException(errMsg.toString(), statusCode: response.statusCode);
  }

  // ─── Public HTTP Methods ──────────────────────────────
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool auth = true,
  }) async {
    if (AppConstants.useMock) return _mockDispatch('GET', path, auth: auth);

    final uri = Uri.parse('${AppConstants.baseUrl}$path').replace(
      queryParameters: queryParams?.map((k, v) => MapEntry(k, v.toString())),
    );
    final headers = await _getHeaders(auth: auth);
    final response = await _client.get(uri, headers: headers);
    return _handleResponse(response, retryRequest: () async {
      final h = await _getHeaders(auth: auth);
      return _client.get(uri, headers: h);
    });
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    if (AppConstants.useMock) return _mockDispatch('POST', path, body: body, auth: auth);

    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final headers = await _getHeaders(auth: auth);
    final response = await _client.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response, retryRequest: () async {
      final h = await _getHeaders(auth: auth);
      return _client.post(uri, headers: h, body: body != null ? jsonEncode(body) : null);
    });
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    if (AppConstants.useMock) return _mockDispatch('PATCH', path, body: body, auth: auth);

    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final headers = await _getHeaders(auth: auth);
    final response = await _client.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response, retryRequest: () async {
      final h = await _getHeaders(auth: auth);
      return _client.patch(uri, headers: h, body: body != null ? jsonEncode(body) : null);
    });
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    if (AppConstants.useMock) return _mockDispatch('DELETE', path, body: body, auth: auth);

    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final headers = await _getHeaders(auth: auth);
    final request = http.Request('DELETE', uri);
    request.headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response, retryRequest: () async {
      final h = await _getHeaders(auth: auth);
      final r = http.Request('DELETE', uri);
      r.headers.addAll(h);
      if (body != null) r.body = jsonEncode(body);
      return http.Response.fromStream(await _client.send(r));
    });
  }
}
