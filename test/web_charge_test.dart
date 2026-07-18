import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/core/api/api_client.dart';
import 'package:meti_app/core/constants/app_constants.dart';
import 'package:meti_app/core/utils/charge_launcher.dart';

Future<void> _login() async {
  final api = ApiClient();
  final res = await api.post('/auth/login',
      body: {'email': 'test@meti.dev', 'password': 'MetiTest1234!'},
      auth: false);
  final data = res['data'] as Map<String, dynamic>;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(AppConstants.keyAccessToken, data['access_token']);
  await prefs.setString(AppConstants.keyRefreshToken, data['refresh_token']);
  await prefs.setInt(AppConstants.keyUserId, (data['user'] as Map)['id'] as int);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('웹 충전 OTT: 토큰 발급(1회용·5분) 응답 스펙', () async {
    await _login();
    final res = await ApiClient().post('/auth/web-session-token');
    expect(res['success'], true);
    final data = res['data'] as Map<String, dynamic>;
    expect(data['token'], isNotEmpty);
    expect(data['expires_in'], 300);
  });

  test('웹 충전 URI: /app/points + ott 파라미터 자동 부착', () async {
    await _login();
    final uri = await buildChargeUri();
    expect(uri.path, endsWith('/app/points'));
    expect(uri.queryParameters['ott'], startsWith('mock-ott'));
  });

  test('웹 충전 URI: 미로그인이면 ott 없이 폴백 (웹이 로그인 화면 처리)', () async {
    // 토큰 미저장 상태 → OTT 발급 401 → 파라미터 없는 기본 URL
    final uri = await buildChargeUri();
    expect(uri.path, endsWith('/app/points'));
    expect(uri.queryParameters.containsKey('ott'), false);
  });
}
