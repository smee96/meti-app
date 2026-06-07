// ignore_for_file: deprecated_member_use
// guardians_screen.dart — 보호자 연결 화면
// 탭 1: 내 보호자 (학생 시점 — 보호자 목록 + 초대)
// 탭 2: 내 학생  (보호자 시점 — 연결된 학생 목록)
// v3.0 신규

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../models/guardian_model.dart';
import '../providers/guardian_provider.dart';

class GuardiansScreen extends StatefulWidget {
  const GuardiansScreen({super.key});

  @override
  State<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends State<GuardiansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final p = context.read<GuardianProvider>();
    await Future.wait([p.loadMyGuardians(), p.loadMyStudents()]);
  }

  // ── 보호자 초대 다이얼로그 ──────────────────────────────────────
  Future<void> _showInviteDialog() async {
    final emailCtrl    = TextEditingController();
    String relation    = 'parent';
    final formKey      = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('보호자 초대'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이메일 입력
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '보호자 이메일',
                    hintText: 'guardian@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요.';
                    if (!v.contains('@')) return '올바른 이메일 형식을 입력해주세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 관계 선택
                Text('관계', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: relation,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.people_outline),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'parent',   child: Text('부모')),
                    DropdownMenuItem(value: 'guardian', child: Text('보호자')),
                    DropdownMenuItem(value: 'other',    child: Text('기타')),
                  ],
                  onChanged: (v) => setDlg(() => relation = v ?? 'parent'),
                ),
              ],
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
                Navigator.pop(ctx);
                await _doInvite(emailCtrl.text.trim(), relation);
              },
              child: const Text('초대 보내기'),
            ),
          ],
        ),
      ),
    );

    emailCtrl.dispose();
  }

  Future<void> _doInvite(String email, String relation) async {
    final p = context.read<GuardianProvider>();
    final ok = await p.inviteGuardian(
      minorEmail: email,
      relation:   relation,
    );
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, '$email 님께 보호자 초대를 보냈습니다.');
    } else {
      showErrorSnackBar(context, p.errorMessage ?? '초대에 실패했습니다.');
    }
  }

  // ── 초대 취소 확인 다이얼로그 ─────────────────────────────────
  Future<void> _confirmCancel(GuardianLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('초대 취소'),
        content: const Text('보내신 보호자 초대를 취소하시겠습니까?'),
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

    final p  = context.read<GuardianProvider>();
    final ok = await p.removeGuardian(link.id);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, '초대가 취소되었습니다.');
    } else {
      showErrorSnackBar(context, p.errorMessage ?? '취소에 실패했습니다.');
    }
  }

  // ── 연결 삭제 확인 다이얼로그 ─────────────────────────────────
  Future<void> _confirmRemove(GuardianLink link, {bool isGuardian = true}) async {
    final name = isGuardian
        ? (link.guardian?.name ?? '보호자')
        : (link.student?.name ?? '학생');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('연결 해제'),
        content: Text('$name 님과의 보호자 연결을 해제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('아니오')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('해제하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final p  = context.read<GuardianProvider>();
    final ok = await p.removeGuardian(link.id);
    if (!mounted) return;
    if (ok) {
      showSuccessSnackBar(context, '연결이 해제되었습니다.');
    } else {
      showErrorSnackBar(context, p.errorMessage ?? '해제에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보호자 관리'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: '내 보호자'),
            Tab(text: '내 학생'),
          ],
        ),
      ),
      // FAB: 내 보호자 탭에서만 초대 버튼 표시
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (_, __) => _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _showInviteDialog,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('보호자 초대'),
                backgroundColor: AppColors.primary,
              )
            : const SizedBox.shrink(),
      ),
      body: Consumer<GuardianProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              // ── 탭 1: 내 보호자 ──────────────────────────────────
              _MyGuardiansTab(
                links:         provider.myGuardians,
                onRefresh:     provider.loadMyGuardians,
                onCancel:      _confirmCancel,
                onRemove: (l) => _confirmRemove(l, isGuardian: true),
              ),
              // ── 탭 2: 내 학생 ────────────────────────────────────
              _MyStudentsTab(
                links:     provider.myStudents,
                onRefresh: provider.loadMyStudents,
                onRemove: (l) => _confirmRemove(l, isGuardian: false),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 탭 1: 내 보호자
// ══════════════════════════════════════════════════════════════════
class _MyGuardiansTab extends StatelessWidget {
  final List<GuardianLink> links;
  final Future<void> Function() onRefresh;
  final void Function(GuardianLink) onCancel;
  final void Function(GuardianLink) onRemove;

  const _MyGuardiansTab({
    required this.links,
    required this.onRefresh,
    required this.onCancel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.family_restroom_outlined,
        title: '등록된 보호자가 없어요',
        subtitle: '보호자 초대 버튼을 눌러 초대해보세요.',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: links.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _GuardianLinkCard(
          link:         links[i],
          isGuardianView: true,
          onCancel:     links[i].isPending  ? () => onCancel(links[i]) : null,
          onRemove:     links[i].isAccepted ? () => onRemove(links[i]) : null,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 탭 2: 내 학생
// ══════════════════════════════════════════════════════════════════
class _MyStudentsTab extends StatelessWidget {
  final List<GuardianLink> links;
  final Future<void> Function() onRefresh;
  final void Function(GuardianLink) onRemove;

  const _MyStudentsTab({
    required this.links,
    required this.onRefresh,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.school_outlined,
        title: '연결된 학생이 없어요',
        subtitle: '학생이 보호자 초대를 보내면 여기에 표시됩니다.',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: links.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _GuardianLinkCard(
          link:           links[i],
          isGuardianView: false,
          onRemove:       links[i].isAccepted ? () => onRemove(links[i]) : null,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 공통 카드 위젯
// ══════════════════════════════════════════════════════════════════
class _GuardianLinkCard extends StatelessWidget {
  final GuardianLink link;
  final bool isGuardianView;  // true=보호자 뷰, false=학생 뷰
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;

  const _GuardianLinkCard({
    required this.link,
    required this.isGuardianView,
    this.onCancel,
    this.onRemove,
  });

  Color get _statusColor {
    switch (link.status) {
      case 'pending':  return AppColors.warning;
      case 'accepted': return AppColors.success;
      case 'rejected': return AppColors.error;
      default:         return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = isGuardianView ? link.guardian : link.student;
    final displayName  = person?.name  ?? '(알 수 없음)';
    final displayEmail = person?.email ?? '';

    return Container(
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
        child: Row(
          children: [
            // 아바타
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
              backgroundImage: person?.avatarUrl != null
                  ? NetworkImage(person!.avatarUrl!)
                  : null,
              child: person?.avatarUrl == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // 이름 + 이메일 + 관계
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(displayName,
                          style: AppTextStyles.body1
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      // 관계 배지
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(link.relationLabel,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  if (displayEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(displayEmail,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  // 상태 배지
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      link.statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 액션 버튼
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // pending → 취소 버튼 (보호자 뷰에서만)
                if (onCancel != null)
                  _ActionIconButton(
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    tooltip: '초대 취소',
                    onTap: onCancel!,
                  ),
                // accepted → 연결 해제 버튼
                if (onRemove != null)
                  _ActionIconButton(
                    icon: Icons.link_off_outlined,
                    color: AppColors.textSecondary,
                    tooltip: '연결 해제',
                    onTap: onRemove!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 아이콘 버튼 (소형) ────────────────────────────────────────────
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
