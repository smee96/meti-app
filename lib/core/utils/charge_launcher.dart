import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../constants/app_constants.dart';

/// 포인트 충전 웹 페이지를 외부(시스템) 브라우저로 연다.
///
/// 포인트는 디지털 재화라 앱 안에서 현금 결제 시 IAP 의무 대상 —
/// 충전은 반드시 외부 브라우저의 웹 충전 페이지에서 진행한다. (핸드오프 §5-1)
///
/// 자동 로그인(서버 회신 2026-07-16 §C-2):
/// `POST /auth/web-session-token`으로 원타임 토큰(1회용·5분)을 발급받아
/// `?ott=` 파라미터로 전달하면 웹이 세션으로 교환한다.
/// 토큰 발급 실패 시 파라미터 없이 열어도 웹이 로그인 화면으로 폴백하므로
/// 앱은 실패 케이스를 별도 처리하지 않는다.
Future<Uri> buildChargeUri() async {
  final base = '${AppConfig.webBaseUrl}/app/points';
  try {
    final res = await ApiClient().post('/auth/web-session-token');
    final token = (res['data'] as Map?)?['token'] as String?;
    if (token != null && token.isNotEmpty) {
      return Uri.parse('$base?ott=$token');
    }
  } catch (_) {}
  return Uri.parse(base);
}

Future<bool> openExternalChargePage() async {
  final uri = await buildChargeUri();
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
