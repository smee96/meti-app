// mock_payments.dart — 결제 + 포인트 + 상품 Mock API
// 포함:
//   포인트: getPointWallet, getGroupPointBalance, getPointTransactions,
//           transferPoints, joinEvent(포인트 차감 시뮬레이션)
//   상품:   getGroupProducts, createProduct, toggleProductActive
//   주문:   createOrder, getMyOrders, verifyWebPayment
//   구독:   verifySubscription, cancelSubscription
//   결제토큰: issuePaymentToken, verifyPaymentToken
//   충전상품: getPointChargeProducts

import 'mock_data.dart';

class MockPayments {
  MockPayments._();

  // ── 포인트 지갑 — GET /points/wallet ─────────────────────────
  // v2.8: expiring_soon 구조 포함
  static Map<String, dynamic> getPointWallet(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);
    return {
      'success': true,
      'data': {
        'balance': user['point_balance'] ?? 3500,
        // 서버 스펙: 7일 내 만료 예정 합계(숫자, 0=없음)
        'expiring_soon': 2000,
      },
    };
  }

  // ── 그룹 포인트 잔액 — GET /points/groups/:groupId/balance ────
  static Map<String, dynamic> getGroupPointBalance(int groupId) {
    final balance = MockStore.groupPointBalance[groupId] ?? 0;
    return {
      'success': true,
      'data': {
        'group_id':   groupId,
        'group_name': 'METI 개발자 모임',
        'balance':    balance,
      },
    };
  }

  // ── 포인트 거래내역 — GET /points/transactions ────────────────
  // v2.8 type: charge_subscription | charge_web | charge_admin
  //            use_event | use_admin | transfer_out | transfer_in
  // v2.8 point_type: subscription | charged | reward
  static Map<String, dynamic> getPointTransactions(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    return {
      'success': true,
      'data': [
        {
          'id': 1,
          'type': 'charge_subscription',
          'point_type': 'subscription',
          'amount': 10000,
          'balance_after': 10000,
          'ref_type': 'subscription',
          'ref_id': null,
          'description': 'Pro 플랜 구독 포인트 지급',
          'created_at': '2026-03-01T10:00:00Z',
        },
        {
          'id': 2,
          'type': 'charge_web',
          'point_type': 'charged',
          'amount': 5000,
          'balance_after': 15000,
          'ref_type': 'payment',
          'ref_id': 'pay_mock_001',
          'description': '포인트 직접 충전',
          'created_at': '2026-02-28T10:01:00Z',
        },
        {
          'id': 3,
          'type': 'charge_admin',
          'point_type': 'reward',
          'amount': 2000,
          'balance_after': 17000,
          'ref_type': null,
          'ref_id': null,
          'description': '행사 취소 환불 포인트',
          'created_at': '2026-04-15T14:30:00Z',
        },
        {
          'id': 4,
          'type': 'transfer_out',
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
          'type': 'use_event',
          'point_type': null,
          'amount': -13500,
          'balance_after': 3500,
          'ref_type': 'event',
          'ref_id': '10',
          'description': '그룹 명함 발급',
          'created_at': '2026-04-25T14:30:00Z',
        },
      ],
      'pagination': {
        'page': 1, 'limit': 20, 'total': 5, 'total_pages': 1, 'has_next': false,
      },
    };
  }

  // ── 개인 → 그룹 포인트 이체 — POST /points/transfer ──────────
  static Map<String, dynamic> transferPoints(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
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
        extra: {'required': amount, 'current': current, 'short': amount - current},
      );
    }
    user['point_balance'] = current - amount;

    return {
      'success': true,
      'data': {
        'transferred':            amount,
        'personal_balance_after': user['point_balance'],
      },
      'message': '${amount}P가 그룹으로 이체되었습니다.',
    };
  }

  // ── 행사 참가 포인트 차감 시뮬레이션 ────────────────────────
  // (그룹 포인트 3,000P 부족 시나리오 테스트용)
  static Map<String, dynamic> joinEvent(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);
    const required = 3000;
    final current  = (user['point_balance'] as int?) ?? 0;

    if (current < required) {
      throw MockApiException(
        '포인트가 부족합니다.',
        422,
        errorCode: 'insufficient_points',
        extra: {'required': required, 'current': current, 'short': required - current},
      );
    }
    user['point_balance'] = current - required;
    return {'success': true, 'data': null, 'message': '행사 참가 신청이 완료되었습니다.'};
  }

  // ── 그룹 상품 목록 — GET /groups/:id/products ────────────────
  static Map<String, dynamic> getGroupProducts(int groupId) {
    final list = List<Map<String, dynamic>>.from(
        MockStore.products[groupId] ?? []);
    return {
      'success': true,
      'data': list,
      'pagination': {
        'page': 1, 'limit': 20, 'total': list.length, 'has_next': false,
      },
    };
  }

  // ── 상품 생성 — POST /groups/:id/products ────────────────────
  static Map<String, dynamic> createProduct(
      String accessToken, int groupId, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    MockStore.productIdSeq++;
    final newProduct = {
      'id':          MockStore.productIdSeq,
      'group_id':    groupId,
      'name':        body['name']        ?? '새 상품',
      'description': body['description'],
      'type':        body['type']        ?? 'service',
      'price':       body['price']       ?? 0,
      'stock':       body['stock'],
      'sold_count':  0,
      'is_active':   true,
      'expires_at':  body['expires_at'],
      'image_url':   null,
      'created_by':  email,
      'created_at':  DateTime.now().toIso8601String(),
    };
    MockStore.products.putIfAbsent(groupId, () => []).add(newProduct);

    return {'success': true, 'data': newProduct, 'message': '상품이 등록되었습니다.'};
  }

  // ── 상품 활성/비활성 토글 ────────────────────────────────────
  static Map<String, dynamic> toggleProductActive(
      String accessToken, int productId, bool isActive) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    for (final list in MockStore.products.values) {
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

  // ── 주문 생성 — POST /orders ──────────────────────────────────
  // 포인트 결제: 즉시 차감 + 완료
  // 웹 결제: order 생성 후 WebView URL 반환
  static Map<String, dynamic> createOrder(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user          = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId        = user['id'] as int;
    final productId     = body['product_id']     as int?    ?? 0;
    final paymentMethod = body['payment_method'] as String? ?? 'points';

    Map<String, dynamic>? product;
    for (final list in MockStore.products.values) {
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
    MockStore.orderIdSeq++;
    final orderId = MockStore.orderIdSeq;

    if (paymentMethod == 'points') {
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
      if (stock != null) {
        for (final list in MockStore.products.values) {
          final idx = list.indexWhere((p) => p['id'] == productId);
          if (idx != -1) {
            list[idx] = Map<String, dynamic>.from(list[idx])
              ..['sold_count'] = sold + 1;
            break;
          }
        }
      }
      final order = {
        'id':              orderId,
        'product_id':      productId,
        'product_name':    product['name'],
        'amount':          price,
        'status':          'paid',
        'payment_method':  'points',
        'created_at':      DateTime.now().toIso8601String(),
        'web_payment_url': null,
      };
      MockStore.orders.putIfAbsent(userId, () => []).add(order);
      return {
        'success': true,
        'data': order,
        'message': '${price}P로 결제가 완료되었습니다.',
      };
    } else {
      final order = {
        'id':              orderId,
        'product_id':      productId,
        'product_name':    product['name'],
        'amount':          price,
        'status':          'pending',
        'payment_method':  'web_payment',
        'created_at':      DateTime.now().toIso8601String(),
        'web_payment_url':
            'https://the-meti.pages.dev/payment?order_id=$orderId',
      };
      MockStore.orders.putIfAbsent(userId, () => []).add(order);
      return {
        'success': true,
        'data': order,
        'message': '주문이 생성되었습니다. 결제 페이지로 이동합니다.',
      };
    }
  }

  // ── 주문 내역 조회 — GET /orders/mine ────────────────────────
  static Map<String, dynamic> getMyOrders(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user   = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId = user['id'] as int;
    final list   = List<Map<String, dynamic>>.from(
        MockStore.orders[userId] ?? []);
    list.sort((a, b) =>
        (b['created_at'] as String).compareTo(a['created_at'] as String));

    return {
      'success': true,
      'data': list,
      'pagination': {
        'page': 1, 'limit': 20, 'total': list.length, 'has_next': false,
      },
    };
  }

  // ── 웹 결제 완료 검증 — POST /payments/verify-web ────────────
  static Map<String, dynamic> verifyWebPayment(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user    = MockStore.users.firstWhere((u) => u['email'] == email);
    final userId  = user['id'] as int;
    final orderId = body['order_id'] as int? ?? 0;

    final orders = MockStore.orders[userId] ?? [];
    final idx    = orders.indexWhere((o) => o['id'] == orderId);
    if (idx == -1) throw MockApiException('주문을 찾을 수 없습니다.', 404);

    orders[idx] = Map<String, dynamic>.from(orders[idx])..['status'] = 'paid';

    // 재고 차감
    final productId = orders[idx]['product_id'] as int;
    for (final list in MockStore.products.values) {
      final pidx = list.indexWhere((p) => p['id'] == productId);
      if (pidx != -1) {
        final sold  = list[pidx]['sold_count'] as int? ?? 0;
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

  // ── 구독 영수증 검증 ──────────────────────────────────────────
  // v2.8: Apple IAP / Google Play 분기
  static Map<String, dynamic> verifySubscription(
      String accessToken, Map<String, dynamic> body,
      {String platform = 'apple'}) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);
    final plan = platform == 'google'
        ? _planFromProductId(body['product_id'] as String? ?? '')
        : (body['plan'] as String? ?? 'pro');

    const pointsMap = {'pro': 10000, 'business': 500000};
    final points    = pointsMap[plan] ?? 10000;

    user['plan'] = plan;
    final prev = (user['point_balance'] as int?) ?? 0;
    user['point_balance'] = prev + points;

    return {
      'success': true,
      'data': {
        'plan':           plan,
        'platform':       platform,
        'points_granted': points,
        'new_balance':    user['point_balance'],
        'expires_at':     DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
      },
      'message': '구독이 활성화되었습니다. ${points}P가 지급되었습니다.',
    };
  }

  static String _planFromProductId(String productId) {
    if (productId.contains('business')) return 'business';
    return 'pro';
  }

  // ── 구독 취소 — DELETE /payments/subscription ────────────────
  static Map<String, dynamic> cancelSubscription(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user = MockStore.users.firstWhere((u) => u['email'] == email);
    user['plan'] = 'free';
    return {
      'success': true,
      'data': null,
      'message': '구독이 취소되었습니다. 다음 결제일부터 Free 플랜으로 전환됩니다.',
    };
  }

  // ── 결제 토큰 발급 — POST /payments/payment-token ────────────
  // v2.7: 동일 order_id 재발급 시 이전 토큰 자동 무효화
  static Map<String, dynamic> issuePaymentToken(
      String accessToken, Map<String, dynamic> body) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    final user    = MockStore.users.firstWhere((u) => u['email'] == email);
    final orderId = body['order_id'] as int? ?? 0;
    if (orderId == 0) throw MockApiException('order_id가 필요합니다.', 422);

    MockStore.paymentTokens.removeWhere((_, v) => v['order_id'] == orderId);

    final token     = 'mock-pay-token-${user['id']}-${DateTime.now().millisecondsSinceEpoch}';
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));
    MockStore.paymentTokens[token] = {
      'token':      token,
      'user_id':    user['id'],
      'user_name':  user['name'],
      'user_email': user['email'],
      'order_id':   orderId,
      'expires_at': expiresAt.toIso8601String(),
      'is_used':    false,
    };

    return {
      'success': true,
      'data': {
        'token':       token,
        'expires_in':  300,
        'expires_at':  expiresAt.toIso8601String(),
        'payment_url': '/payment?token=$token',
      },
    };
  }

  // ── 결제 토큰 검증 — GET /payments/payment-token/verify ──────
  // v2.7: 검증 즉시 is_used=true — 재사용 불가
  static Map<String, dynamic> verifyPaymentToken(String token) {
    final data = MockStore.paymentTokens[token];
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
      MockStore.paymentTokens.remove(token);
      throw MockApiException('만료된 결제 토큰입니다.', 400,
          errorCode: 'token_expired');
    }
    MockStore.paymentTokens[token] =
        Map<String, dynamic>.from(data)..['is_used'] = true;

    final orderId = data['order_id'] as int;
    final userId  = data['user_id']  as int;
    final userOrders = MockStore.orders[userId] ?? [];
    final idx    = userOrders.indexWhere((o) => o['id'] == orderId);
    final order  = idx != -1 ? userOrders[idx] : null;

    return {
      'success': true,
      'data': {
        'user_id':      data['user_id'],
        'user_name':    data['user_name'],
        'user_email':   data['user_email'],
        'order_id':     orderId,
        'total_amount': order?['amount'] ?? 0,
        'order_status': order?['status'] ?? 'pending',
      },
    };
  }

  // ── 포인트 충전 상품 목록 — GET /payments/point-charge-products
  static Map<String, dynamic> getPointChargeProducts(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);

    return {
      'success': true,
      'data': List<Map<String, dynamic>>.from(MockStore.pointChargeProducts),
    };
  }
}
