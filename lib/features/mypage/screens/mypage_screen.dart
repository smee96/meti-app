import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../points/providers/point_provider.dart';
import '../../points/screens/point_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PointProvider>().loadWallet();
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
            tooltip: '설정',
          ),
        ],
      ),
      body: Consumer2<AuthProvider, PointProvider>(
        builder: (context, auth, point, _) {
          final user = auth.user;
          if (user == null) return const SizedBox.shrink();

          return ListView(
            children: [
              // ── 프로필 헤더 ──────────────────────────────
              _buildProfileHeader(user, point),

              const Divider(height: 8, thickness: 8, color: AppColors.background),

              // ── 포인트 카드 ──────────────────────────────
              _buildPointCard(point),

              // ── 플랜 업그레이드 (Free 전용) ──────────────
              if (user.isFree) _buildUpgradeCard(),

              const Divider(height: 8, thickness: 8, color: AppColors.background),

              // ── 계정 메뉴 ────────────────────────────────
              _buildMenuSection('계정', [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: '프로필 수정',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: '비밀번호 변경',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: '알림 설정',
                  onTap: () {},
                ),
              ]),

              _buildMenuSection('앱 정보', [
                _MenuItem(
                  icon: Icons.info_outline,
                  label: '버전 정보',
                  trailing: const Text('v1.0.0', style: AppTextStyles.body2),
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: '이용약관',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: '개인정보처리방침',
                  onTap: () {},
                ),
              ]),

              const Divider(height: 8, thickness: 8, color: AppColors.background),

              // ── 로그아웃 ─────────────────────────────────
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('로그아웃',
                    style: TextStyle(color: AppColors.error)),
                onTap: _handleLogout,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // ── 프로필 헤더 ───────────────────────────────────────
  Widget _buildProfileHeader(user, PointProvider point) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Column(
        children: [
          Stack(
            children: [
              UserAvatar(name: user.name, size: 80),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.name, style: AppTextStyles.h2),
              const SizedBox(width: 8),
              PlanBadge(plan: user.plan),
              // 어드민 배지
              if (user.isSuperAdmin) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '슈퍼어드민',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else if (user.isGroupAdmin) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '그룹관리자',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(user.email, style: AppTextStyles.body2),
          const SizedBox(height: 4),
          Text(
            '개인 회원', // v2.8: headhunter 타입 제거, 항상 개인 회원 고정
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  // ── 포인트 카드 ───────────────────────────────────────
  Widget _buildPointCard(PointProvider point) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PointScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet,
                color: Colors.amber, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '내 포인트',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  point.isLoading
                      ? const SizedBox(
                          height: 28,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '${_formatNumber(point.balance)} P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text('내역',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 업그레이드 카드 ───────────────────────────────────
  Widget _buildUpgradeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium,
              color: AppColors.accent, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro로 업그레이드', style: AppTextStyles.h4),
                Text('명함 10장 + 고급 기능 (10,000P/월)',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.upgrade,
                arguments: {
                  'fromContext': '더 많은 명함과 그룹 관리를 위해 Pro 플랜으로 업그레이드하세요.',
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('업그레이드'),
          ),
        ],
      ),
    );
  }

  // ── 메뉴 섹션 ─────────────────────────────────────────
  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: AppTextStyles.label),
        ),
        ...items.map(
          (item) => ListTile(
            leading:
                Icon(item.icon, size: 22, color: AppColors.textSecondary),
            title: Text(item.label),
            trailing: item.trailing ??
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textTertiary),
            onTap: item.onTap,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });
}
