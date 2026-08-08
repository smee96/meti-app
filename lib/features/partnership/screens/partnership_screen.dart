import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/charge_launcher.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';
import '../models/partner_service_model.dart';
import '../providers/partnership_provider.dart';
import 'partner_webview_screen.dart';

/// 제휴 탭 — 해피트리 연동·미니게임 등 제휴 혜택 허브 (IA 개편 2026-07-20)
///
/// 해피트리는 서버 파트너 목록(GET /partner/services)에서 내려오면 실기능
/// (launch-token → 인앱 웹뷰)으로 열린다. 목록이 비거나 로드 실패면
/// '오픈 예정' 카드로 폴백한다. (스테이징 live 2026-08-08)
class PartnershipScreen extends StatefulWidget {
  const PartnershipScreen({super.key});

  @override
  State<PartnershipScreen> createState() => _PartnershipScreenState();
}

class _PartnershipScreenState extends State<PartnershipScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PartnershipProvider>();
      provider.loadServices();
      provider.loadBalance();
    });
  }

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

  /// 파트너 진입 — open_mode에 따라 인앱 웹뷰 또는 외부 브라우저.
  /// external 모드는 토큰을 먼저 발급받아 launch_url을 외부로 연다.
  Future<void> _openPartner(PartnerService service) async {
    if (!service.isExternal) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartnerWebviewScreen(service: service),
        ),
      );
      return;
    }
    try {
      final ticket =
          await context.read<PartnershipProvider>().issueLaunchToken(service.id);
      final url = ticket.launchUrl ?? service.webviewUrl;
      if (url == null || url.isEmpty) throw Exception();
      await launcher.launchUrl(
        Uri.parse(url),
        mode: launcher.LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(context, '접속에 실패했습니다. 잠시 후 다시 시도해주세요.');
      }
    }
  }

  IconData _partnerIcon(PartnerService s) =>
      s.name.contains('해피트리') ? Icons.park_outlined : Icons.handshake_outlined;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartnershipProvider>();
    final services = provider.services;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('제휴')),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.loadServices();
          await provider.loadBalance();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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

            // ── 파트너 게임 (서버 목록 기반) ──────────────────
            if (services.isNotEmpty)
              for (final service in services) ...[
                _PartnerCard(
                  icon: _partnerIcon(service),
                  iconColor: AppColors.success,
                  title: service.name,
                  subtitle: service.description ?? '',
                  trailing: Icon(
                    service.isExternal ? Icons.open_in_new : Icons.chevron_right,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () => _openPartner(service),
                ),
                if (service.name.contains('해피트리')) ...[
                  const SizedBox(height: 8),
                  _BalanceBar(balance: provider.balance),
                ],
                const SizedBox(height: 12),
              ]
            else ...[
              // 목록 로드 전/실패 폴백 — 기존 '오픈 예정' 카드
              _PartnerCard(
                icon: Icons.park_outlined,
                iconColor: AppColors.success,
                title: '해피트리',
                subtitle: '명함 네트워킹이 나눔으로 이어지는\n해피트리 제휴 서비스',
                badge: provider.isLoading ? null : '오픈 예정',
                trailing: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: () => _showComingSoon(context, '해피트리 제휴'),
              ),
              const SizedBox(height: 12),
            ],

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
      ),
    );
  }
}

/// B-2 게임재화 잔액 바 — 별·하트·코인 (읽기 전용 표시, 통합 가이드 §1).
/// 서버 프록시가 열리기 전(balance == null)에는 '—'와 연동 준비 중 안내를 보인다.
class _BalanceBar extends StatelessWidget {
  final PartnerBalance? balance;
  const _BalanceBar({required this.balance});

  @override
  Widget build(BuildContext context) {
    final b = balance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _BalanceItem(emoji: '🌟', label: '별', value: b?.stars.toString()),
          _divider(),
          _BalanceItem(
            emoji: '❤️',
            label: '하트',
            value: b == null ? null : '${b.hearts}/${b.heartsMax}',
          ),
          _divider(),
          _BalanceItem(emoji: '🪙', label: '코인', value: b?.coins.toString()),
          const Spacer(),
          if (b == null)
            const Text(
              '연동 준비 중',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.border,
      );
}

class _BalanceItem extends StatelessWidget {
  final String emoji;
  final String label;

  /// null이면 미연동 상태 — '—' 표시
  final String? value;

  const _BalanceItem({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
        const SizedBox(width: 4),
        Text(
          value ?? '—',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
