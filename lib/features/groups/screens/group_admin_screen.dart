import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../points/models/point_model.dart';

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
  List<dynamic> _pending = [];
  List<dynamic> _inviteLinks = [];
  bool _isLoading = false;

  // M2: 그룹 포인트 잔액
  PointWallet? _groupWallet;
  bool _isWalletLoading = false;
  // M1: 포인트 이체 입력
  final _transferAmountCtrl = TextEditingController();
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
    _loadGroupWallet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _transferAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final gid = widget.group['id'];
    try {
      // 멤버 목록
      final mRes = await _api.get('/groups/$gid/members');
      if (mRes['success'] == true) {
        _members = (mRes['data'] as List?) ?? [];
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
                onKick: () => _handleKick(_members[i]),
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

// ── 멤버 타일 ──────────────────────────────────────────
class _MemberTile extends StatelessWidget {
  final dynamic member;
  final VoidCallback onKick;
  const _MemberTile({required this.member, required this.onKick});

  @override
  Widget build(BuildContext context) {
    final role = member['role'] as String? ?? 'member';
    final isAdmin = role == 'admin' || role == 'owner';
    final name = member['name'] as String? ?? '알 수 없음';
    final email = member['email'] as String? ?? '';
    final joinedAt = member['joined_at'] as String?;

    String dateStr = '';
    if (joinedAt != null) {
      try {
        final dt = DateTime.parse(joinedAt).toLocal();
        dateStr = '가입 ${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: UserAvatar(name: name, size: 44),
      title: Row(
        children: [
          Text(name, style: AppTextStyles.h4),
          if (isAdmin) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '관리자',
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
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
      trailing: !isAdmin
          ? PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'kick') onKick();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'kick',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_outlined,
                          size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('내보내기',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            )
          : null,
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
