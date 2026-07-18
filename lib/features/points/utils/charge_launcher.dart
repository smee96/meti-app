import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

/// 포인트 충전 웹 페이지를 외부(시스템) 브라우저로 연다.
///
/// 포인트는 디지털 재화라 앱 안에서 현금 결제 시 IAP 의무 대상 —
/// 충전은 반드시 외부 브라우저의 웹 충전 페이지에서 진행한다. (핸드오프 §5-1)
/// TODO(충전 전환): POST /auth/web-session-token 원타임 토큰을 발급받아
/// `?ott=` 파라미터로 자동 로그인 연계 (서버 구현 완료 상태)
Future<bool> openExternalChargePage() {
  final url = Uri.parse('${AppConfig.webBaseUrl}/app/points');
  return launchUrl(url, mode: LaunchMode.externalApplication);
}
