import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../models/event_model.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  List<Event> _events = [];
  bool _isLoading = false;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final statuses = [null, 'upcoming', 'ongoing'];
        setState(() => _statusFilter = statuses[_tabController.index]);
        _loadEvents();
      }
    });
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{'page': 1, 'limit': 20};
      if (_statusFilter != null) params['status'] = _statusFilter;
      // v2.6: /events (전체 공개 이벤트 피드)
      final response =
          await _api.get('/events', queryParams: params, auth: false);
      if (response['success'] == true) {
        final raw = response['data'] as List? ?? [];
        setState(() {
          _events = raw
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // 이벤트 참가 신청
  Future<void> _handleJoin(Event event) async {
    try {
      final res = await _api.post('/events/${event.id}/join');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '이벤트 참가 신청이 완료되었습니다!');
        _loadEvents();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.errorCode == 'insufficient_points') {
        showInsufficientPointsSnackBar(
          context,
          current: e.extra?['current'] as int?,
          required: e.extra?['required'] as int?,
          short: e.extra?['short'] as int?,
        );
      } else {
        showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  // 이벤트 참가 취소
  Future<void> _handleLeave(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('참가 취소'),
        content: Text('"${event.title}" 이벤트 참가를 취소하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('아니오')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final res = await _api.delete('/events/${event.id}/join');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '참가 신청이 취소되었습니다.');
        _loadEvents();
      }
    } on ApiException catch (e) {
      if (!mounted) showErrorSnackBar(context, e.message);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이벤트'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '예정'),
            Tab(text: '진행중'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _events.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.event_outlined,
                  title: '이벤트가 없어요',
                  subtitle: '새로운 이벤트를 기다려주세요!',
                )
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _EventCard(
                      event: _events[i],
                      onJoin: () => _handleJoin(_events[i]),
                      onLeave: () => _handleLeave(_events[i]),
                    ),
                  ),
                ),
    );
  }
}

// ── 이벤트 카드 (사용자용) ─────────────────────────────
class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _EventCard({
    required this.event,
    required this.onJoin,
    required this.onLeave,
  });

  Color get _statusColor {
    switch (event.status) {
      case 'upcoming':
        return AppColors.info;
      case 'ongoing':
        return AppColors.success;
      case 'ended':
        return AppColors.textTertiary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MM/dd HH:mm').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = event.isActive;
    final isFull   = event.isFull;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.isJoined && isActive
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: event.isJoined && isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 썸네일 영역
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.event,
                size: 36,
                color: _statusColor.withValues(alpha: 0.4),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 배지 행
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.statusLabel,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (event.isJoined && isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '참가중',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (isFull && isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '정원 마감',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    if (event.groupName != null) ...[
                      const Spacer(),
                      Text(event.groupName!, style: AppTextStyles.caption),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // 제목
                Text(event.title,
                    style: AppTextStyles.h4.copyWith(
                      decoration: event.isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                      color: event.isCancelled
                          ? AppColors.textTertiary
                          : null,
                    )),

                // 장소
                if (event.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(event.location!,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),

                // 일시 + 참가자
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(_formatDate(event.startsAt),
                        style: AppTextStyles.caption),
                    const Spacer(),
                    const Icon(Icons.people_outline,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      event.capacity != null
                          ? '${event.participantCount}/${event.capacity}명'
                          : '${event.participantCount}명',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),

                // 참가 신청 / 취소 버튼
                if (isActive) ...[
                  const SizedBox(height: 10),
                  event.isJoined
                      ? SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onLeave,
                            icon: const Icon(Icons.event_busy, size: 15),
                            label: const Text('참가 취소'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              foregroundColor: AppColors.error,
                              side:
                                  const BorderSide(color: AppColors.error),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isFull ? null : onJoin,
                            icon: const Icon(Icons.how_to_reg, size: 15),
                            label: Text(isFull ? '정원 마감' : '참가 신청'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
