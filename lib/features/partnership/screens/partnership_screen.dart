import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/charge_launcher.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

/// 제휴 탭 — 해피트리 연동·미니게임 등 제휴 혜택 허브 (IA 개편 2026-07-20)
/// 해피트리·미니게임은 연동 전이라 '준비 중'으로 노출하고,
/// 포인트(충전·내역)는 지금도 동작하는 항목으로 배치한다.
class PartnershipScreen extends StatelessWidget {
  const PartnershipScreen({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature은(는) 준비 중입니다. 조금만 기다려주세요!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _openCharge(BuildContext context) async {
    final opened = await openExternalChargePage();
    if (!opened && context.mounted) {
      showErrorSnackBar(context, '브라우저를 열 수 없습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('제휴')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 헤더 ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 16),
            child: Text(
              'ELID와 함께하는\n제휴 혜택을 만나보세요',
              style: AppTextStyles.h2,
            ),
          ),

          // ── 해피트리 (준비 중) ────────────────────────────
          _PartnerCard(
            icon: Icons.park_outlined,
            iconColor: AppColors.success,
            title: '해피트리',
            subtitle: '명함 네트워킹이 나눔으로 이어지는\n해피트리 제휴 서비스',
            badge: '오픈 예정',
            onTap: () => _showComingSoon(context, '해피트리 제휴'),
          ),
          const SizedBox(height: 12),

          // ── 미니게임 (준비 중) ────────────────────────────
          _PartnerCard(
            icon: Icons.videogame_asset_outlined,
            iconColor: AppColors.accent,
            title: '포인트 미니게임',
            subtitle: '게임하고 포인트 적립하기',
            badge: '오픈 예정',
            onTap: () => _showComingSoon(context, '포인트 미니게임'),
          ),
          const SizedBox(height: 12),

          // ── 포인트 (동작) ────────────────────────────────
          _PartnerCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.primary,
            title: '포인트 충전',
            subtitle: '웹 충전 페이지에서 포인트 충전하기',
            trailing: const Icon(Icons.open_in_new,
                size: 18, color: AppColors.textTertiary),
            onTap: () => _openCharge(context),
          ),
          const SizedBox(height: 12),
          _PartnerCard(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.info,
            title: '포인트 내역',
            subtitle: '잔액과 적립·사용 내역 확인',
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.textTertiary),
            onTap: () => Navigator.pushNamed(context, AppRoutes.myPoints),
          ),

          const SizedBox(height: 24),
          // ── 제휴 문의 안내 ────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.handshake_outlined,
                    color: AppColors.accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ELID와 제휴를 원하시는 기업·단체는\n마이페이지 > 문의하기로 연락해주세요.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
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

class _PartnerCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Widget? trailing;
  final VoidCallback onTap;

  const _PartnerCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: AppTextStyles.h4),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
