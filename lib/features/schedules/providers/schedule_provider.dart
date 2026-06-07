// schedule_provider.dart — 레슨 일정 + 출석 상태 관리
// API: v1.7 스펙 기준
//   GET  /lessons/:groupId/schedules
//   POST /lessons/:groupId/schedules
//   GET  /lessons/:groupId/schedules/:id
//   POST /lessons/:groupId/schedules/:id/attendance
// v3.0 신규

import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // ── 상태 ────────────────────────────────────────────────────────
  final Map<int, List<LessonSchedule>> _schedulesByGroup = {};
  LessonSchedule? _selectedSchedule;
  List<AttendanceRecord> _attendances = [];

  bool    _isLoading     = false;
  bool    _isSubmitting  = false;
  String? _errorMessage;

  // ── getter ───────────────────────────────────────────────────────
  List<LessonSchedule> schedulesOf(int groupId) =>
      _schedulesByGroup[groupId] ?? [];

  LessonSchedule? get selectedSchedule => _selectedSchedule;
  List<AttendanceRecord> get attendances => _attendances;
  bool    get isLoading     => _isLoading;
  bool    get isSubmitting  => _isSubmitting;
  String? get errorMessage  => _errorMessage;

  // ── 일정 목록 — GET /lessons/:groupId/schedules ───────────────
  Future<void> loadSchedules(int groupId, {String? status}) async {
    _setLoading(true);
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;

      final res = await _api.get(
        '/lessons/$groupId/schedules',
        queryParams: params.isEmpty ? null : params,
      );
      if (res['success'] == true) {
        _schedulesByGroup[groupId] = (res['data'] as List)
            .map((e) => LessonSchedule.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ── 일정 상세 — GET /lessons/:groupId/schedules/:id ──────────
  Future<LessonSchedule?> loadScheduleDetail(int groupId, int scheduleId) async {
    _setLoading(true);
    try {
      final res = await _api.get('/lessons/$groupId/schedules/$scheduleId');
      if (res['success'] == true) {
        _selectedSchedule =
            LessonSchedule.fromJson(res['data'] as Map<String, dynamic>);
        notifyListeners();
        return _selectedSchedule;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    return null;
  }

  // ── 일정 생성 — POST /lessons/:groupId/schedules ─────────────
  Future<LessonSchedule?> createSchedule(int groupId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final res = await _api.post('/lessons/$groupId/schedules', body: data);
      if (res['success'] == true) {
        final newSchedule =
            LessonSchedule.fromJson(res['data'] as Map<String, dynamic>);
        _schedulesByGroup
            .putIfAbsent(groupId, () => [])
            .add(newSchedule);
        notifyListeners();
        return newSchedule;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
    return null;
  }

  // ── 출석 목록 — GET /lessons/:groupId/schedules/:id (detail에 포함) ─
  Future<void> loadAttendances(int groupId, int scheduleId) async {
    _setLoading(true);
    try {
      final res = await _api.get('/lessons/$groupId/schedules/$scheduleId');
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final raw = data['attendances'] as List? ?? [];
        _attendances = raw
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  // ── 출석 배치 처리 — POST /lessons/:groupId/schedules/:id/attendance ─
  Future<Map<String, dynamic>?> recordAttendances(
    int groupId,
    int scheduleId,
    List<AttendanceRecord> records,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _api.post(
        '/lessons/$groupId/schedules/$scheduleId/attendance',
        body: {'attendances': records.map((r) => r.toJson()).toList()},
      );
      if (res['success'] == true) {
        _attendances = List.from(records);
        if (_selectedSchedule?.id == scheduleId) {
          _selectedSchedule = LessonSchedule.fromJson({
            'id':               _selectedSchedule!.id,
            'group_id':         _selectedSchedule!.groupId,
            'instructor_id':    _selectedSchedule!.instructorId,
            'instructor_name':  _selectedSchedule!.instructorName,
            'title':            _selectedSchedule!.title,
            'description':      _selectedSchedule!.description,
            'scheduled_at':     _selectedSchedule!.scheduledAt,
            'duration_minutes': _selectedSchedule!.durationMinutes,
            'location':         _selectedSchedule!.location,
            'capacity':         _selectedSchedule!.capacity,
            'status':           'completed',
            'attendance_count':
                (res['data'] as Map<String, dynamic>?)?['attended'] ?? 0,
            'created_at':       _selectedSchedule!.createdAt,
          });
        }
        notifyListeners();
        return res['data'] as Map<String, dynamic>?;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
    return null;
  }

  // ── 출석 로컬 수정 ─────────────────────────────────────────────
  void updateAttendanceLocally(int studentId, String status, {String? note}) {
    final idx = _attendances.indexWhere((r) => r.studentId == studentId);
    if (idx != -1) {
      _attendances[idx] = _attendances[idx].copyWith(
        status: status,
        note: note ?? _attendances[idx].note,
      );
      notifyListeners();
    }
  }

  void clearSelected() {
    _selectedSchedule = null;
    _attendances = [];
    notifyListeners();
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
