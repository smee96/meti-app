// ignore_for_file: deprecated_member_use
// schedule_detail_screen.dart — 레슨 일정 상세 + 출석 기록 화면
// 기능:
//   - 일정 정보 표시 (제목, 일시, 장소, 강사, 상태)
//   - 출석 목록 조회 (GET /schedules/:id/attendances)
//   - 출석 상태 편집 (체크박스 → present/absent/late/excused)
//   - 출석 일괄 저장 (PUT /schedules/:id/attendances)
// v3.0 신규

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final LessonSchedule schedule;

  const ScheduleDetailScreen({super.key, required this.schedule});

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  // 편집 중인 출석 목록 (로컬 복사본)
  List<AttendanceRecord> _editableAttendances = [];
  bool _isDirty = false;   // 변경 사항 있으면 true → 저장 버튼 활성화

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAttendances());
  }

  Future<void> _loadAttendances() async {
    final p = context.read<ScheduleProvider>();
    await p.loadAttendances(widget.schedule.id);
    if (!mounted) return;
    // Provider 목록을 로컬 편집용으로 복사
    setState(() {
      _editableAttendances = List.from(p.attendances);
      _isDirty = false;
    });
  }

  // ── 출석 상태 로컬 변경 ──────────────────────────────────────
  void _changeStatus(int studentId, String newStatus) {
    setState(() {
      final idx = _editableAttendances.indexWhere(
          (r) => r.studentId == studentId);
      if (idx != -1) {
        _editableAttendances[idx] =
            _editableAttendances[idx].copyWith(status: newStatus);
      }
      _isDirty = true;
    });
  }

  // ── 비고(note) 편집 다이얼로그 ──────────────────────────────
  Future<void> _editNote(AttendanceRecord record) async {
    final ctrl = TextEditingController(text: record.note ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${record.studentName} — 비고'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '예: 병결, 개인 사정 등',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                final idx = _editableAttendances
                    .indexWhere((r) => r.studentId == record.studentId);
                if (idx != -1) {
                  _editableAttendances[idx] = _editableAttendances[idx]
                      .copyWith(note: ctrl.text.trim().isEmpty
                          ? null
                          : ctrl.text.trim());
                }
                _isDirty = true;
              });
              Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  // ── 출석 일괄 저장 ──────────────────────────────────────────
  Future<void> _saveAttendances() async {
    final p = context.read<ScheduleProvider>();
    final summary = await p.recordAttendances(
      widget.schedule.id,
      _editableAttendances,
    );
    if (!mounted) return;
    if (summary != null) {
      setState(() => _isDirty = false);
      final attended = summary['attended'] as int? ?? 0;
      final total    = summary['total']    as int? ?? 0;
      showSuccessSnackBar(
          context, '출석이 저장되었습니다. ($attended/$total명 출석)');
    } else {
      showErrorSnackBar(context, p.errorMessage ?? '저장에 실패했습니다.');
    }
  }

  // ── 저장 전 확인 다이얼로그 ──────────────────────────────────
  Future<void> _confirmSave() async {
    final attendedCnt =
        _editableAttendances.where((r) => r.isAttended).length;
    final total = _editableAttendances.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('출석 저장'),
        content: Text(
          '총 $total명 중 $attendedCnt명 출석으로 저장합니다.\n\n'
          '저장 후 일정 상태가 "완료"로 변경됩니다.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('저장')),
        ],
      ),
    );
    if (confirmed == true && mounted) await _saveAttendances();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일정 상세'),
        actions: [
          // 출석 기록이 있고 변경 사항이 있을 때만 저장 버튼 표시
          if (_editableAttendances.isNotEmpty && _isDirty)
            Consumer<ScheduleProvider>(
              builder: (_, p, __) => p.isSubmitting
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                          child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textOnPrimary))),
                    )
                  : TextButton(
                      onPressed: _confirmSave,
                      child: const Text('저장',
                          style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.bold)),
                    ),
            ),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          return RefreshIndicator(
            onRefresh: _loadAttendances,
            child: CustomScrollView(
              slivers: [
                // ── 일정 정보 섹션 ──────────────────────────────
                SliverToBoxAdapter(
                  child: _ScheduleInfoCard(schedule: widget.schedule),
                ),

                // ── 출석 섹션 헤더 ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Text('출석 현황',
                            style: AppTextStyles.h4),
                        const SizedBox(width: 8),
                        if (_editableAttendances.isNotEmpty)
                          _AttendanceSummaryBadge(
                              attendances: _editableAttendances),
                        const Spacer(),
                        // 예정 상태일 때만 편집 안내 텍스트
                        if (widget.schedule.isScheduled &&
                            _editableAttendances.isNotEmpty)
                          Text('탭하여 상태 변경',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                ),

                // ── 출석 목록 ────────────────────────────────────
                if (_editableAttendances.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: EmptyStateWidget(
                        icon: Icons.how_to_reg_outlined,
                        title: '출석 기록이 없어요',
                        subtitle: '아래 버튼으로 학생을 추가하거나\n출석 기록을 시작하세요.',
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final record = _editableAttendances[i];
                        return _AttendanceRow(
                          record: record,
                          isEditable: !widget.schedule.isCancelled,
                          onStatusChanged: (s) =>
                              _changeStatus(record.studentId, s),
                          onNoteTap: () => _editNote(record),
                        );
                      },
                      childCount: _editableAttendances.length,
                    ),
                  ),

                // ── 하단 여백 ────────────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 일정 정보 카드
// ══════════════════════════════════════════════════════════════════
class _ScheduleInfoCard extends StatelessWidget {
  final LessonSchedule schedule;
  const _ScheduleInfoCard({required this.schedule});

  Color get _statusColor {
    switch (schedule.status) {
      case 'scheduled':  return AppColors.info;
      case 'completed':  return AppColors.success;
      case 'cancelled':  return AppColors.textTertiary;
      default:           return AppColors.textTertiary;
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('yyyy.MM.dd (E) HH:mm', 'ko').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(schedule.statusLabel,
                style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),

          // 제목
          Text(schedule.title,
              style: AppTextStyles.h3.copyWith(
                decoration: schedule.isCancelled
                    ? TextDecoration.lineThrough
                    : null,
                color: schedule.isCancelled ? AppColors.textTertiary : null,
              )),
          const SizedBox(height: 12),

          // 상세 정보 행들
          _InfoRow(
            icon: Icons.schedule,
            label: '시작',
            value: _formatDateTime(schedule.scheduledDateTime),
          ),
          _InfoRow(
            icon: Icons.timelapse,
            label: '소요',
            value: '${schedule.durationMinutes}분'
                '${schedule.endDateTime != null
                    ? "  (${DateFormat('HH:mm').format(schedule.endDateTime!)} 종료)"
                    : ""}',
          ),
          _InfoRow(
            icon: Icons.person_outline,
            label: '강사',
            value: schedule.instructorName,
          ),
          if (schedule.location != null)
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: '장소',
              value: schedule.location!,
            ),
          _InfoRow(
            icon: Icons.people_outline,
            label: '정원',
            value: '${schedule.capacity}명',
          ),
          if (schedule.description != null) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            Text(schedule.description!,
                style: AppTextStyles.body2
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: AppTextStyles.body2),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════
// 출석 요약 배지
// ══════════════════════════════════════════════════════════════════
class _AttendanceSummaryBadge extends StatelessWidget {
  final List<AttendanceRecord> attendances;
  const _AttendanceSummaryBadge({required this.attendances});

  @override
  Widget build(BuildContext context) {
    final attended = attendances.where((r) => r.isAttended).length;
    final total    = attendances.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$attended / $total명',
        style: const TextStyle(
            color: AppColors.success,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 출석 행 (한 학생)
// ══════════════════════════════════════════════════════════════════
class _AttendanceRow extends StatelessWidget {
  final AttendanceRecord record;
  final bool isEditable;
  final void Function(String status) onStatusChanged;
  final VoidCallback onNoteTap;

  const _AttendanceRow({
    required this.record,
    required this.isEditable,
    required this.onStatusChanged,
    required this.onNoteTap,
  });

  static const _statuses = ['present', 'late', 'excused', 'absent'];
  static const _statusLabels = {
    'present': '출석',
    'late':    '지각',
    'excused': '공결',
    'absent':  '결석',
  };
  static const _statusColors = {
    'present': AppColors.success,
    'late':    AppColors.warning,
    'excused': AppColors.info,
    'absent':  AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[record.status] ?? AppColors.textTertiary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // 아바타
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.12),
              backgroundImage: record.avatarUrl != null
                  ? NetworkImage(record.avatarUrl!)
                  : null,
              child: record.avatarUrl == null
                  ? Text(
                      record.studentName.isNotEmpty
                          ? record.studentName[0]
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // 이름 + 비고
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.studentName,
                      style: AppTextStyles.body2
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (record.note != null && record.note!.isNotEmpty)
                    Text(record.note!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),

            // 비고 편집 버튼
            if (isEditable)
              IconButton(
                onPressed: onNoteTap,
                icon: const Icon(Icons.edit_note,
                    size: 18, color: AppColors.textTertiary),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: '비고 편집',
              ),
            const SizedBox(width: 4),

            // 상태 선택 (세그먼트)
            if (isEditable)
              _StatusSegment(
                current: record.status,
                statuses: _statuses,
                labels: _statusLabels,
                colors: _statusColors,
                onChanged: onStatusChanged,
              )
            else
              // 읽기 전용 배지
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabels[record.status] ?? record.status,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 상태 세그먼트 버튼 (출석/지각/공결/결석) ────────────────────
class _StatusSegment extends StatelessWidget {
  final String current;
  final List<String> statuses;
  final Map<String, String> labels;
  final Map<String, Color> colors;
  final void Function(String) onChanged;

  const _StatusSegment({
    required this.current,
    required this.statuses,
    required this.labels,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: statuses.map((s) {
        final isSelected = current == s;
        final color      = colors[s] ?? AppColors.textTertiary;
        return GestureDetector(
          onTap: () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? color
                    : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              labels[s] ?? s,
              style: TextStyle(
                color: isSelected ? color : AppColors.textTertiary,
                fontSize: 10,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
