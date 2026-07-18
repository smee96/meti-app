import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/core/api/api_client.dart';
import 'package:meti_app/core/constants/app_constants.dart';

Future<void> _login(String email, String password) async {
  final api = ApiClient();
  final res = await api.post('/auth/login',
      body: {'email': email, 'password': password}, auth: false);
  final data = res['data'] as Map<String, dynamic>;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(AppConstants.keyAccessToken, data['access_token']);
  await prefs.setString(AppConstants.keyRefreshToken, data['refresh_token']);
  await prefs.setInt(AppConstants.keyUserId, (data['user'] as Map)['id'] as int);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const shipping = {
    'shipping_name': '김프로',
    'shipping_phone': '010-2222-3333',
    'shipping_zipcode': '06134',
    'shipping_address': '서울 강남구 테헤란로 123',
  };

  test('NFC mock: config·시드 내역·포인트 부족 400', () async {
    await _login('test@meti.dev', 'MetiTest1234!');
    final api = ApiClient();

    // 가격 설정 조회
    final config = await api.get('/cards/nfc/config');
    expect((config['data'] as Map)['price'], 10000);

    // 시드: 명함 2 발급완료(운송장 포함) 내역 존재
    final apps = await api.get('/cards/nfc/applications');
    final seeded = (apps['data'] as List)
        .where((a) => a['card_id'] == 2 && a['status'] == 'issued');
    expect(seeded.length, 1);
    expect(seeded.first['tracking_no'], isNotNull);

    // test 계정 3,500P < 10,000P → 400 insufficient_points + shortage
    try {
      await api.post('/cards/nfc/apply',
          body: {'card_id': 1, ...shipping});
      fail('insufficient_points가 발생해야 합니다');
    } on ApiException catch (e) {
      expect(e.statusCode, 400);
      expect(e.errorCode, 'insufficient_points');
      expect(e.extra?['shortage'], 6500);
    }
  });

  test('NFC mock: 신청 성공(포인트 차감) 후 중복 신청 409', () async {
    await _login('pro@meti.dev', 'ProTest1234!');
    final api = ApiClient();

    // pro 계정 15,000P → 성공, balance_after 5,000
    final applied =
        await api.post('/cards/nfc/apply', body: {'card_id': 1, ...shipping});
    expect(applied['success'], true);
    expect((applied['data'] as Map)['balance_after'], 5000);

    // 신청 내역에 pending 반영
    final apps = await api.get('/cards/nfc/applications');
    expect((apps['data'] as List).first['status'], 'pending');

    // 같은 명함 재신청 → 409
    try {
      await api.post('/cards/nfc/apply', body: {'card_id': 1, ...shipping});
      fail('409가 발생해야 합니다');
    } on ApiException catch (e) {
      expect(e.statusCode, 409);
    }
  });
}
