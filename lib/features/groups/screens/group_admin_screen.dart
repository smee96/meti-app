import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../points/models/point_model.dart';
import '../../lessons/models/lesson_model.dart';
import '../../events/models/event_model.dart';
import '../../products/models/product_model.dart';

/// 그룹 어드민 관리 화면
/// - 멤버 목록 / 승인대기 / 초대링크 관리
class GroupAdminScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupAdminScreen({super.key, required this.group});

  @override
  State<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends State<GroupAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();

  List<dynamic> _members = [];
  // 현재 로그인 유저의 이 그룹 내 역할 (admin 여부 판별용)
  bool _isCurrentUserAdmin = false;
  List<dynamic> _pending = [];
  List<dynamic> _inviteLinks = [];
  bool _isLoading = false;

  // M2: 그룹 포인트 잔액
  PointWallet? _groupWallet;
  bool _isWalletLoading = false;
  // M1: 포인트 이체 입력
  final _transferAmountCtrl = TextEditingController();
  bool _isTransferring = false;

  // v2.6: 레슨
  List<Lesson> _lessons = [];
  bool _isLessonsLoading = false;
  String _lessonStatusFilter = 'all'; // all | upcoming | ended | cancelled

  // v2.6: 이벤트
  List<Event> _events = [];
  bool _isEventsLoading = false;
  String _eventStatusFilter = 'all'; // all | upcoming | ongoing | ended | cancelled

  // v2.6: 상품
  List<Product> _products = [];
  bool _isProductsLoading = false;

  @override
  void initState() {
    super.initState();
    // v2.6: 탭 7개 (멤버/승인대기/초대링크/레슨/이벤트/상품/포인트)
    _tabController = TabController(length: 7, vsync: this);
    _loadAll();
    _loadGroupWallet();
    _loadLessons();
    _loadGroupEvents();
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transferAmountCtrl.dispose();
    super.dispose();
  }

  // v2.6: 상품 목록 로드
  Future<void> _loadProducts() async {
    final gid = widget.group['id'] as int?;
    if (gid == null) return;
    setState(() => _isProductsLoading = true);
    try {
      final res = await _api.get('/products/groups/$gid/products');
      if (res['success'] == true && mounted) {
        setState(() {
          _products = ((res['data'] as List?) ?? [])
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isProductsLoading = false);
  }

  // v2.6: 이벤트 목록 로드
  Future<void> _loadGroupEvents() async {
    final gid = widget.group['id'] as int?;
    if (gid == null) return;
    setState(() => _isEventsLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_eventStatusFilter != 'all') params['status'] = _eventStatusFilter;
      final res = await _api.get('/events/groups/$gid/events', queryParams: params);
      if (res['success'] == true && mounted) {
        setState(() {
          _events = ((res['data'] as List?) ?? [])
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isEventsLoading = false);
  }

  // v2.6: 레슨 목록 로드
  Future<void> _loadLessons() async {
    final gid = widget.group['id'] as int?;
    if (gid == null) return;
    setState(() => _isLessonsLoading = true);
    try {
      final params = <String, dynamic>{};
      if (_lessonStatusFilter != 'all') params['status'] = _lessonStatusFilter;
      final res = await _api.get('/lessons/groups/$gid/lessons',
          queryParams: params);
      if (res['success'] == true && mounted) {
        setState(() {
          _lessons = ((res['data'] as List?) ?? [])
              .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLessonsLoading = false);
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final gid = widget.group['id'];
    try {
      // 멤버 목록
      final mRes = await _api.get('/groups/$gid/members');
      if (mRes['success'] == true) {
        _members = (mRes['data'] as List?) ?? [];
        // 현재 유저가 admin인지 확인 (my_role 필드 또는 멤버 목록 기준)
        final myRole = widget.group['my_role'] as String?;
        _isCurrentUserAdmin = myRole == 'admin' || myRole == 'sub_admin';
      }
      // 승인 대기
      final pRes =
          await _api.get('/groups/$gid/members', queryParams: {'status': 'pending'});
      if (pRes['success'] == true) {
        _pending = (pRes['data'] as List?)
                ?.where((m) => m['status'] == 'pending')
                .toList() ??
            [];
      }
      // 초대 링크
      final lRes = await _api.get('/groups/$gid/invite-links');
      if (lRes['success'] == true) {
        _inviteLinks = (lRes['data'] as List?) ?? [];
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // M2: 그룹 지갑 로드
  Future<void> _loadGroupWallet() async {
    final gid = widget.group['id'] as int?;
    if (gid == null) return;
    setState(() => _isWalletLoading = true);
    try {
      final res = await _api.get('/points/groups/$gid/wallet');
      if (res['success'] == true && mounted) {
        setState(() {
          _groupWallet = PointWallet.fromJson(
              res['data'] as Map<String, dynamic>);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isWalletLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return Scaffold(
      appBar: AppBar(
        title: Text(group['name'] ?? '그룹 관리'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('멤버'),
                  if (_members.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _CountBadge(count: _members.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('승인대기'),
                  if (_pending.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _CountBadge(count: _pending.length, color: AppColors.warning),
                  ],
                ],
              ),
            ),
            const Tab(text: '초대링크'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('레슨'),
                  if (_lessons.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _CountBadge(count: _lessons.length, color: const Color(0xFF10B981)),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('이벤트'),
                  if (_events.isNotEmpty) ...[  
                    const SizedBox(width: 4),
                    _CountBadge(count: _events.length, color: const Color(0xFF6366F1)),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('상품'),
                  if (_products.isNotEmpty) ...[  
                    const SizedBox(width: 4),
                    _CountBadge(count: _products.length, color: const Color(0xFFEC4899)),
                  ],
                ],
              ),
            ),
            const Tab(text: '포인트'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildPendingTab(),
                _buildInviteLinksTab(),
                _buildLessonsTab(),
                _buildEventsTab(),
                _buildProductsTab(),
                _buildPointsTab(),
              ],
            ),
    );
  }

  // ── 멤버 탭 ────────────────────────────────────────────
  Widget _buildMembersTab() {
    // v2.5: 플랜별 멤버 한도 표시
    final maxLimit = widget.group['max_group_members'] as int?;
    final memberCount = _members.length;
    final isAtLimit = maxLimit != null && memberCount >= maxLimit;

    if (_members.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: '멤버가 없습니다',
        subtitle: '초대 링크를 공유해 멤버를 초대해보세요.',
      );
    }
    return Column(
      children: [
        // v2.5: 상단 멤버수/한도 표시
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isAtLimit
                ? AppColors.error.withValues(alpha: 0.06)
                : AppColors.primary.withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(
                color: isAtLimit
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAtLimit ? Icons.warning_amber_rounded : Icons.people,
                size: 16,
                color: isAtLimit ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                maxLimit != null
                    ? '현재 $memberCount명 / 최대 $maxLimit명'
                    : '현재 $memberCount명 (무제한)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isAtLimit ? AppColors.error : AppColors.primary,
                ),
              ),
              if (isAtLimit) ...[  
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '한도 도달',
                    style: TextStyle(
                      fontSize: 10, color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAll,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: memberCount,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _MemberTile(
                member: _members[i],
                isCurrentUserAdmin: _isCurrentUserAdmin,
                onKick: () => _handleKick(_members[i]),
                onRoleChange: (newRole) => _handleRoleChange(_members[i], newRole),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 승인 대기 탭 ───────────────────────────────────────
  Widget _buildPendingTab() {
    if (_pending.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.how_to_reg_outlined,
        title: '승인 대기 중인 요청이 없습니다',
        subtitle: '새 가입 신청이 들어오면 여기에 표시됩니다.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _PendingTile(
          member: _pending[i],
          onApprove: () => _handleApprove(_pending[i]),
          onReject: () => _handleReject(_pending[i]),
        ),
      ),
    );
  }

  // ── 초대 링크 탭 ───────────────────────────────────────
  Widget _buildInviteLinksTab() {
    return Column(
      children: [
        // 새 링크 생성 버튼
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _createInviteLink,
            icon: const Icon(Icons.add_link, size: 18),
            label: const Text('새 초대 링크 생성'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        // 링크 목록
        Expanded(
          child: _inviteLinks.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.link_off,
                  title: '초대 링크가 없습니다',
                  subtitle: '버튼을 눌러 초대 링크를 생성하세요.',
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _inviteLinks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _InviteLinkTile(
                      link: _inviteLinks[i],
                      onCopy: () => _copyLink(_inviteLinks[i]),
                      onDelete: () => _deleteLink(_inviteLinks[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── 레슨 탭 (v2.6) ────────────────────────────────────
  Widget _buildLessonsTab() {
    final gid = widget.group['id'] as int?;
    final canManage = _isCurrentUserAdmin ||
        (_members.any((m) =>
            m['role'] == 'instructor'));
    // 현재 로그인 유저가 instructor인지 (my_role 기준)
    final myRole = widget.group['my_role'] as String? ?? 'member';
    final canCreate = myRole == 'admin' ||
        myRole == 'sub_admin' ||
        myRole == 'instructor';

    return Column(
      children: [
        // 상단 필터 + 생성 버튼
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // 상태 필터 칩
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: '전체',
                        selected: _lessonStatusFilter == 'all',
                        onTap: () => _setLessonFilter('all'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '예정',
                        selected: _lessonStatusFilter == 'upcoming',
                        onTap: () => _setLessonFilter('upcoming'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '종료',
                        selected: _lessonStatusFilter == 'ended',
                        onTap: () => _setLessonFilter('ended'),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '취소됨',
                        selected: _lessonStatusFilter == 'cancelled',
                        onTap: () => _setLessonFilter('cancelled'),
                      ),
                    ],
                  ),
                ),
              ),
              if (canCreate) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreateLessonSheet(gid!),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('개설'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 0),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 레슨 목록
        Expanded(
          child: _isLessonsLoading
              ? const Center(child: CircularProgressIndicator())
              : _lessons.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.school_outlined,
                      title: '등록된 레슨이 없습니다',
                      subtitle: '개설 버튼을 눌러 첫 레슨을 만들어보세요.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLessons,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lessons.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _LessonCard(
                          lesson: _lessons[i],
                          canManage: canManage,
                          onRegister: () =>
                              _handleLessonRegister(_lessons[i]),
                          onCancel: () =>
                              _handleLessonCancel(_lessons[i]),
                          onCancelRegistration: () =>
                              _handleCancelLessonRegistration(_lessons[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  // ── 이벤트 탭 (v2.6) ──────────────────────────────────
  Widget _buildEventsTab() {
    final gid = widget.group['id'] as int?;
    final myRole = widget.group['my_role'] as String? ?? 'member';
    final canCreate = myRole == 'admin' || myRole == 'sub_admin';

    return Column(
      children: [
        // 상단 필터 + 생성 버튼
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: '전체',
                        selected: _eventStatusFilter == 'all',
                        onTap: () => _setEventFilter('all'),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '예정',
                        selected: _eventStatusFilter == 'upcoming',
                        onTap: () => _setEventFilter('upcoming'),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '진행중',
                        selected: _eventStatusFilter == 'ongoing',
                        onTap: () => _setEventFilter('ongoing'),
                        activeColor: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '종료',
                        selected: _eventStatusFilter == 'ended',
                        onTap: () => _setEventFilter('ended'),
                        activeColor: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
              ),
              if (canCreate) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreateEventSheet(gid!),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('개설'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 0),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 이벤트 목록
        Expanded(
          child: _isEventsLoading
              ? const Center(child: CircularProgressIndicator())
              : _events.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.event_outlined,
                      title: '등록된 이벤트가 없습니다',
                      subtitle: '개설 버튼을 눌러 첫 이벤트를 만들어보세요.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadGroupEvents,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _EventCard(
                          event: _events[i],
                          canManage: canCreate,
                          onJoin: () => _handleEventJoin(_events[i]),
                          onLeave: () => _handleEventLeave(_events[i]),
                          onCancel: () => _handleEventCancel(_events[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  void _setEventFilter(String filter) {
    setState(() => _eventStatusFilter = filter);
    _loadGroupEvents();
  }

  // 이벤트 개설 바텀시트
  Future<void> _showCreateEventSheet(int gid) async {
    final titleCtrl    = TextEditingController();
    final descCtrl     = TextEditingController();
    final locationCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '30');
    final startCtrl    = TextEditingController();
    final endCtrl      = TextEditingController();
    DateTime? selectedStart;
    DateTime? selectedEnd;

    Future<void> pickDate(
      BuildContext ctx,
      TextEditingController ctrl,
      DateTime? Function() getCurrent,
      void Function(DateTime) onPicked,
    ) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: ctx,
        initialDate: getCurrent() ?? now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      );
      if (picked == null || !ctx.mounted) return;
      final time = await showTimePicker(
        context: ctx,
        initialTime: const TimeOfDay(hour: 18, minute: 0),
      );
      if (time != null) {
        final dt = DateTime(picked.year, picked.month, picked.day,
            time.hour, time.minute);
        onPicked(dt);
        ctrl.text =
            '${picked.year}.${picked.month.toString().padLeft(2, '0')}.${picked.day.toString().padLeft(2, '0')} '
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.event_outlined,
                          color: Color(0xFF6366F1), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('이벤트 개설', style: AppTextStyles.h3),
                    const Spacer(),
                    // 비용 안내
                    StatefulBuilder(builder: (_, ss) {
                      final cap = int.tryParse(capacityCtrl.text) ?? 30;
                      final cost = cap <= 30 ? 1000 : cap <= 100 ? 3000 : 5000;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '그룹 포인트 ${_fmt(cost)}P',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '정원 ≤30: 1,000P  |  31-100: 3,000P  |  >100: 5,000P',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),

                // 제목
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '이벤트 제목 *',
                    hintText: '예: 여름 네트워킹 밋업',
                  ),
                ),
                const SizedBox(height: 12),

                // 장소
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: '장소',
                    hintText: '예: 강남 코워킹스페이스',
                  ),
                ),
                const SizedBox(height: 12),

                // 시작 일시
                TextField(
                  controller: startCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '시작 일시 *',
                    hintText: '날짜를 선택하세요',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => pickDate(
                        ctx, startCtrl,
                        () => selectedStart,
                        (dt) => setSheetState(() => selectedStart = dt),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 종료 일시 (선택)
                TextField(
                  controller: endCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '종료 일시 (선택)',
                    hintText: '날짜를 선택하세요',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () => pickDate(
                        ctx, endCtrl,
                        () => selectedEnd,
                        (dt) => setSheetState(() => selectedEnd = dt),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 정원
                TextField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    labelText: '최대 참가 인원 *',
                    suffixText: '명',
                    helperText: '정원에 따라 개설 비용이 달라집니다',
                  ),
                ),
                const SizedBox(height: 12),

                // 설명
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '이벤트 설명 (선택)',
                    hintText: '간단한 소개를 입력하세요',
                  ),
                ),
                const SizedBox(height: 20),

                // 개설 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        showErrorSnackBar(ctx, '이벤트 제목을 입력해주세요.');
                        return;
                      }
                      if (selectedStart == null) {
                        showErrorSnackBar(ctx, '시작 일시를 선택해주세요.');
                        return;
                      }
                      final cap =
                          int.tryParse(capacityCtrl.text.trim()) ?? 0;
                      if (cap <= 0) {
                        showErrorSnackBar(ctx, '최대 참가 인원을 올바르게 입력해주세요.');
                        return;
                      }
                      Navigator.pop(ctx);

                      try {
                        final res = await _api.post(
                          '/events/groups/$gid/events',
                          body: {
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            'location': locationCtrl.text.trim().isEmpty
                                ? null
                                : locationCtrl.text.trim(),
                            'starts_at': selectedStart!.toIso8601String(),
                            'ends_at': selectedEnd?.toIso8601String(),
                            'capacity': cap,
                            'visibility': 'public',
                            'registration_type': 'pre_required',
                            'entry_fee': 0,
                          },
                        );
                        if (!mounted) return;
                        if (res['success'] == true) {
                          showSuccessSnackBar(
                              context, res['message'] ?? '이벤트가 개설되었습니다.');
                          _loadGroupEvents();
                        }
                      } on ApiException catch (e) {
                        if (!mounted) return;
                        if (e.errorCode == 'insufficient_group_points') {
                          final extra = e.extra ?? {};
                          final cur = extra['current'] as int? ?? 0;
                          final req = extra['required'] as int? ?? 0;
                          showErrorSnackBar(
                            context,
                            '그룹 포인트 부족: 현재 ${_fmt(cur)}P / 필요 ${_fmt(req)}P\n'
                            '포인트 탭에서 개인 포인트를 이체해주세요.',
                          );
                        } else {
                          showErrorSnackBar(context, e.message);
                        }
                      } catch (_) {
                        if (mounted) {
                          showErrorSnackBar(context, '이벤트 개설 중 오류가 발생했습니다.');
                        }
                      }
                    },
                    child: const Text('이벤트 개설',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 이벤트 참가 신청
  Future<void> _handleEventJoin(Event event) async {
    try {
      final res = await _api.post('/events/${event.id}/join');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '이벤트 참가 신청이 완료되었습니다.');
        _loadGroupEvents();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.errorCode == 'insufficient_points') {
        final extra = e.extra ?? {};
        showInsufficientPointsSnackBar(
          context,
          current: extra['current'] as int?,
          required: extra['required'] as int?,
          short: extra['short'] as int?,
        );
      } else {
        showErrorSnackBar(context, e.message);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '오류가 발생했습니다.');
    }
  }

  // 이벤트 참가 취소
  Future<void> _handleEventLeave(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('참가 취소'),
        content: Text('"${event.title}" 참가를 취소하시겠습니까?'),
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
        showSuccessSnackBar(context, '이벤트 참가 신청이 취소되었습니다.');
        _loadGroupEvents();
      }
    } on ApiException catch (e) {
      if (!mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '오류가 발생했습니다.');
    }
  }

  // ── 상품 관리 탭 (v2.6) ───────────────────────────────
  Widget _buildProductsTab() {
    final gid = widget.group['id'] as int?;
    final myRole = widget.group['my_role'] as String? ?? 'member';
    final canManage = myRole == 'admin' || myRole == 'sub_admin';

    return Column(
      children: [
        // 상단 등록 버튼 (관리자만)
        if (canManage)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateProductSheet(gid!),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('상품 등록'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

        // 상품 목록
        Expanded(
          child: _isProductsLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.store_outlined,
                      title: '등록된 상품이 없습니다',
                      subtitle: '상품 등록 버튼을 눌러 첫 상품을 추가하세요.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.separated(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: canManage ? 0 : 16,
                          bottom: 16,
                        ),
                        itemCount: _products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ProductTile(
                          product: _products[i],
                          canManage: canManage,
                          onBuy: () => _handleBuyProduct(_products[i]),
                          onToggle: () =>
                              _handleToggleProduct(_products[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  // 상품 등록 바텀시트
  Future<void> _showCreateProductSheet(int gid) async {
    final nameCtrl  = TextEditingController();
    final descCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    String selectedType = 'service';
    bool hasExpiry = false;
    DateTime? expiresAt;
    final expiryCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.store_outlined,
                          color: Color(0xFFEC4899), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('상품 등록', style: AppTextStyles.h3),
                  ],
                ),
                const SizedBox(height: 20),

                // 상품명
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '상품명 *',
                    hintText: '예: 수영 강습 쿠폰 (10회)',
                  ),
                ),
                const SizedBox(height: 12),

                // 상품 유형
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: '상품 유형 *'),
                  items: const [
                    DropdownMenuItem(value: 'service',  child: Text('서비스')),
                    DropdownMenuItem(value: 'physical', child: Text('실물 상품')),
                    DropdownMenuItem(value: 'digital',  child: Text('디지털')),
                  ],
                  onChanged: (v) =>
                      setSheetState(() => selectedType = v ?? 'service'),
                ),
                const SizedBox(height: 12),

                // 가격
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '가격 *',
                    suffixText: 'P',
                    hintText: '포인트 단위',
                  ),
                ),
                const SizedBox(height: 12),

                // 재고 (null = 무제한)
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '재고',
                    hintText: '비워두면 무제한',
                    suffixText: '개',
                  ),
                ),
                const SizedBox(height: 12),

                // 유효기간 토글
                Row(
                  children: [
                    Switch(
                      value: hasExpiry,
                      activeThumbColor: const Color(0xFFEC4899),
                      onChanged: (v) => setSheetState(() {
                        hasExpiry = v;
                        if (!v) {
                          expiresAt = null;
                          expiryCtrl.clear();
                        }
                      }),
                    ),
                    const SizedBox(width: 8),
                    const Text('유효기간 설정',
                        style: TextStyle(fontSize: 14)),
                  ],
                ),
                if (hasExpiry) ...[
                  TextField(
                    controller: expiryCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: '만료일 *',
                      hintText: '날짜를 선택하세요',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate:
                                now.add(const Duration(days: 90)),
                            firstDate: now,
                            lastDate:
                                now.add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            setSheetState(() {
                              expiresAt = picked;
                              expiryCtrl.text =
                                  '${picked.year}.${picked.month.toString().padLeft(2, '0')}.${picked.day.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 설명
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '상품 설명 (선택)',
                    hintText: '간단한 상품 설명을 입력하세요',
                  ),
                ),
                const SizedBox(height: 20),

                // 등록 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        showErrorSnackBar(ctx, '상품명을 입력해주세요.');
                        return;
                      }
                      final price =
                          int.tryParse(priceCtrl.text.trim()) ?? -1;
                      if (price < 0) {
                        showErrorSnackBar(ctx, '가격을 올바르게 입력해주세요.');
                        return;
                      }
                      if (hasExpiry && expiresAt == null) {
                        showErrorSnackBar(ctx, '만료일을 선택해주세요.');
                        return;
                      }
                      Navigator.pop(ctx);

                      final stockVal =
                          int.tryParse(stockCtrl.text.trim());
                      try {
                        final res = await _api.post(
                          '/products/groups/$gid/products',
                          body: {
                            'name': nameCtrl.text.trim(),
                            'description':
                                descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                            'type': selectedType,
                            'price': price,
                            'stock': stockVal,
                            'expires_at': expiresAt?.toIso8601String(),
                          },
                        );
                        if (!mounted) return;
                        if (res['success'] == true) {
                          showSuccessSnackBar(
                              context, '상품이 등록되었습니다.');
                          _loadProducts();
                        }
                      } on ApiException catch (e) {
                        if (mounted) showErrorSnackBar(context, e.message);
                      } catch (_) {
                        if (mounted) {
                          showErrorSnackBar(
                              context, '상품 등록 중 오류가 발생했습니다.');
                        }
                      }
                    },
                    child: const Text('상품 등록',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 상품 구매 (포인트 결제)
  Future<void> _handleBuyProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('상품 구매'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              '${_fmt(product.price)}P로 결제됩니다.',
              style: const TextStyle(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('구매하기')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final res = await _api.post('/orders', body: {
        'product_id': product.id,
        'payment_method': 'points',
      });
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, res['message'] ?? '구매가 완료되었습니다.');
        _loadProducts();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.errorCode == 'insufficient_points') {
        final extra = e.extra ?? {};
        showInsufficientPointsSnackBar(
          context,
          current: extra['current'] as int?,
          required: extra['required'] as int?,
          short: extra['short'] as int?,
        );
      } else {
        showErrorSnackBar(context, e.message);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '오류가 발생했습니다.');
    }
  }

  // 상품 활성/비활성 토글
  Future<void> _handleToggleProduct(Product product) async {
    final newActive = !product.isActive;
    try {
      final res = await _api.patch(
        '/products/${product.id}/toggle',
        body: {'is_active': newActive},
      );
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(
            context, newActive ? '상품이 활성화되었습니다.' : '상품이 비활성화되었습니다.');
        _loadProducts();
      }
    } on ApiException catch (e) {
      if (mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '오류가 발생했습니다.');
    }
  }

  // 이벤트 취소 (관리자)
  Future<void> _handleEventCancel(Event event) async {
    final gid = widget.group['id'] as int?;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이벤트 취소'),
        content: Text(
            '"${event.title}" 이벤트를 취소하시겠습니까?\n포인트는 환불되지 않습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('아니오')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final res =
          await _api.delete('/events/groups/$gid/events/${event.id}');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '이벤트가 취소되었습니다.');
        _loadGroupEvents();
      }
    } on ApiException catch (e) {
      if (!mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '오류가 발생했습니다.');
    }
  }

  void _setLessonFilter(String filter) {
    setState(() => _lessonStatusFilter = filter);
    _loadLessons();
  }

  // 레슨 개설 바텀시트
  Future<void> _showCreateLessonSheet(int gid) async {
    final titleCtrl    = TextEditingController();
    final descCtrl     = TextEditingController();
    final locationCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '10');
    final dateCtrl     = TextEditingController();
    DateTime? selectedDate;

    // instructor 목록 (현재 멤버에서 instructor + admin/sub_admin 추출)
    final instructors = _members
        .where((m) => ['admin', 'sub_admin', 'instructor']
            .contains(m['role'] as String?))
        .toList();
    dynamic selectedInstructor =
        instructors.isNotEmpty ? instructors.first : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school_outlined,
                          color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('레슨 개설', style: AppTextStyles.h3),
                    const Spacer(),
                    // 비용 안내 배지
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '그룹 포인트 500P 차감',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 제목
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '레슨 제목 *',
                    hintText: '예: 수영 초급 클래스',
                  ),
                ),
                const SizedBox(height: 12),

                // 강사 선택
                DropdownButtonFormField<dynamic>(
                  initialValue: selectedInstructor,
                  decoration: const InputDecoration(labelText: '강사 *'),
                  items: instructors
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              '${m['name']} (${_roleLabel(m['role'] as String? ?? '')})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => selectedInstructor = v),
                ),
                const SizedBox(height: 12),

                // 일시 선택
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '레슨 일시 *',
                    hintText: '날짜를 선택하세요',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (picked == null || !ctx.mounted) return;
                        final time = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          selectedDate = DateTime(
                              picked.year, picked.month, picked.day,
                              time.hour, time.minute);
                          setSheetState(() {
                            dateCtrl.text =
                                '${picked.year}.${picked.month.toString().padLeft(2,'0')}.${picked.day.toString().padLeft(2,'0')} '
                                '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}';
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 장소
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: '장소',
                    hintText: '예: 실내수영장 A레인',
                  ),
                ),
                const SizedBox(height: 12),

                // 정원
                TextField(
                  controller: capacityCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: '정원 *', suffixText: '명'),
                ),
                const SizedBox(height: 12),

                // 설명
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '레슨 설명 (선택)',
                    hintText: '간단한 소개를 입력하세요',
                  ),
                ),
                const SizedBox(height: 20),

                // 개설 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) {
                        showErrorSnackBar(ctx, '레슨 제목을 입력해주세요.');
                        return;
                      }
                      if (selectedDate == null) {
                        showErrorSnackBar(ctx, '레슨 일시를 선택해주세요.');
                        return;
                      }
                      final capacity =
                          int.tryParse(capacityCtrl.text.trim()) ?? 0;
                      if (capacity <= 0) {
                        showErrorSnackBar(ctx, '정원을 올바르게 입력해주세요.');
                        return;
                      }
                      Navigator.pop(ctx);

                      try {
                        final res = await _api.post(
                          '/lessons/groups/$gid/lessons',
                          body: {
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            'instructor_id':
                                selectedInstructor?['user_id'] ?? 1,
                            'instructor_name':
                                selectedInstructor?['name'] ?? '',
                            'scheduled_at':
                                selectedDate!.toIso8601String(),
                            'duration_minutes': 60,
                            'capacity': capacity,
                            'location': locationCtrl.text.trim().isEmpty
                                ? null
                                : locationCtrl.text.trim(),
                            'schedule_type': 'one-time',
                          },
                        );
                        if (!mounted) return;
                        if (res['success'] == true) {
                          showSuccessSnackBar(
                              context,
                              res['message'] ??
                                  '레슨이 개설되었습니다.');
                          _loadLessons();
                        }
                      } on ApiException catch (e) {
                        if (!mounted) return;
                        if (e.errorCode == 'insufficient_group_points') {
                          final extra  = e.extra ?? {};
                          final cur    = extra['current'] as int? ?? 0;
                          final req    = extra['required'] as int? ?? 500;
                          showErrorSnackBar(
                            context,
                            '그룹 포인트 부족: 현재 ${_fmt(cur)}P / 필요 ${_fmt(req)}P\n'
                            '포인트 탭에서 개인 포인트를 이체해주세요.',
                          );
                        } else {
                          showErrorSnackBar(context, e.message);
                        }
                      } catch (e) {
                        if (mounted) {
                          showErrorSnackBar(context, '레슨 개설 중 오류가 발생했습니다.');
                        }
                      }
                    },
                    child: const Text('레슨 개설',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    const map = {
      'admin': '관리자', 'sub_admin': '부관리자',
      'instructor': '강사', 'member': '일반',
    };
    return map[role] ?? role;
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // 수강 신청
  Future<void> _handleLessonRegister(Lesson lesson) async {
    try {
      final res = await _api.post('/lessons/${lesson.id}/register');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '수강 신청이 완료되었습니다.');
        _loadLessons();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '오류가 발생했습니다.');
    }
  }

  // 수강 취소
  Future<void> _handleCancelLessonRegistration(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('수강 취소'),
        content: Text('"${lesson.title}" 수강 신청을 취소하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니오')),
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
      final res = await _api.delete('/lessons/${lesson.id}/register');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '수강 신청이 취소되었습니다.');
        _loadLessons();
      }
    } on ApiException catch (e) {
      if (!mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '오류가 발생했습니다.');
    }
  }

  // 레슨 취소 (관리자)
  Future<void> _handleLessonCancel(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('레슨 취소'),
        content: Text('"${lesson.title}" 레슨을 취소하시겠습니까?\n포인트는 환불되지 않습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니오')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final res = await _api.delete('/lessons/${lesson.id}');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '레슨이 취소되었습니다.');
        _loadLessons();
      }
    } on ApiException catch (e) {
      if (!mounted) showErrorSnackBar(context, e.message);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '오류가 발생했습니다.');
    }
  }

  // ── 포인트 탭 (M1 이체 + M2 그룹 잔액) ──────────────────
  Widget _buildPointsTab() {
    final gid = widget.group['id'];
    return RefreshIndicator(
      onRefresh: () async {
        await _loadGroupWallet();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // M2: 그룹 포인트 잔액 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.group['name'] ?? '그룹'} 포인트 잔액',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _loadGroupWallet,
                        child: const Icon(Icons.refresh,
                            color: Colors.white54, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isWalletLoading
                      ? const SizedBox(
                          height: 36,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          '${_formatNumber(_groupWallet?.balance ?? 0)} P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _WalletStatItem(
                        label: '총 적립',
                        value:
                            '${_formatNumber(_groupWallet?.totalEarned ?? 0)}P',
                      ),
                      const SizedBox(width: 24),
                      _WalletStatItem(
                        label: '총 사용',
                        value:
                            '${_formatNumber(_groupWallet?.totalSpent ?? 0)}P',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // M1: 포인트 이체 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.swap_horiz_rounded,
                            color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('포인트 이체', style: AppTextStyles.h4),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '개인 포인트를 그룹으로 이체합니다. (역방향 이체 불가)',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 16),

                  // 이체 금액 입력
                  TextField(
                    controller: _transferAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '이체할 포인트',
                      hintText: '예: 1000',
                      suffixText: 'P',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 빠른 금액 선택
                  Wrap(
                    spacing: 8,
                    children: [500, 1000, 3000, 5000].map((amt) {
                      return OutlinedButton(
                        onPressed: () {
                          _transferAmountCtrl.text = '$amt';
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: Text('+${_formatNumber(amt)}P'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 이체 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTransferring
                          ? null
                          : () => _handleTransfer(gid),
                      icon: _isTransferring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_isTransferring ? '이체 중...' : '그룹으로 이체'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 안내 박스
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '• 이체는 관리자만 가능합니다\n'
                '• 이체 후 역방향(그룹→개인) 환불은 불가합니다\n'
                '• 그룹 포인트는 행사 개설 등에 사용됩니다',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // M1: 이체 처리
  Future<void> _handleTransfer(dynamic gid) async {
    final amountText = _transferAmountCtrl.text.trim();
    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showErrorSnackBar(context, '올바른 이체 금액을 입력해주세요.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('포인트 이체 확인'),
        content: Text(
          '개인 포인트에서 ${_formatNumber(amount)}P를\n'
          '"${widget.group['name'] ?? '그룹'}"으로 이체하시겠습니까?\n\n'
          '이체 후 역방향 환불은 불가합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('이체하기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isTransferring = true);
    try {
      final res = await _api.post('/points/transfer', body: {
        'group_id': gid,
        'amount': amount,
      });
      if (!mounted) return;
      if (res['success'] == true) {
        _transferAmountCtrl.clear();
        showSuccessSnackBar(context,
            res['message'] ?? '${_formatNumber(amount)}P 이체 완료');
        // 그룹 잔액 새로고침
        await _loadGroupWallet();
      } else {
        showErrorSnackBar(context, res['message']?.toString() ?? '이체 실패');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.errorCode == 'insufficient_points') {
        final extra = e.extra ?? {};
        final current = extra['current'] as int? ?? 0;
        final short = extra['short'] as int? ?? 0;
        showErrorSnackBar(
          context,
          '포인트 부족: 현재 ${_formatNumber(current)}P · ${_formatNumber(short)}P 부족',
        );
      } else {
        showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '이체 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  // ── 역할 변경 (v2.6) ─────────────────────────────────
  Future<void> _handleRoleChange(dynamic member, String newRole) async {
    final gid = widget.group['id'];
    final mid = member['user_id'] ?? member['id'];
    final name = member['name'] as String? ?? '멤버';

    final roleLabel = {
      'sub_admin': '부관리자',
      'instructor': '강사',
      'member': '일반 멤버',
    }[newRole] ?? newRole;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('역할 변경'),
        content: Text('$name 님의 역할을 "$roleLabel"(으)로 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('변경'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final res = await _api.patch(
        '/groups/$gid/members/$mid/role',
        body: {'role': newRole},
      );
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '$name 님의 역할이 $roleLabel(으)로 변경되었습니다.');
        _loadAll();
      } else {
        showErrorSnackBar(context, res['message']?.toString() ?? '역할 변경 실패');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  // ── 액션 핸들러 ────────────────────────────────────────
  Future<void> _handleApprove(dynamic member) async {
    final gid = widget.group['id'];
    final mid = member['id'] ?? member['user_id'];
    try {
      final res = await _api.post('/groups/$gid/members/$mid/approve');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '가입을 승인했습니다.');
        _loadAll();
      } else {
        showErrorSnackBar(context, res['message']?.toString() ?? '승인 실패');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _handleReject(dynamic member) async {
    final gid = widget.group['id'];
    final mid = member['id'] ?? member['user_id'];
    try {
      final res = await _api.post('/groups/$gid/members/$mid/reject');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '가입 요청을 거절했습니다.');
        _loadAll();
      } else {
        showErrorSnackBar(context, res['message']?.toString() ?? '거절 실패');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _handleKick(dynamic member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('멤버 내보내기'),
        content: Text('${member['name'] ?? '해당 멤버'}를 그룹에서 내보내시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final gid = widget.group['id'];
    final mid = member['id'] ?? member['user_id'];
    try {
      final res = await _api.post('/groups/$gid/members/$mid/kick');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '멤버를 내보냈습니다.');
        _loadAll();
      } else {
        showErrorSnackBar(context, res['message']?.toString() ?? '처리 실패');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _createInviteLink() async {
    final gid = widget.group['id'];
    // 만료 기간 선택 다이얼로그
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('링크 유효 기간'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 1),
            child: const Text('1일'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 7),
            child: const Text('7일'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 30),
            child: const Text('30일'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('만료 없음'),
          ),
        ],
      ),
    );
    if (days == null) return;
    if (!mounted) return;
    try {
      final body = <String, dynamic>{'max_uses': 100};
      if (days > 0) {
        body['expires_at'] = DateTime.now()
            .add(Duration(days: days))
            .toIso8601String();
      }
      final res = await _api.post('/groups/$gid/invite-links', body: body);
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '초대 링크가 생성되었습니다.');
        _loadAll();
      } else {
        showErrorSnackBar(context, res['message']?.toString() ?? '생성 실패');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }

  Future<void> _copyLink(dynamic link) async {
    final token = link['token'] as String? ?? '';
    final url = 'https://the-meti.pages.dev/app/invite/$token';
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) showSuccessSnackBar(context, '초대 링크가 복사되었습니다.');
  }

  Future<void> _deleteLink(dynamic link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('링크 삭제'),
        content: const Text('이 초대 링크를 삭제하시겠습니까?\n삭제 후에는 해당 링크로 가입이 불가합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final gid = widget.group['id'];
    final lid = link['id'];
    try {
      final res = await _api.delete('/groups/$gid/invite-links/$lid');
      if (!mounted) return;
      if (res['success'] == true) {
        showSuccessSnackBar(context, '초대 링크가 삭제되었습니다.');
        _loadAll();
      } else {
        showErrorSnackBar(context, res['message']?.toString() ?? '삭제 실패');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString());
    }
  }
}

// ── 멤버 타일 (v2.6: instructor 역할 + 역할 변경) ───────
class _MemberTile extends StatelessWidget {
  final dynamic member;
  final bool isCurrentUserAdmin;     // 현재 로그인 유저가 admin인지
  final VoidCallback onKick;
  final void Function(String newRole) onRoleChange;

  const _MemberTile({
    required this.member,
    required this.isCurrentUserAdmin,
    required this.onKick,
    required this.onRoleChange,
  });

  // 역할별 배지 색상·레이블
  static const _roleConfig = {
    'admin':      {'label': '관리자',   'color': 0xFFF59E0B},  // warning
    'owner':      {'label': '관리자',   'color': 0xFFF59E0B},
    'sub_admin':  {'label': '부관리자', 'color': 0xFF6366F1},  // indigo
    'instructor': {'label': '강사',    'color': 0xFF10B981},  // green
    'member':     {'label': '',        'color': 0x00000000},
  };

  @override
  Widget build(BuildContext context) {
    final role = member['role'] as String? ?? 'member';
    final isAdmin   = role == 'admin' || role == 'owner';
    final isFixed   = isAdmin;          // admin은 역할 변경/내보내기 불가
    final name      = member['name']  as String? ?? '알 수 없음';
    final email     = member['email'] as String? ?? '';
    final joinedAt  = member['joined_at'] as String?;
    final config    = _roleConfig[role];
    final roleLabel = config?['label'] as String? ?? '';
    final roleColor = Color(config?['color'] as int? ?? 0x00000000);

    String dateStr = '';
    if (joinedAt != null) {
      try {
        final dt = DateTime.parse(joinedAt).toLocal();
        dateStr =
            '가입 ${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: UserAvatar(name: name, size: 44),
      title: Row(
        children: [
          Flexible(
            child: Text(name,
                style: AppTextStyles.h4, overflow: TextOverflow.ellipsis),
          ),
          if (roleLabel.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                roleLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: roleColor,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        dateStr.isNotEmpty ? '$email  $dateStr' : email,
        style: AppTextStyles.caption,
        overflow: TextOverflow.ellipsis,
      ),
      // admin 본인은 팝업 없음, 나머지는 역할변경+내보내기
      trailing: (!isFixed && isCurrentUserAdmin)
          ? PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'kick') {
                  onKick();
                } else {
                  onRoleChange(v);
                }
              },
              itemBuilder: (_) => [
                // ── 역할 변경 서브메뉴 ──
                if (role != 'sub_admin')
                  const PopupMenuItem(
                    value: 'sub_admin',
                    child: _RoleMenuItem(
                      icon: Icons.manage_accounts,
                      label: '부관리자로 변경',
                      color: Color(0xFF6366F1),
                    ),
                  ),
                if (role != 'instructor')
                  const PopupMenuItem(
                    value: 'instructor',
                    child: _RoleMenuItem(
                      icon: Icons.school_outlined,
                      label: '강사로 지정',
                      color: Color(0xFF10B981),
                    ),
                  ),
                if (role != 'member')
                  const PopupMenuItem(
                    value: 'member',
                    child: _RoleMenuItem(
                      icon: Icons.person_outline,
                      label: '일반 멤버로 변경',
                      color: AppColors.textSecondary,
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'kick',
                  child: _RoleMenuItem(
                    icon: Icons.person_remove_outlined,
                    label: '내보내기',
                    color: AppColors.error,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

// 팝업 메뉴 아이템 공통 위젯
class _RoleMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RoleMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}

// ── 승인 대기 타일 ─────────────────────────────────────
class _PendingTile extends StatelessWidget {
  final dynamic member;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _PendingTile({
    required this.member,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? '알 수 없음';
    final email = member['email'] as String? ?? '';
    final message = member['message'] as String?;
    final isMinor = member['is_minor'] == true || member['is_minor'] == 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: name, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: AppTextStyles.h4),
                        if (isMinor) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('미성년자',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    Text(email,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"$message"',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('거절'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onApprove,
                  child: const Text('승인'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 초대 링크 타일 ─────────────────────────────────────
class _InviteLinkTile extends StatelessWidget {
  final dynamic link;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  const _InviteLinkTile({
    required this.link,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final token = link['token'] as String? ?? '';
    final shortUrl = 'meti.app/invite/${token.length > 8 ? token.substring(0, 8) : token}...';
    final expiresAt = link['expires_at'] as String?;
    final maxUses = link['max_uses'] as int?;
    final useCount = link['use_count'] as int? ?? 0;
    final isActive = link['is_active'] == true || link['is_active'] == 1;

    String expireStr = '만료 없음';
    if (expiresAt != null) {
      try {
        final dt = DateTime.parse(expiresAt).toLocal();
        expireStr =
            '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} 만료';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.border : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.link,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shortUrl,
                        style: AppTextStyles.body1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '$expireStr · 사용 $useCount${maxUses != null ? '/$maxUses' : ''}회',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('비활성',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('링크 복사'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20),
                tooltip: '링크 삭제',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 지갑 통계 항목 (포인트 탭용) ──────────────────────
class _WalletStatItem extends StatelessWidget {
  final String label;
  final String value;
  const _WalletStatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── 카운트 배지 ────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge({required this.count, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── 레슨/이벤트 필터 칩 (v2.6) ───────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor = const Color(0xFF10B981),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── 상품 타일 (v2.6) ───────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Product product;
  final bool canManage;
  final VoidCallback onBuy;
  final VoidCallback onToggle;

  const _ProductTile({
    required this.product,
    required this.canManage,
    required this.onBuy,
    required this.onToggle,
  });

  static const _typeColors = {
    'service':  Color(0xFF6366F1),
    'physical': Color(0xFFEC4899),
    'digital':  Color(0xFF10B981),
  };

  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColors[product.type] ?? AppColors.textTertiary;
    final canBuy    = product.canPurchase;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: product.isActive
              ? AppColors.border
              : AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 유형 배지 + 상태 + 관리자 토글
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.typeLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: typeColor),
                  ),
                ),
                if (!product.isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '판매 중지',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error),
                    ),
                  ),
                ],
                if (product.isSoldOut) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '품절',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning),
                    ),
                  ),
                ],
                const Spacer(),
                // 관리자 전용 활성/비활성 토글
                if (canManage)
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.isActive
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: product.isActive
                              ? AppColors.success.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        product.isActive ? '판매중' : '중지됨',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: product.isActive
                              ? AppColors.success
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // 상품명
            Text(product.name, style: AppTextStyles.h4),
            if (product.description != null) ...[
              const SizedBox(height: 4),
              Text(product.description!,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),

            // 가격 + 재고
            Row(
              children: [
                Text(
                  '${_formatNumber(product.price)} P',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (product.stock != null)
                  Text(
                    '재고 ${product.remaining}/${product.stock}개',
                    style: AppTextStyles.caption,
                  )
                else
                  const Text('재고 무제한', style: AppTextStyles.caption),
              ],
            ),

            // 유효기간
            if (product.expiresAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: product.isExpired
                        ? AppColors.error
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${product.expiresAt!.year}.${product.expiresAt!.month.toString().padLeft(2, '0')}.${product.expiresAt!.day.toString().padLeft(2, '0')} 만료'
                    '${product.isExpired ? ' (만료됨)' : ''}',
                    style: TextStyle(
                        fontSize: 11,
                        color: product.isExpired
                            ? AppColors.error
                            : AppColors.textTertiary),
                  ),
                ],
              ),
            ],

            // 구매 버튼 (멤버용)
            if (!canManage) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canBuy ? onBuy : null,
                  icon: const Icon(Icons.shopping_cart_outlined, size: 15),
                  label: Text(
                    product.isSoldOut
                        ? '품절'
                        : product.isExpired
                            ? '판매 종료'
                            : !product.isActive
                                ? '판매 중지'
                                : '구매하기',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 36),
                    backgroundColor: const Color(0xFFEC4899),
                    disabledBackgroundColor: AppColors.border,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 이벤트 카드 (v2.6) ─────────────────────────────────
class _EventCard extends StatelessWidget {
  final Event event;
  final bool canManage;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onCancel;

  const _EventCard({
    required this.event,
    required this.canManage,
    required this.onJoin,
    required this.onLeave,
    required this.onCancel,
  });

  static const _statusColors = {
    'upcoming':  Color(0xFF6366F1),
    'ongoing':   Color(0xFF10B981),
    'ended':     Color(0xFF9CA3AF),
    'cancelled': Color(0xFFEF4444),
  };

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColors[event.status] ?? AppColors.textTertiary;
    final isCancelled = event.isCancelled;
    final isActive    = event.isActive;
    final isFull      = event.isFull;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCancelled
              ? AppColors.error.withValues(alpha: 0.25)
              : event.isJoined
                  ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                  : AppColors.border,
        ),
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
            // 상단: 상태 + 관리자 메뉴
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
                if (event.isJoined && isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '참가중',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1)),
                    ),
                  ),
                ],
                if (isFull && isActive) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '정원 마감',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning),
                    ),
                  ),
                ],
                const Spacer(),
                if (canManage && isActive)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'cancel') onCancel();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('이벤트 취소',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert,
                        size: 20, color: AppColors.textTertiary),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // 제목
            Text(
              event.title,
              style: AppTextStyles.h4.copyWith(
                decoration:
                    isCancelled ? TextDecoration.lineThrough : null,
                color: isCancelled ? AppColors.textTertiary : null,
              ),
            ),
            const SizedBox(height: 6),

            // 장소 + 일시
            if (event.location != null) ...[
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
              const SizedBox(height: 4),
            ],
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(_formatDate(event.startsAt),
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 참가 인원
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  event.capacity != null
                      ? '${event.participantCount}/${event.capacity}명'
                          '  (남은 자리 ${event.remaining}석)'
                      : '${event.participantCount}명 참가',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            if (event.capacity != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: event.capacity! > 0
                      ? event.participantCount / event.capacity!
                      : 0,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFull
                        ? AppColors.warning
                        : const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],

            // 참가 신청/취소 버튼
            if (isActive) ...[
              const SizedBox(height: 12),
              event.isJoined
                  ? OutlinedButton.icon(
                      onPressed: onLeave,
                      icon: const Icon(Icons.event_busy, size: 15),
                      label: const Text('참가 취소'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: isFull ? null : onJoin,
                      icon: const Icon(Icons.how_to_reg, size: 15),
                      label: Text(isFull ? '정원 마감' : '참가 신청'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        backgroundColor: const Color(0xFF6366F1),
                        disabledBackgroundColor: AppColors.border,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 레슨 카드 (v2.6) ───────────────────────────────────
class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool canManage;   // admin/sub_admin 여부 (레슨 취소 가능)
  final VoidCallback onRegister;
  final VoidCallback onCancel;             // 레슨 자체 취소 (관리자)
  final VoidCallback onCancelRegistration; // 수강 신청 취소

  const _LessonCard({
    required this.lesson,
    required this.canManage,
    required this.onRegister,
    required this.onCancel,
    required this.onCancelRegistration,
  });

  static const _statusColors = {
    'upcoming':  Color(0xFF3B82F6), // blue
    'ongoing':   Color(0xFF10B981), // green
    'ended':     Color(0xFF9CA3AF), // gray
    'cancelled': Color(0xFFEF4444), // red
  };

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.year}.${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')} '
          '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColors[lesson.status] ?? AppColors.textTertiary;
    final isCancelled = lesson.isCancelled;
    final isUpcoming  = lesson.isUpcoming;
    final isFull      = lesson.isFull;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCancelled
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.border,
        ),
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
            // 상단: 상태 배지 + 관리자 메뉴
            Row(
              children: [
                // 상태 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lesson.statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
                // 정원 가득 배지
                if (isFull && isUpcoming) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '정원 마감',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning),
                    ),
                  ),
                ],
                const Spacer(),
                // 관리자 전용: 레슨 취소 메뉴
                if (canManage && isUpcoming)
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'cancel') onCancel();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('레슨 취소',
                                style:
                                    TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert,
                        size: 20, color: AppColors.textTertiary),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // 제목
            Text(lesson.title,
                style: AppTextStyles.h4
                    .copyWith(
                      decoration: isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCancelled
                          ? AppColors.textTertiary
                          : null,
                    )),
            const SizedBox(height: 6),

            // 강사 + 일시
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(lesson.instructorName,
                    style: AppTextStyles.caption),
                const SizedBox(width: 12),
                const Icon(Icons.schedule,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(_formatDate(lesson.scheduledAt),
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),

            // 장소
            if (lesson.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 13, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(lesson.location!,
                      style: AppTextStyles.caption),
                ],
              ),
            ],
            const SizedBox(height: 10),

            // 수강 인원 프로그레스
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${lesson.registeredCount}/${lesson.capacity}명'
                  '  (남은 자리 ${lesson.remaining}석)',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: lesson.capacity > 0
                    ? lesson.registeredCount / lesson.capacity
                    : 0,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isFull ? AppColors.warning : const Color(0xFF10B981),
                ),
              ),
            ),

            // 수강 신청/취소 버튼 (upcoming 레슨만)
            if (isUpcoming) ...[
              const SizedBox(height: 12),
              lesson.isRegistered
                  ? OutlinedButton.icon(
                      onPressed: onCancelRegistration,
                      icon: const Icon(Icons.event_busy, size: 15),
                      label: const Text('수강 취소'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: isFull ? null : onRegister,
                      icon: const Icon(Icons.how_to_reg, size: 15),
                      label: Text(isFull ? '정원 마감' : '수강 신청'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor:
                            AppColors.border,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
