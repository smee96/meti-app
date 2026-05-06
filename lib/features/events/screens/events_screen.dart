import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  List<dynamic> _events = [];
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
      final response = await _api.get('/events', queryParams: params, auth: false);
      if (response['success'] == true) {
        setState(() => _events = response['data'] as List);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                    itemBuilder: (_, i) => _EventCard(event: _events[i]),
                  ),
                ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final dynamic event;
  const _EventCard({required this.event});

  Color get _statusColor {
    switch (event['status']) {
      case 'upcoming': return AppColors.info;
      case 'ongoing': return AppColors.success;
      case 'ended': return AppColors.textTertiary;
      default: return AppColors.textTertiary;
    }
  }

  String get _statusLabel {
    switch (event['status']) {
      case 'upcoming': return '예정';
      case 'ongoing': return '진행중';
      case 'ended': return '종료';
      default: return '';
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('MM/dd HH:mm', 'ko').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.event,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상태 + 그룹명
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (event['group_name'] != null) ...[
                      const SizedBox(width: 8),
                      Text(event['group_name'], style: AppTextStyles.caption),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(event['title'] ?? '', style: AppTextStyles.h4),
                if (event['location'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(event['location'], style: AppTextStyles.caption),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(_formatDate(event['starts_at'] as String?), style: AppTextStyles.caption),
                    const Spacer(),
                    const Icon(Icons.people_outline, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text('${event['participant_count'] ?? 0}명', style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 10),
                if (event['status'] == 'upcoming')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          final resp = await api.post('/events/${event['id']}/join');
                          if (context.mounted) {
                            if (resp['success'] == true) {
                              showSuccessSnackBar(context, '참가 신청이 완료되었습니다!');
                            }
                          }
                        } on ApiException catch (e) {
                          if (!context.mounted) return;
                          // v2.5: 포인트 부족 오류 — 충전 버튼 없이 잔액/부족 정보만 표시
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
                          if (context.mounted) {
                            showErrorSnackBar(context, e.toString());
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('참가 신청'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
