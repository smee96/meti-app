import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';
import 'group_admin_screen.dart';

class GroupsScreen extends StatefulWidget {
  /// true면 네트워크 탭 안에 임베드 — 자체 Scaffold/AppBar 없이 내부 탭+본문만 렌더
  final bool embedded;
  const GroupsScreen({super.key, this.embedded = false});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();

  List<dynamic> _groups = [];
  List<dynamic> _myGroups = [];
  bool _isLoading = false;
  bool _isMyGroupsLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _myGroups.isEmpty) {
        _loadMyGroups();
      }
    });
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, dynamic>{'page': 1, 'limit': 20};
      if (_searchQuery.isNotEmpty) params['q'] = _searchQuery;

      final response =
          await _api.get('/groups', queryParams: params, auth: false);
      if (response['success'] == true) {
        setState(() => _groups = response['data'] as List);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _loadMyGroups() async {
    setState(() => _isMyGroupsLoading = true);
    try {
      final response = await _api.get('/groups/mine'); // v2.9: /groups/mine
      if (response['success'] == true) {
        setState(() => _myGroups = response['data'] as List);
      }
    } catch (_) {}
    setState(() => _isMyGroupsLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // 네트워크 탭 임베드: 내부 탭바(+ 그룹 개설 버튼)를 본문 상단에 배치
      return Column(
        children: [
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(child: _buildTabBar()),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '그룹 개설 신청',
                  color: AppColors.textSecondary,
                  onPressed: _showCreateGroupSheet,
                ),
              ],
            ),
          ),
          Expanded(child: _buildTabBarView()),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹'),
        bottom: _buildTabBar(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '그룹 개설 신청',
            onPressed: _showCreateGroupSheet,
          ),
        ],
      ),
      body: _buildTabBarView(),
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      tabs: const [
        Tab(text: '그룹 탐색'),
        Tab(text: '내 그룹'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildExploreTab(),
        _buildMyGroupsTab(),
      ],
    );
  }

  // ── 탐색 탭 ──────────────────────────────────────────────
  Widget _buildExploreTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: '그룹 검색',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) {
              _searchQuery = v;
              _loadGroups();
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _groups.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.group_outlined,
                      title: '그룹이 없어요',
                      subtitle: '새로운 그룹을 개설해보세요!',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadGroups,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: _groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _GroupCard(
                          group: _groups[i],
                          onTap: () => _showGroupDetail(_groups[i]),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  // ── 내 그룹 탭 ──────────────────────────────────────────
  Widget _buildMyGroupsTab() {
    if (_isMyGroupsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_myGroups.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.group_outlined,
        title: '가입된 그룹이 없어요',
        subtitle: '\'그룹 탐색\'에서 관심 있는 그룹에 참여해보세요.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMyGroups,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _myGroups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final g = _myGroups[i];
          final myRole   = g['my_role']   as String? ?? 'member';
          final myStatus = g['my_status'] as String? ?? 'active'; // v2.9
          final isAdmin  = myRole == 'admin' || myRole == 'owner';

          // v2.9: pending 상태 — 신청 중 카드 (취소 버튼 표시)
          if (myStatus == 'pending' || myStatus == 'group_pending') {
            return _PendingGroupCard(
              group: g,
              myStatus: myStatus,
              onCancel: () async {
                final gid = g['id'] as int? ?? 0;
                try {
                  await _api.delete('/groups/$gid/leave');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('가입 신청이 취소되었습니다.')),
                    );
                    await _loadMyGroups();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
            );
          }

          // active 상태 — 기존 카드
          return _GroupCard(
            group: g,
            showRole: true,
            onTap: () => _showGroupDetail(g),
            adminButton: isAdmin
                ? ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupAdminScreen(group: g),
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts, size: 16),
                    label: const Text('관리'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  // ── 그룹 개설 신청 완료 '심사 중' 다이얼로그 (H3) ──────
  void _showGroupPendingDialog(String groupName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: AppColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '개설 신청 완료',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              groupName.isNotEmpty ? '"$groupName"' : '그룹',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text(
                        '심사 중 (pending)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '슈퍼어드민이 신청 내용을 검토한 후 승인합니다.\n승인되면 그룹이 활성화되며 멤버를 초대할 수 있습니다.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }

  // ── 그룹 상세 바텀시트 ────────────────────────────────
  void _showGroupDetail(dynamic group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GroupDetailSheet(
        group: group,
        api: _api,
        onJoined: () {
          Navigator.pop(ctx);
          _loadMyGroups();
          if (mounted) {
            showSuccessSnackBar(context, '그룹 가입 신청이 완료되었습니다!');
          }
        },
      ),
    );
  }

  // ── 그룹 개설 신청 바텀시트 ──────────────────────────
  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateGroupSheet(
        onSubmit: (data) async {
          try {
            final resp = await _api.post('/groups', body: data);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (resp['success'] == true) {
              // H3: 성공 시 스낵바 대신 '심사 중' 다이얼로그 표시
              _showGroupPendingDialog(data['name'] as String? ?? '');
            } else {
              showErrorSnackBar(
                  ctx, resp['message']?.toString() ?? '신청에 실패했습니다.');
            }
          } catch (e) {
            if (!ctx.mounted) return;
            showErrorSnackBar(ctx, e.toString());
          }
        },
      ),
    );
  }
}

// ── 그룹 카드 위젯 ──────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final dynamic group;
  final bool showRole;
  final VoidCallback? onTap;
  final Widget? adminButton;

  const _GroupCard({
    required this.group,
    this.showRole = false,
    this.onTap,
    this.adminButton,
  });

  @override
  Widget build(BuildContext context) {
    final visibility = group['visibility'] as String? ?? 'public';
    final isPrivate = visibility == 'private';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(group['name'] ?? '',
                            style: AppTextStyles.h4,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isPrivate)
                        const Icon(Icons.lock_outline,
                            size: 14, color: AppColors.textTertiary),
                    ],
                  ),
                  if (group['description'] != null &&
                      (group['description'] as String).isNotEmpty)
                    Text(
                      group['description'],
                      style: AppTextStyles.body2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 13, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      // v2.5: 관리자 그룹이면 멤버수/한도 표시
                      Builder(builder: (_) {
                        final memberCount = group['member_count'] ?? 0;
                        final maxLimit = group['max_group_members'] as int?;
                        if (showRole && maxLimit != null) {
                          final isAtLimit = memberCount >= maxLimit;
                          return Text(
                            '$memberCount/$maxLimit명',
                            style: AppTextStyles.caption.copyWith(
                              color: isAtLimit ? AppColors.error : null,
                              fontWeight: isAtLimit ? FontWeight.bold : null,
                            ),
                          );
                        }
                        return Text('$memberCount명',
                            style: AppTextStyles.caption);
                      }),
                      if (group['purpose'] != null) ...[
                        const SizedBox(width: 8),
                        _PurposeBadge(purpose: group['purpose'] as String),
                      ],
                      if (showRole && group['my_role'] != null) ...[
                        const SizedBox(width: 8),
                        _RoleBadge(role: group['my_role'] as String),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (adminButton != null)
              adminButton!
            else
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _PurposeBadge extends StatelessWidget {
  final String purpose;
  const _PurposeBadge({required this.purpose});

  // v2.9: purpose는 자유 텍스트 — 바로 표시
  String get _label => purpose.isNotEmpty ? purpose : '막연';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(_label,
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin' || role == 'owner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAdmin ? '관리자' : '멤버',
        style: TextStyle(
          fontSize: 10,
          color: isAdmin ? AppColors.warning : AppColors.success,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── 그룹 상세 + 가입 바텀시트 ──────────────────────────
class _GroupDetailSheet extends StatefulWidget {
  final dynamic group;
  final ApiClient api;
  final VoidCallback onJoined;

  const _GroupDetailSheet({
    required this.group,
    required this.api,
    required this.onJoined,
  });

  @override
  State<_GroupDetailSheet> createState() => _GroupDetailSheetState();
}

class _GroupDetailSheetState extends State<_GroupDetailSheet> {
  bool _showJoinForm = false;
  bool _isLoading = false;

  // 생년월일 (선택)
  DateTime? _birthDate;
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  bool _calculateIsMinor() {
    if (_birthDate == null) return false;
    final today = DateTime.now();
    final age = today.year -
        _birthDate!.year -
        ((today.month < _birthDate!.month ||
                (today.month == _birthDate!.month &&
                    today.day < _birthDate!.day))
            ? 1
            : 0);
    return age < 19;
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
      confirmText: '확인',
      cancelText: '취소',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleJoin() async {
    setState(() => _isLoading = true);
    try {
      final body = <String, dynamic>{};
      if (_messageCtrl.text.trim().isNotEmpty) {
        body['message'] = _messageCtrl.text.trim();
      }
      if (_birthDate != null) {
        final bd =
            '${_birthDate!.year.toString().padLeft(4, '0')}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
        body['birth_date'] = bd;
        body['is_minor'] = _calculateIsMinor();
      }
      final groupId = widget.group['id'];
      final resp =
          await widget.api.post('/groups/$groupId/join', body: body);
      if (!mounted) return;
      if (resp['success'] == true) {
        widget.onJoined();
      } else {
        showErrorSnackBar(
            context, resp['message']?.toString() ?? '가입 신청에 실패했습니다.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      // v2.5: 멤버 한도 초과 → 업그레이드 모달
      if (e.upgradeRequired && e.errorCode == 'plan_member_limit_reached') {
        _showMemberLimitModal(e.extra?['limit'] as int? ?? 2);
      // v2.5: 포인트 부족 → 충전 버튼 없이 잔액/부족 금액만 표시
      } else if (e.errorCode == 'insufficient_points') {
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
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// v2.5 멤버 한도 초과 업그레이드 유도 모달
  void _showMemberLimitModal(int limit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('📋', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            const Text(
              '멤버 한도에 도달했습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '현재 Free 플랜은 그룹당 최대\n$limit명까지 관리할 수 있습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pro로 업그레이드하면',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 6),
                  Text('• 그룹당 최대 10명까지 초대',
                      style: TextStyle(fontSize: 13)),
                  Text('• 10,000P/월 자동 지급',
                      style: TextStyle(fontSize: 13)),
                  Text('• 명함 최대 10개',
                      style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('나중에'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.upgrade,
                        arguments: {
                          'fromContext': 'Free 플랜은 그룹당 최대 $limit명까지 관리할 수 있습니다. 더 많은 멤버를 관리하려면 업그레이드하세요.',
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Pro 구독하기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final hasMinor = group['has_minor'] == true || group['has_minor'] == 1;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: sheetBottomPadding(context, 28),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 그룹 아이콘 + 이름
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      const Icon(Icons.group, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group['name'] ?? '', style: AppTextStyles.h3),
                      if (group['purpose'] != null)
                        _PurposeBadge(purpose: group['purpose'] as String),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 설명
            if (group['description'] != null &&
                (group['description'] as String).isNotEmpty) ...[
              Text(group['description'], style: AppTextStyles.body1),
              const SizedBox(height: 12),
            ],

            // 정보 행
            Row(
              children: [
                _InfoChip(
                    icon: Icons.people_outline,
                    label: '${group['member_count'] ?? 0}명'),
                const SizedBox(width: 8),
                _InfoChip(
                    icon: group['visibility'] == 'private'
                        ? Icons.lock_outline
                        : Icons.public,
                    label: group['visibility'] == 'private' ? '비공개' : '공개'),
                if (hasMinor) ...[
                  const SizedBox(width: 8),
                  _InfoChip(icon: Icons.child_care, label: '청소년 포함'),
                ],
              ],
            ),
            const SizedBox(height: 20),

            if (!_showJoinForm) ...[
              ElevatedButton.icon(
                onPressed: () => setState(() => _showJoinForm = true),
                icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                label: const Text('가입 신청하기'),
              ),
            ] else ...[
              // 가입 신청 폼
              const Divider(),
              const SizedBox(height: 12),
              Text('가입 신청', style: AppTextStyles.h4),
              const SizedBox(height: 4),
              Text(
                '관리자 승인 후 그룹에 참여할 수 있습니다.',
                style: AppTextStyles.body2,
              ),
              const SizedBox(height: 16),

              // 생년월일 (선택)
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _birthDate == null
                              ? '생년월일 (선택)'
                              : '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일',
                          style: TextStyle(
                            color: _birthDate == null
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_birthDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _birthDate = null),
                          child: const Icon(Icons.close,
                              size: 16, color: AppColors.textTertiary),
                        ),
                    ],
                  ),
                ),
              ),

              // 미성년자 안내
              if (_birthDate != null && _calculateIsMinor()) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '만 19세 미만으로 처리됩니다.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // 가입 메시지
              TextField(
                controller: _messageCtrl,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: '가입 메시지 (선택)',
                  hintText: '자기소개나 가입 동기를 작성해주세요.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showJoinForm = false),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleJoin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('신청하기'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── 그룹 개설 신청 바텀시트 ────────────────────────────
class _CreateGroupSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const _CreateGroupSheet({required this.onSubmit});

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _purposeCtrl = TextEditingController(); // v2.9: 자유 텍스트
  String _visibility = 'public';
  int _maxMembers = 100;
  bool _isLoading = false;

  final _maxMembersOptions = [10, 20, 50, 100, 200, 500, 1000];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: sheetBottomPadding(context, 28),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text('그룹 개설 신청', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            const Text(
              '슈퍼어드민 승인 후 그룹이 활성화됩니다.',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: 20),

            // 그룹명
            TextField(
              controller: _nameCtrl,
              // autofocus 제거 — BottomSheet 내 한글 IME 입력 방해 방지
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '그룹명 *',
                prefixIcon: Icon(Icons.group_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // 설명
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '그룹 소개',
                hintText: '그룹의 목적과 활동을 소개해주세요.',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // v2.9: 목적 자유 텍스트 (5자 이상 필수)
            const Text('그룹 목적 *', style: AppTextStyles.label),
            const SizedBox(height: 4),
            const Text('5자 이상 자유롭게 작성해주세요',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _purposeCtrl,
              maxLength: 100,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: '예) 플러터 개발자 지식 공유 및 네트워킹 스터디',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),

            // 공개 여부
            const Text('공개 설정', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _VisibilityOption(
                    icon: Icons.public,
                    label: '공개',
                    desc: '누구나 검색·가입 신청',
                    isSelected: _visibility == 'public',
                    onTap: () => setState(() => _visibility = 'public'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _VisibilityOption(
                    icon: Icons.lock_outline,
                    label: '비공개',
                    desc: '초대 링크로만 가입',
                    isSelected: _visibility == 'private',
                    onTap: () => setState(() => _visibility = 'private'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 최대 인원
            Row(
              children: [
                const Text('최대 인원', style: AppTextStyles.label),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _maxMembersOptions.map((n) {
                        final isSelected = _maxMembers == n;
                        return GestureDetector(
                          onTap: () => setState(() => _maxMembers = n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              '$n명',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      // H4: 그룹명 필수 검사
                      if (_nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('그룹명을 입력해주세요.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      // v2.9: purpose 5자 이상 검사 (자유 텍스트)
                      if (_purposeCtrl.text.trim().length < 5) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('그룹 목적을 5자 이상 입력해주세요.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      setState(() => _isLoading = true);
                      await widget.onSubmit({
                        'name': _nameCtrl.text.trim(),
                        if (_descCtrl.text.trim().isNotEmpty)
                          'description': _descCtrl.text.trim(),
                        'purpose': _purposeCtrl.text.trim(),
                        'visibility': _visibility,
                        'max_members': _maxMembers,
                      });
                      if (mounted) setState(() => _isLoading = false);
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('신청하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityOption({
    required this.icon,
    required this.label,
    required this.desc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            Text(desc,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

// ── v2.9: pending 신청 중 그룹 카드 ─────────────────────────────
class _PendingGroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final String myStatus;       // 'pending' | 'group_pending'
  final VoidCallback onCancel;

  const _PendingGroupCard({
    required this.group,
    required this.myStatus,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final name        = group['name']        as String? ?? '';
    final description = group['description'] as String? ?? '';
    final adminName   = group['admin_name']  as String? ?? '';
    final memberCount = group['member_count'] as int?   ?? 0;

    final isPending      = myStatus == 'pending';
    final statusLabel    = isPending ? '승인 대기 중' : '초대 수락 대기';
    final statusColor    = isPending ? Colors.orange : Colors.blue;
    final cancelLabel    = isPending ? '신청 취소' : '초대 거절';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 상태 뱃지 + 이름
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_top_rounded,
                        size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          // 하단: 관리자 / 멤버 수 / 취소 버튼
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 3),
              Text('관리자: $adminName',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(width: 10),
              Icon(Icons.group_outlined,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 3),
              Text('$memberCount명',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _confirmCancel(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: statusColor,
                  side: BorderSide(color: statusColor.withValues(alpha: 0.6)),
                  minimumSize: const Size(0, 30),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(cancelLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    final isPending = myStatus == 'pending';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isPending ? '신청 취소' : '초대 거절'),
        content: Text(isPending
            ? '"${group['name']}" 그룹 가입 신청을 취소할까요?'
            : '"${group['name']}" 그룹 초대를 거절할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onCancel();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isPending ? '취소하기' : '거절하기'),
          ),
        ],
      ),
    );
  }
}
