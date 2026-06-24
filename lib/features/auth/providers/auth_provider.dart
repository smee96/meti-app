import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ─── 앱 시작 시 로그인 상태 복구 ──────────────────────
  Future<void> checkAuthState() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
      final token = prefs.getString(AppConstants.keyAccessToken);

      if (!isLoggedIn || token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // 토큰으로 내 프로필 조회
      final response = await _api.get('/auth/me');
      if (response['success'] == true) {
        _user = UserModel.fromJson(response['data']);
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await _api.clearTokens();
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  // ─── 회원가입 ──────────────────────────────────────────
  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String name,
    String? birthDate, // YYYY-MM-DD — 만 19세 미만 차단(클라이언트 게이트)
  }) async {
    _setLoading();
    try {
      final response = await _api.post('/auth/register', body: {
        'email': email,
        'password': password,
        'name': name,
        if (birthDate != null) 'birth_date': birthDate,
        // v2.8: account_type 서버 자동 고정 — 클라이언트 전송 제거
      }, auth: false);

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return response['data'] as Map<String, dynamic>?;
    } on ApiException catch (e) {
      _setError(e.message);
      return null;
    }
  }

  // ─── 이메일 인증 ───────────────────────────────────────
  Future<bool> verifyEmail(String token) async {
    _setLoading();
    try {
      final response = await _api.post('/auth/verify-email',
        body: {'token': token}, auth: false);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return response['success'] == true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ─── 로그인 ────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final response = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      }, auth: false);

      final data = response['data'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(AppConstants.keyAccessToken, data['access_token']);
      await prefs.setString(AppConstants.keyRefreshToken, data['refresh_token']);
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);

      _user = UserModel.fromJson(data['user']);
      await prefs.setInt(AppConstants.keyUserId, _user!.id);
      await prefs.setString(AppConstants.keyUserEmail, _user!.email);
      await prefs.setString(AppConstants.keyUserName, _user!.name);
      await prefs.setString(AppConstants.keyUserPlan, _user!.plan);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ─── 로그아웃 ──────────────────────────────────────────
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(AppConstants.keyRefreshToken);
      await _api.post('/auth/logout', body: {
        if (refreshToken != null) 'refresh_token': refreshToken,
      });
    } catch (_) {}

    await _api.clearTokens();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ─── 비밀번호 재설정 요청 ──────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _setLoading();
    try {
      await _api.post('/auth/forgot-password',
        body: {'email': email}, auth: false);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ─── 비밀번호 재설정 ───────────────────────────────────
  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    _setLoading();
    try {
      await _api.post('/auth/reset-password', body: {
        'token': token,
        'password': password,
      }, auth: false);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ─── 내 프로필 새로고침 ────────────────────────────────
  Future<void> refreshProfile() async {
    try {
      final response = await _api.get('/auth/me');
      if (response['success'] == true) {
        _user = UserModel.fromJson(response['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─── 프로필 수정 — PATCH /auth/me (v2.9) ──────────────
  /// [name]: 변경할 이름 (null이면 변경 안 함)
  Future<bool> updateProfile({String? name}) async {
    if (name != null && name.trim().isEmpty) return false;
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name.trim();
      if (body.isEmpty) return true;

      final response = await _api.patch('/auth/me', body: body);
      if (response['success'] == true) {
        // 로컬 _user 즉시 반영
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null && _user != null) {
          _user = _user!.copyWith(
            name:      data['name']       as String? ?? _user!.name,
            avatarUrl: data['avatar_url'] as String? ?? _user!.avatarUrl,
          );
          // SharedPreferences 이름 동기화
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.keyUserName, _user!.name);
        }
        notifyListeners();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ─── 프로필 사진 업로드 — POST /auth/me/avatar (v2.9) ──
  /// [filePath]: 로컬 이미지 파일 경로 (image_picker 결과)
  Future<bool> uploadAvatar(String filePath) async {
    try {
      final response = await _api.uploadFile('/auth/me/avatar', filePath);
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        final newUrl = data?['avatar_url'] as String?;
        if (newUrl != null && _user != null) {
          _user = _user!.copyWith(avatarUrl: newUrl);
          notifyListeners();
        }
        return true;
      }
      return false;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
