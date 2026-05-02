import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

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
      final response = await _api.get('/groups/my');
      if (response['success'] == true) {
        setState(() => _myGroups = response['data'] as List);
      }
    } catch (_) {}
    setState(() => _isMyGroupsLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '그룹 탐색'),
            Tab(text: '내 그룹'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '그룹 개설 신청',
            onPressed: _showCreateGroupSheet,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(),
          _buildMyGroupsTab(),
        ],
      ),
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
        itemBuilder: (_, i) => _GroupCard(
          group: _myGroups[i],
          showRole: true,
          onTap: () => _showGroupDetail(_myGroups[i]),
        ),
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
            final success = resp['success'] == true;
            final msg = success
                ? '그룹 개설 신청이 완료되었습니다!\n슈퍼어드민 승인 후 활성화됩니다.'
                : (resp['message']?.toString() ?? '신청에 실패했습니다.');
            if (success) {
              showSuccessSnackBar(ctx, msg);
            } else {
              showErrorSnackBar(ctx, msg);
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

  const _GroupCard({required this.group, this.showRole = false, this.onTap});

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
                      Text('${group['member_count'] ?? 0}명',
                          style: AppTextStyles.caption),
                      if (group['purpose'] != null) ...[
                        const SizedBox(width: 8),
                        _PurposeBadge(purpose: group['purpose'] as String),
                      ],
                      if (showRole && group['role'] != null) ...[
                        const SizedBox(width: 8),
                        _RoleBadge(role: group['role'] as String),
                      ],
                    ],
                  ),
                ],
              ),
            ),
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

  String get _label {
    final found = AppConstants.groupPurposes
        .where((p) => p['value'] == purpose)
        .toList();
    return found.isNotEmpty ? found.first['label']! : purpose;
  }

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
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
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
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedPurpose = 'networking';
  String _visibility = 'public';
  int _maxMembers = 100;
  bool _isLoading = false;

  final _maxMembersOptions = [10, 20, 50, 100, 200, 500, 1000];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
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
              autofocus: true,
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

            // 목적 선택
            const Text('그룹 목적 *', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.groupPurposes.map((p) {
                final isSelected = _selectedPurpose == p['value'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedPurpose = p['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      p['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                      if (_nameCtrl.text.trim().isEmpty) return;
                      setState(() => _isLoading = true);
                      await widget.onSubmit({
                        'name': _nameCtrl.text.trim(),
                        if (_descCtrl.text.trim().isNotEmpty)
                          'description': _descCtrl.text.trim(),
                        'purpose': _selectedPurpose,
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
