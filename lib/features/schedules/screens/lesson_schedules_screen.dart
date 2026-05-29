// ignore_for_file: deprecated_member_use
// lesson_schedules_screen.dart — 레슨 일정 목록 화면
// 탭: 전체 / 예정 / 완료
// 기능: 일정 목록 조회, 일정 생성 다이얼로그, 상세 이동
// v3.0 신규

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';
import 'schedule_detail_screen.dart';

class LessonSchedulesScreen extends StatefulWidget {
  final int groupId;
  final String groupName;

  const LessonSchedulesScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<LessonSchedulesScreen> createState() => _LessonSchedulesScreenState();
}

class _LessonSchedulesScreenState extends State<LessonSchedulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 탭별 status 필터: null=전체, 'scheduled', 'completed'
  static const _statusFilters = [null, 'scheduled', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _reload();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final status = _statusFilters[_tabController.index];
    await context
        .read<ScheduleProvider>()
        .loadSchedules(widget.groupId, status: status);
  }

  // ── 일정 생성 다이얼로그 ────────────────────────────────────────
  Future<void> _showCreateDialog() async {
    final titleCtrl    = TextEditingController();
    final locationCtrl = TextEditingController();
    final descCtrl     = TextEditingController();
    final formKey      = GlobalKey<FormState>();

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    int durationMin = 60;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('레슨 일정 등록'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: '일정 제목 *',
                      hintText: '예: 6월 1주차 수영 수업',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '제목을 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 12),

                  // 날짜 선택
                  _LabeledRow(
                    label: '날짜 *',
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        DateFormat('yyyy.MM.dd (E)', 'ko').format(selectedDate),
                        style: AppTextStyles.body2,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setDlg(() => selectedDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 시간 선택
                  _LabeledRow(
                    label: '시작 시간 *',
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(
                        selectedTime.format(ctx),
                        style: AppTextStyles.body2,
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) setDlg(() => selectedTime = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 소요 시간
                  _LabeledRow(
                    label: '소요 시간',
                    child: DropdownButton<int>(
                      value: durationMin,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 30,  child: Text('30분')),
                        DropdownMenuItem(value: 60,  child: Text('60분')),
                        DropdownMenuItem(value: 90,  child: Text('90분')),
                        DropdownMenuItem(value: 120, child: Text('120분')),
                      ],
                      onChanged: (v) => setDlg(() => durationMin = v ?? 60),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 장소 (선택)
                  TextFormField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                      labelText: '장소',
                      hintText: '예: 실내수영장 A레인',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 설명 (선택)
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '설명',
                      hintText: '수업 내용을 간략히 입력해주세요.',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                // ISO8601 조합
                final dt = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute,
                ).toUtc();

                Navigator.pop(ctx);
                await _doCreate({
                  'group_id':         widget.groupId,
                  'title':            titleCtrl.text.trim(),
                  'scheduled_at':     dt.toIso8601String(),
                  'duration_minutes': durationMin,
                  if (locationCtrl.text.trim().isNotEmpty)
                    'location': locationCtrl.text.trim(),
                  if (descCtrl.text.trim().isNotEmpty)
                    'description': descCtrl.text.trim(),
                });
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );

    titleCtrl.dispose();
    locationCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _doCreate(Map<String, dynamic> data) async {
    final p = context.read<ScheduleProvider>();
    final result = await p.createSchedule(data);
    if (!mounted) return;
    if (result != null) {
      showSuccessSnackBar(context, '레슨 일정이 등록되었습니다.');
      // 전체 탭(index=0)으로 이동 후 새로고침
      _tabController.animateTo(0);
      await context
          .read<ScheduleProvider>()
          .loadSchedules(widget.groupId);
    } else {
      showErrorSnackBar(context, p.errorMessage ?? '등록에 실패했습니다.');
    }
  }

  void _openDetail(LessonSchedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<ScheduleProvider>(),
          child: ScheduleDetailScreen(schedule: schedule),
        ),
      ),
    ).then((_) => _reload()); // 상세에서 출석 기록 후 돌아오면 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '예정'),
            Tab(text: '완료'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('일정 등록'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<ScheduleProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final schedules = provider.schedulesOf(widget.groupId);

          // 현재 탭 필터 적용 (캐시에서 클라이언트 측 재필터)
          final currentStatus = _statusFilters[_tabController.index];
          final filtered = currentStatus == null
              ? schedules
              : schedules
                  .where((s) => s.status == currentStatus)
                  .toList();

          if (filtered.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.calendar_month_outlined,
              title: '일정이 없어요',
              subtitle: currentStatus == 'scheduled'
                  ? '예정된 레슨 일정이 없습니다.'
                  : currentStatus == 'completed'
                      ? '완료된 레슨 일정이 없습니다.'
                      : '일정 등록 버튼을 눌러 추가해보세요.',
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ScheduleCard(
                schedule: filtered[i],
                onTap: () => _openDetail(filtered[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 일정 카드
// ══════════════════════════════════════════════════════════════════
class _ScheduleCard extends StatelessWidget {
  final LessonSchedule schedule;
  final VoidCallback onTap;

  const _ScheduleCard({required this.schedule, required this.onTap});

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
    return DateFormat('MM/dd (E) HH:mm', 'ko').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final dt = schedule.scheduledDateTime;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 배지 + 강사명
              Row(
                children: [
                  _StatusBadge(
                      label: schedule.statusLabel, color: _statusColor),
                  const Spacer(),
                  const Icon(Icons.person_outline,
                      size: 13, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(schedule.instructorName,
                      style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 8),

              // 제목
              Text(
                schedule.title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: schedule.isCancelled
                      ? TextDecoration.lineThrough
                      : null,
                  color: schedule.isCancelled
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              // 일시
              _IconRow(
                icon: Icons.schedule,
                text: _formatDateTime(dt),
              ),

              // 소요 시간
              _IconRow(
                icon: Icons.timelapse,
                text: '${schedule.durationMinutes}분',
              ),

              // 장소 (있을 때만)
              if (schedule.location != null)
                _IconRow(
                  icon: Icons.location_on_outlined,
                  text: schedule.location!,
                ),

              const SizedBox(height: 6),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 6),

              // 정원 + 출석 수
              Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 13, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text('정원 ${schedule.capacity}명',
                      style: AppTextStyles.caption),
                  if (schedule.isCompleted) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.check_circle_outline,
                        size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('출석 ${schedule.attendanceCount}명',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.success)),
                  ],
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 소형 공통 위젯 ────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textTertiary),
            const SizedBox(width: 5),
            Flexible(
                child: Text(text,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
}

class _LabeledRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
          child,
        ],
      );
}
