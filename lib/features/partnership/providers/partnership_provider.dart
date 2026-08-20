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

  /// B-2 잔액과 그 조회 상태.
  PartnerBalance? _balance;
  PartnerBalance? get balance => _balance;

  PartnerBalanceStatus _balanceStatus = PartnerBalanceStatus.idle;
  PartnerBalanceStatus get balanceStatus => _balanceStatus;

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

  /// B-2 잔액 조회 — `GET /partner/services/:id/balance`.
  ///
  /// 해피트리 잔액 API는 `X-HT-Partner-Key`(서버-서버 시크릿) 인증이라 앱이 직접
  /// 부를 수 없고 ELID 서버 프록시를 거친다(확정 회신 v0.1 §2, 서버측 10초 캐시).
  /// 그 프록시는 2026-08-08에 열렸다(회신 v0.2 §5-1).
  ///
  /// [loadServices] 이후에 불러야 한다 — 목록에서 해피트리 서비스 id를 찾는다.
  /// ⚠ `/services` 응답에 slug가 없어 지금은 이름으로 식별한다. 서버에 slug 추가를
  /// 요청해 두었고, 오면 그 값으로 바꾼다.
  Future<void> loadBalance() async {
    PartnerService? happytree;
    for (final s in _services) {
      if (s.name.contains('해피트리') || s.name.toLowerCase().contains('happytree')) {
        happytree = s;
        break;
      }
    }
    if (happytree == null) {
      _balance = null;
      _balanceStatus = PartnerBalanceStatus.idle;
      notifyListeners();
      return;
    }

    _balanceStatus = PartnerBalanceStatus.loading;
    notifyListeners();

    try {
      final res = await _api.get('/partner/services/${happytree.id}/balance');
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) {
        _balance = null;
        _balanceStatus = PartnerBalanceStatus.error;
      } else {
        _balance = PartnerBalance.fromJson(data);
        _balanceStatus = PartnerBalanceStatus.ok;
      }
    } on ApiException catch (e) {
      _balance = null;
      _balanceStatus = switch (e.statusCode) {
        // 아직 해피트리에 플레이어가 없다 — 첫 SSO 진입 전 (정상 상태)
        404 => PartnerBalanceStatus.notLinked,
        // prod 파트너 키 미설정 — 서버가 아직 조회를 못 한다
        503 => PartnerBalanceStatus.unavailable,
        // 잔액 조회를 지원하지 않는 파트너
        400 => PartnerBalanceStatus.idle,
        _ => PartnerBalanceStatus.error,
      };
    } catch (_) {
      _balance = null;
      _balanceStatus = PartnerBalanceStatus.error;
    }
    notifyListeners();
  }
}
