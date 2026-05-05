import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/card_model.dart';

class CardsProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<CardModel> _myCards = [];
  List<CardModel> _contacts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _errorCode;
  bool _upgradeRequired = false;

  List<CardModel> get myCards => _myCards;
  List<CardModel> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  bool get upgradeRequired => _upgradeRequired;

  // ─── 내 명함 목록 ──────────────────────────────────────
  Future<void> loadMyCards() async {
    _setLoading(true);
    try {
      final response = await _api.get('/cards');
      if (response['success'] == true) {
        _myCards = (response['data'] as List)
            .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ─── 명함 상세 조회 ────────────────────────────────────
  Future<CardModel?> getCardDetail(int cardId) async {
    try {
      final response = await _api.get('/cards/$cardId');
      if (response['success'] == true) {
        return CardModel.fromJson(response['data'] as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    return null;
  }

  // ─── 명함 생성 ─────────────────────────────────────────
  Future<CardModel?> createCard(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _api.post('/cards', body: data);
      if (response['success'] == true) {
        final card = CardModel.fromJson(response['data'] as Map<String, dynamic>);
        _myCards.insert(0, card);
        notifyListeners();
        return card;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _errorCode = e.errorCode;
      _upgradeRequired = e.upgradeRequired;
    } finally {
      _setLoading(false);
    }
    return null;
  }

  // ─── 명함 수정 ─────────────────────────────────────────
  Future<bool> updateCard(int cardId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _api.patch('/cards/$cardId', body: data);
      if (response['success'] == true) {
        await loadMyCards();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ─── 명함 삭제 ─────────────────────────────────────────
  Future<bool> deleteCard(int cardId) async {
    _setLoading(true);
    try {
      final response = await _api.delete('/cards/$cardId');
      if (response['success'] == true) {
        _myCards.removeWhere((c) => c.id == cardId);
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ─── QR 토큰 생성 ──────────────────────────────────────
  Future<Map<String, dynamic>?> generateQrToken(int cardId) async {
    try {
      final response = await _api.post('/cards/$cardId/qr-token');
      if (response['success'] == true) {
        return response['data'] as Map<String, dynamic>?;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    return null;
  }

  // ─── QR로 명함 조회 ────────────────────────────────────
  Future<CardModel?> getCardByQrToken(String token) async {
    try {
      final response = await _api.get('/cards/qr/$token', auth: false);
      if (response['success'] == true) {
        return CardModel.fromJson(response['data'] as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    return null;
  }

  // ─── 명함 저장 (명함첩) ────────────────────────────────
  Future<bool> saveCard(int cardId) async {
    try {
      final response = await _api.post('/cards/$cardId/save');
      return response['success'] == true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  // ─── 명함첩 목록 ───────────────────────────────────────
  Future<void> loadContacts({int page = 1}) async {
    _setLoading(true);
    try {
      final response = await _api.get('/cards/contacts/list',
          queryParams: {'page': page, 'limit': 20});
      if (response['success'] == true) {
        final list = (response['data'] as List)
            .map((e) => CardModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (page == 1) {
          _contacts = list;
        } else {
          _contacts.addAll(list);
        }
        notifyListeners();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    if (v) {
      _errorMessage = null;
      _errorCode = null;
      _upgradeRequired = false;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
