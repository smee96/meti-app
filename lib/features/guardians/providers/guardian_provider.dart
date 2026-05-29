// guardian_provider.dart — 보호자 연결 상태 관리
// API: /guardians/my-guardians, /guardians/my-students,
//      /guardians/invite, /guardians/:id/accept|reject|cancel|remove
// v3.0 신규

import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/guardian_model.dart';

class GuardianProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // ── 상태 ────────────────────────────────────────────────────────
  List<GuardianLink> _myGuardians = [];   // 내 보호자 목록 (학생 시점)
  List<GuardianLink> _myStudents  = [];   // 내 학생 목록  (보호자 시점)
  bool   _isLoading     = false;
  String? _errorMessage;

  // ── getter ───────────────────────────────────────────────────────
  List<GuardianLink> get myGuardians   => _myGuardians;
  List<GuardianLink> get myStudents    => _myStudents;
  bool   get isLoading     => _isLoading;
  String? get errorMessage => _errorMessage;

  /// pending 상태인 내 보호자 초대 건수 (배지 표시용)
  int get pendingGuardianCount =>
      _myGuardians.where((l) => l.isPending).length;

  // ── 내 보호자 목록 — GET /guardians/my-guardians ───────────────
  Future<void> loadMyGuardians() async {
    _setLoading(true);
    try {
      final res = await _api.get('/guardians/my-guardians');
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

  // ── 내 학생 목록 — GET /guardians/my-students ─────────────────
  Future<void> loadMyStudents() async {
    _setLoading(true);
    try {
      final res = await _api.get('/guardians/my-students');
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

  // ── 보호자 초대 — POST /guardians/invite ──────────────────────
  /// 반환: 성공 시 true, 실패 시 false (_errorMessage 설정됨)
  Future<bool> inviteGuardian({
    required String guardianEmail,
    required String relation,
  }) async {
    _setLoading(true);
    try {
      final res = await _api.post('/guardians/invite', body: {
        'guardian_email': guardianEmail,
        'relation':       relation,
      });
      if (res['success'] == true) {
        // 서버 응답의 새 링크를 목록에 즉시 추가
        final data = res['data'] as Map<String, dynamic>?;
        if (data != null) {
          _myGuardians.add(GuardianLink.fromJson({
            'id':         data['id'],
            'relation':   data['relation'],
            'status':     data['status'],
            'invited_at': data['invited_at'],
            'accepted_at': null,
            'guardian':   null,  // 수락 전에는 정보 없음
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

  // ── 초대 수락 — PUT /guardians/:id/accept ────────────────────
  Future<bool> acceptGuardian(int linkId) async {
    _setLoading(true);
    try {
      final res = await _api.put('/guardians/$linkId/accept');
      if (res['success'] == true) {
        // 로컬 상태 즉시 갱신
        final idx = _myStudents.indexWhere((l) => l.id == linkId);
        if (idx != -1) {
          // accepted 상태로 교체 — 전체 목록 재로드로 최신화
          await loadMyStudents();
        } else {
          await loadMyGuardians();
        }
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // ── 초대 거절 — PUT /guardians/:id/reject ────────────────────
  Future<bool> rejectGuardian(int linkId) async {
    _setLoading(true);
    try {
      final res = await _api.put('/guardians/$linkId/reject');
      if (res['success'] == true) {
        _myStudents.removeWhere((l) => l.id == linkId);
        _myGuardians.removeWhere((l) => l.id == linkId);
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

  // ── 초대 취소 — DELETE /guardians/:id/cancel ─────────────────
  // 초대를 보낸 학생(user_id)이 pending 상태 취소
  Future<bool> cancelGuardian(int linkId) async {
    _setLoading(true);
    try {
      final res = await _api.delete('/guardians/$linkId/cancel');
      if (res['success'] == true) {
        _myGuardians.removeWhere((l) => l.id == linkId);
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

  // ── 연결 삭제 — DELETE /guardians/:id ────────────────────────
  // accepted 상태의 연결을 완전 삭제 (학생/보호자 양쪽 가능)
  Future<bool> removeGuardian(int linkId) async {
    _setLoading(true);
    try {
      final res = await _api.delete('/guardians/$linkId');
      if (res['success'] == true) {
        _myGuardians.removeWhere((l) => l.id == linkId);
        _myStudents.removeWhere((l) => l.id == linkId);
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
