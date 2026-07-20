// mock_nfc.dart — NFC 실물카드 신청 Mock API (서버 스펙: ELID_Chat_Push_App_Handoff.md §5-2)
// 포함: getNfcConfig, applyNfc, getNfcApplications
// 정책:
//   - 결제는 포인트 차감 (IAP 비대상). 부족 시 400 insufficient_points → 외부 브라우저 충전 유도
//   - 같은 명함에 진행 중(pending/approved) 신청 있으면 409
//   - status: pending(신청됨) → approved(제작중) → issued(발급완료, 운송장 포함)

import 'mock_data.dart';

class MockNfc {
  MockNfc._();

  static const int price = 10000;

  static int applicationIdSeq = 10;

  // 신청 내역 시드: 명함 2(홍길동 공개)는 발급 완료 상태 — 상태 배지·운송장 표시 확인용
  static final List<Map<String, dynamic>> applications = [
    {
      'id': 1,
      'user_id': 1,
      'card_id': 2,
      'card_name': '홍길동 (공개)',
      'status': 'issued',
      'amount': 10000,
      'design_type': 'basic',
      'shipping_name': '홍길동',
      'shipping_phone': '010-1234-5678',
      'shipping_zipcode': '06134',
      'shipping_address': '서울 강남구 테헤란로 123',
      'shipping_detail': '5층',
      'tracking_no': '651234567890',
      'carrier': 'CJ대한통운',
      'created_at': '2026-07-01T10:00:00Z',
      'updated_at': '2026-07-08T15:30:00Z',
    },
  ];

  static Map<String, dynamic> _userFromToken(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    return MockStore.users.firstWhere((u) => u['email'] == email);
  }

  // ── GET /cards/nfc/config ────────────────────────────────────
  static Map<String, dynamic> getNfcConfig() {
    return {
      'success': true,
      'data': {'price': price, 'design_type': 'basic'},
    };
  }

  // ── POST /cards/nfc/apply ────────────────────────────────────
  static Map<String, dynamic> applyNfc(
      String accessToken, Map<String, dynamic> body) {
    final user = _userFromToken(accessToken);
    final userId = user['id'] as int;
    final cardId = body['card_id'] as int? ?? 0;

    // 필수 배송 정보 검증
    for (final field in [
      'shipping_name', 'shipping_phone', 'shipping_zipcode', 'shipping_address'
    ]) {
      final v = body[field] as String?;
      if (v == null || v.trim().isEmpty) {
        throw MockApiException('배송 정보를 모두 입력해주세요.', 422);
      }
    }
    if (cardId <= 0) throw MockApiException('명함을 선택해주세요.', 422);

    // 같은 명함에 진행 중 신청 있으면 409
    final inProgress = applications.any((a) =>
        a['card_id'] == cardId &&
        (a['status'] == 'pending' || a['status'] == 'approved'));
    if (inProgress) {
      throw MockApiException('이미 진행 중인 신청이 있습니다.', 409);
    }

    // 포인트 차감 (부족 시 400 insufficient_points)
    final balance = (user['point_balance'] as int?) ?? 0;
    if (balance < price) {
      throw MockApiException(
        '포인트가 부족합니다.',
        400,
        errorCode: 'insufficient_points',
        extra: {
          'required': price,
          'balance': balance,
          'shortage': price - balance,
        },
      );
    }
    user['point_balance'] = balance - price;

    String cardName = '명함';
    for (final c in MockStore.cards) {
      if (c['id'] == cardId) {
        cardName = c['name'] as String? ?? '명함';
        break;
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final application = {
      'id': ++applicationIdSeq,
      'user_id': userId,
      'card_id': cardId,
      'card_name': cardName,
      'status': 'pending',
      'amount': price,
      'design_type': 'basic',
      'shipping_name': body['shipping_name'],
      'shipping_phone': body['shipping_phone'],
      'shipping_zipcode': body['shipping_zipcode'],
      'shipping_address': body['shipping_address'],
      if (body['shipping_detail'] != null)
        'shipping_detail': body['shipping_detail'],
      if (body['shipping_memo'] != null)
        'shipping_memo': body['shipping_memo'],
      'tracking_no': null,
      'carrier': null,
      'created_at': now,
      'updated_at': now,
    };
    applications.add(application);

    return {
      'success': true,
      'data': {
        'application_id': application['id'],
        'amount': price,
        'balance_after': user['point_balance'],
      },
      'message': 'NFC 실물카드 신청이 완료되었습니다.',
    };
  }

  // ── GET /cards/nfc/applications ──────────────────────────────
  static Map<String, dynamic> getNfcApplications(String accessToken) {
    final user = _userFromToken(accessToken);
    final list = applications
        .where((a) => a['user_id'] == user['id'])
        .map(Map<String, dynamic>.from)
        .toList()
      ..sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
    return {
      'success': true,
      'data': list,
      'pagination': {
        'page': 1, 'limit': 20, 'total': list.length,
        'total_pages': 1, 'has_next': false,
      },
    };
  }
}
