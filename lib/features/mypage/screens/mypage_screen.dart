import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int _rewardPoints = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRewardPoints());
  }

  Future<void> _loadRewardPoints() async {
    // TODO: 파트너 API 연동 후 실제 데이터 로드
    setState(() => _rewardPoints = 0);
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
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) return const SizedBox.shrink();

          return ListView(
            children: [
              // 프로필 헤더
              Container(
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user.email, style: AppTextStyles.body2),
                    const SizedBox(height: 4),
                    Text(
                      user.accountType == 'headhunter' ? '헤드헌터' : '개인',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              const Divider(height: 8, thickness: 8, color: AppColors.background),

              // 리워드 카드
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '리워드 포인트',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            '$_rewardPoints P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Text('내역'),
                    ),
                  ],
                ),
              ),

              // 플랜 정보
              if (user.isFree) _buildUpgradeCard(),

              const Divider(height: 8, thickness: 8, color: AppColors.background),

              // 메뉴
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

              // 로그아웃
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
          const Icon(Icons.workspace_premium, color: AppColors.accent, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro로 업그레이드', style: AppTextStyles.h4),
                Text('무제한 명함 + 고급 기능', style: AppTextStyles.body2),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
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

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: AppTextStyles.label),
        ),
        ...items.map((item) => ListTile(
              leading: Icon(item.icon, size: 22, color: AppColors.textSecondary),
              title: Text(item.label),
              trailing:
                  item.trailing ?? const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
              onTap: item.onTap,
            )),
        const Divider(height: 1),
      ],
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
