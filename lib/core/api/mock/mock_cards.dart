// mock_cards.dart — 명함 관련 Mock API
// 포함: getCards, createCard, uploadCardAvatar
// v2.9 변경: 명함 한도 free=3 / pro=10 / business=무제한(null)
//            uploadCardAvatar (POST /cards/:id/avatar) 신규 추가

import 'mock_data.dart';

class MockCards {
  MockCards._();

  // ── 명함 목록 조회 — GET /cards ──────────────────────────────
  static Map<String, dynamic> getCards(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;
    final list   = MockStore.cards
        .where((c) => c['user_id'] == userId)
        .toList();

    return {
      'success': true,
      'data': List<Map<String, dynamic>>.from(list),
      'pagination': {
        'page': 1,
        'limit': 20,
        'total': list.length,
        'total_pages': 1,
        'has_next': false,
      },
    };
  }

  // ── 명함 생성 — POST /cards ───────────────────────────────────
  // v2.9: 플랜별 한도 free=3 / pro=10 / business=무제한
  // v2.9: tags[], sns_links[] 필드 지원
  static Map<String, dynamic> createCard(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final plan   = user['plan'] as String? ?? 'free';
    final userId = user['id'] as int;

    // v2.9: 플랜별 명함 한도 (v1.6 기준: free=3, pro=10, business=무제한)
    // -1 은 무제한을 의미
    const limits = {'free': 3, 'pro': 10, 'business': -1};
    final limit  = limits[plan] ?? 3;
    final userCardCount =
        MockStore.cards.where((c) => c['user_id'] == userId).length;

    if (limit != -1 && userCardCount >= limit) {
      throw MockApiException(
        '명함 생성 한도를 초과했습니다.',
        422,
        errorCode: 'card_limit_exceeded',
        upgradeRequired: true,
        extra: {
          'current':     userCardCount,
          'limit':       limit,
          'extra_price': 5000,
        },
      );
    }

    // tags[], sns_links[] 추출 (v2.9 API 형식)
    final tags     = (body['tags']     as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final snsLinks = (body['sns_links'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    final newCard = {
      'id':         DateTime.now().millisecondsSinceEpoch % 100000,
      'user_id':    userId,
      'group_id':   body['group_id'],
      'card_type':  body['card_type']  ?? 'personal',
      'name':       body['name']       ?? user['name'],
      'title':      body['title'],
      'company':    body['company'],
      'email':      body['email']      ?? user['email'],
      'phone':      body['phone'],
      'website':    body['website'],
      'bio':        body['bio'],
      'avatar_url': null,
      'template_id': body['template_id'] ?? 'modern_blue',
      'is_primary': MockStore.cards.where((c) => c['user_id'] == userId).isEmpty ? 1 : 0,
      'is_public':  body['is_public']  ?? 0,
      'is_active':  1,
      'tags':       tags,
      'sns_links':  snsLinks,
      'sns_count':  snsLinks.length,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    MockStore.cards.add(newCard);

    return {'success': true, 'data': newCard, 'message': '명함이 생성되었습니다.'};
  }

  // ── 명함 수정 — PATCH /cards/:id ────────────────────────────
  // v2.9: tags[], sns_links[] full-replace 방식
  static Map<String, dynamic> updateCard(
      String accessToken, int cardId, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final idx = MockStore.cards
        .indexWhere((c) => c['id'] == cardId && c['user_id'] == userId);
    if (idx == -1) throw MockApiException('명함을 찾을 수 없습니다.', 404);

    final card = Map<String, dynamic>.from(MockStore.cards[idx]);

    // 업데이트 가능한 필드만 반영
    const updatableFields = [
      'name', 'title', 'company', 'email', 'phone',
      'website', 'bio', 'template_id', 'is_public',
    ];
    for (final field in updatableFields) {
      if (body.containsKey(field)) card[field] = body[field];
    }

    // tags full-replace
    if (body.containsKey('tags')) {
      card['tags'] = (body['tags'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ?? [];
    }

    // sns_links full-replace
    if (body.containsKey('sns_links')) {
      final snsLinks = (body['sns_links'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ?? [];
      card['sns_links'] = snsLinks;
      card['sns_count'] = snsLinks.length;
    }

    card['updated_at'] = DateTime.now().toIso8601String();
    MockStore.cards[idx] = card;

    return {'success': true, 'data': card, 'message': '명함이 수정되었습니다.'};
  }

  // ── 명함 사진 업로드 — POST /cards/:id/avatar ────────────────
  // v2.9 신규: multipart/form-data, field name = avatar
  // Mock: 실제 파일 처리 없이 더미 URL 반환
  static Map<String, dynamic> uploadCardAvatar(
      String accessToken, int cardId) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;

    final idx = MockStore.cards
        .indexWhere((c) => c['id'] == cardId && c['user_id'] == userId);
    if (idx == -1) throw MockApiException('명함을 찾을 수 없습니다.', 404);

    // Mock: Cloudflare R2 더미 URL 생성
    final dummyUrl =
        'https://pub-9e92c640989d47f69f8e3f749c4de9c0.r2.dev/cards/card_${cardId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    MockStore.cards[idx] = Map<String, dynamic>.from(MockStore.cards[idx])
      ..['avatar_url'] = dummyUrl
      ..['updated_at'] = DateTime.now().toIso8601String();

    return {
      'success': true,
      'data': {'avatar_url': dummyUrl},
      'message': '명함 사진이 업로드되었습니다.',
    };
  }
}
