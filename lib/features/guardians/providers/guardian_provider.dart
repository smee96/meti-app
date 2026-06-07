// guardian_provider.dart — 보호자 연결 상태 관리
// API: v1.7 스펙 기준
//   GET  /guardians?role=mine|students
//   GET  /guardians/pending
//   POST /guardians/link
//   POST /guardians/link/:id/accept
//   POST /guardians/link/:id/reject
//   DELETE /guardians/:guardianUserId
// v3.0 신규

import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/guardian_model.dart';

class GuardianProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // ── 상태 ────────────────────────────────────────────────────────
  List<GuardianLink> _myGuardians = [];   // 내 보호자 목록 (학생 시점)
  List<GuardianLink> _myStudents  = [];   // 내 학생 목록  (보호자 시점)
  List<GuardianLink> _pending     = [];   // 대기 중인 연결 요청
  bool   _isLoading     = false;
  String? _errorMessage;

  // ── getter ───────────────────────────────────────────────────────
  List<GuardianLink> get myGuardians   => _myGuardians;
  List<GuardianLink> get myStudents    => _myStudents;
  List<GuardianLink> get pending       => _pending;
  bool   get isLoading     => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _pending.length;

  // ── 내 보호자 목록 — GET /guardians?role=mine ──────────────────
  Future<void> loadMyGuardians() async {
    _setLoading(true);
    try {
      final res = await _api.get('/guardians', queryParams: {'role': 'mine'});
      if (res['success'] == true) {
        _myGuardians = (res['data'] as List)
            .map((e) => GuardianLink.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ── 내 학생 목록 — GET /guardians?role=students ───────────────
  Future<void> loadMyStudents() async {
    _setLoading(true);
    try {
      final res = await _api.get('/guardians', queryParams: {'role': 'students'});
      if (res['success'] == true) {
        _myStudents = (res['data'] as List)
            .map((e) => GuardianLink.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ── 대기 중인 요청 — GET /guardians/pending ───────────────────
  Future<void> loadPending() async {
    _setLoading(true);
    try {
      final res = await _api.get('/guardians/pending');
      if (res['success'] == true) {
        _pending = (res['data'] as List)
            .map((e) => GuardianLink.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ── 보호자 연결 요청 — POST /guardians/link ───────────────────
  Future<bool> inviteGuardian({
    String? minorEmail,
    int? minorUserId,
    required String relation,
    int? groupId,
  }) async {
    _setLoading(true);
    try {
      final body = <String, dynamic>{'relation': relation};
      if (minorEmail != null) body['minor_email'] = minorEmail;
      if (minorUserId != null) body['minor_user_id'] = minorUserId;
      if (groupId != null) body['group_id'] = groupId;

      final res = await _api.post('/guardians/link', body: body);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>?;
        if (data != null) {
          _myStudents.add(GuardianLink.fromJson({
            'id':          data['id'],
            'relation':    data['relation'],
            'status':      data['status'],
            'invited_at':  data['invited_at'] ?? DateTime.now().toIso8601String(),
            'accepted_at': null,
          }));
        }
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

  // ── 연결 수락 — POST /guardians/link/:id/accept ───────────────
  Future<bool> acceptGuardian(int requestId) async {
    _setLoading(true);
    try {
      final res = await _api.post('/guardians/link/$requestId/accept');
      if (res['success'] == true) {
        _pending.removeWhere((l) => l.id == requestId);
        await loadMyGuardians();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ── 연결 거절 — POST /guardians/link/:id/reject ───────────────
  Future<bool> rejectGuardian(int requestId) async {
    _setLoading(true);
    try {
      final res = await _api.post('/guardians/link/$requestId/reject');
      if (res['success'] == true) {
        _pending.removeWhere((l) => l.id == requestId);
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

  // ── 연결 해제 — DELETE /guardians/:guardianUserId ─────────────
  Future<bool> removeGuardian(int guardianUserId) async {
    _setLoading(true);
    try {
      final res = await _api.delete('/guardians/$guardianUserId');
      if (res['success'] == true) {
        _myGuardians.removeWhere((l) => l.id == guardianUserId);
        _myStudents.removeWhere((l) => l.id == guardianUserId);
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

  // ── 내부 헬퍼 ────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    if (v) _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
