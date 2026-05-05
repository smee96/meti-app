import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/point_model.dart';

class PointProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  PointWallet? _wallet;
  List<PointTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  PointWallet? get wallet => _wallet;
  List<PointTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get balance => _wallet?.balance ?? 0;

  // ─── 개인 지갑 조회 ───────────────────────────────────
  Future<void> loadWallet() async {
    _setLoading(true);
    try {
      final res = await _api.get('/points/me');
      if (res['success'] == true) {
        _wallet = PointWallet.fromJson(res['data'] as Map<String, dynamic>);
        _error = null;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '포인트 정보를 불러오는 중 오류가 발생했습니다.';
    } finally {
      _setLoading(false);
    }
  }

  // ─── 거래 내역 조회 ───────────────────────────────────
  Future<void> loadTransactions() async {
    try {
      final res = await _api.get('/points/me/transactions');
      if (res['success'] == true) {
        final list = res['data'] as List<dynamic>? ?? [];
        _transactions = list
            .map((e) => PointTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (_) {}
  }

  // ─── 그룹 지갑 조회 (어드민용) ───────────────────────
  Future<PointWallet?> loadGroupWallet(int groupId) async {
    try {
      final res = await _api.get('/points/groups/$groupId/wallet');
      if (res['success'] == true) {
        return PointWallet.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
