// schedule_provider.dart — 레슨 일정 + 출석 상태 관리
// API: GET/POST /schedules, GET /schedules/:id
//      GET/PUT /schedules/:id/attendances
// v3.0 신규

import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/schedule_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // ── 상태 ────────────────────────────────────────────────────────
  // groupId → 일정 목록 (탭 전환 시 빠른 재표시용 캐시)
  final Map<int, List<LessonSchedule>> _schedulesByGroup = {};

  LessonSchedule? _selectedSchedule;          // 상세 조회 결과
  List<AttendanceRecord> _attendances = [];   // 선택된 일정의 출석 목록

  bool    _isLoading     = false;
  bool    _isSubmitting  = false;             // 출석 기록 저장 중
  String? _errorMessage;

  // ── getter ───────────────────────────────────────────────────────
  List<LessonSchedule> schedulesOf(int groupId) =>
      _schedulesByGroup[groupId] ?? [];

  LessonSchedule? get selectedSchedule => _selectedSchedule;
  List<AttendanceRecord> get attendances => _attendances;
  bool    get isLoading     => _isLoading;
  bool    get isSubmitting  => _isSubmitting;
  String? get errorMessage  => _errorMessage;

  // ── 일정 목록 — GET /schedules?group_id=:gid ──────────────────
  Future<void> loadSchedules(int groupId, {String? status}) async {
    _setLoading(true);
    try {
      final res = await _api.get(
        '/schedules',
        queryParams: {
          'group_id': '$groupId',
          if (status != null) 'status': status,
        },
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

  // ── 일정 상세 — GET /schedules/:id ───────────────────────────
  Future<LessonSchedule?> loadScheduleDetail(int scheduleId) async {
    _setLoading(true);
    try {
      final res = await _api.get('/schedules/$scheduleId');
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

  // ── 일정 생성 — POST /schedules ──────────────────────────────
  Future<LessonSchedule?> createSchedule(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final res = await _api.post('/schedules', body: data);
      if (res['success'] == true) {
        final newSchedule =
            LessonSchedule.fromJson(res['data'] as Map<String, dynamic>);
        // 해당 그룹 캐시에 추가
        _schedulesByGroup
            .putIfAbsent(newSchedule.groupId, () => [])
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

  // ── 출석 목록 — GET /schedules/:id/attendances ───────────────
  Future<void> loadAttendances(int scheduleId) async {
    _setLoading(true);
    try {
      final res = await _api.get('/schedules/$scheduleId/attendances');
      if (res['success'] == true) {
        _attendances = (res['data'] as List)
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

  // ── 출석 일괄 기록 — PUT /schedules/:id/attendances ──────────
  /// [records]: AttendanceRecord 목록 (UI에서 편집된 상태)
  /// 반환: 서버 응답 summary Map (total, attended, absent 등) or null
  Future<Map<String, dynamic>?> recordAttendances(
    int scheduleId,
    List<AttendanceRecord> records,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _api.put(
        '/schedules/$scheduleId/attendances',
        body: {
          'attendances': records.map((r) => r.toJson()).toList(),
        },
      );
      if (res['success'] == true) {
        // 로컬 출석 목록 교체
        _attendances = List.from(records);
        // selectedSchedule 상태 → completed
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

  // ── 출석 로컬 수정 (UI에서 체크박스 변경 시) ──────────────────
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

  // ── 선택 초기화 ────────────────────────────────────────────────
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
