import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/partner_service_model.dart';

/// 제휴 탭 상태 — 파트너 목록·launch-token 발급·B-2 잔액.
///
/// launch-token은 1회용(jti)·TTL 5분이라 상태로 보관하지 않는다.
/// 웹뷰를 열 때마다 [issueLaunchToken]으로 새로 발급받는다.
class PartnershipProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<PartnerService> _services = [];
  bool _loading = false;
  String? _error;

  List<PartnerService> get services => _services;
  bool get isLoading => _loading;
  String? get error => _error;

  /// B-2 잔액. 서버 프록시가 열리기 전까지는 항상 null(연동 준비 중).
  PartnerBalance? _balance;
  PartnerBalance? get balance => _balance;

  Future<void> loadServices() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/partner/services');
      final list = (res['data'] as List? ?? []);
      _services = list
          .map((e) => PartnerService.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = '제휴 서비스를 불러오지 못했습니다.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// SSO launch-token 발급. 실패 시 ApiException을 그대로 던진다 —
  /// 호출측(웹뷰 화면)이 재시도 UX를 책임진다.
  Future<PartnerLaunchTicket> issueLaunchToken(int serviceId) async {
    final res = await _api.post('/partner/services/$serviceId/launch-token');
    return PartnerLaunchTicket.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// B-2 잔액 조회 — 아직 연동 보류.
  ///
  /// 해피트리 잔액 API는 `X-HT-Partner-Key`(서버-서버 시크릿) 인증이라
  /// 앱이 직접 부를 수 없고 ELID 서버 프록시를 거쳐야 한다(확정 회신 v0.1 §2,
  /// ELID측 5~10초 캐시). 그 프록시는 해피트리 키 수령 후 서버가 구현한다
  /// (회신 v0.2 §5-3). 엔드포인트가 열리면 여기서 호출만 붙이면 된다.
  Future<void> loadBalance() async {
    _balance = null;
    notifyListeners();
  }
}
