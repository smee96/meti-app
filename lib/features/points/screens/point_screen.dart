import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/charge_launcher.dart';
import '../../../core/utils/server_date.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/point_provider.dart';
import '../models/point_model.dart';

class PointScreen extends StatefulWidget {
  const PointScreen({super.key});

  @override
  State<PointScreen> createState() => _PointScreenState();
}

class _PointScreenState extends State<PointScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 외부 브라우저 충전 후 앱 복귀 시 잔액·내역 자동 갱신
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _reload() {
    final p = context.read<PointProvider>();
    p.loadWallet();
    p.loadTransactions();
  }

  /// 충전 = 외부 브라우저 웹 충전 페이지 (IAP 회피, OTT 자동 로그인)
  Future<void> _openCharge() async {
    final opened = await openExternalChargePage();
    if (!opened && mounted) {
      showErrorSnackBar(context, '브라우저를 열 수 없습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('포인트'),
        centerTitle: true,
      ),
      body: Consumer<PointProvider>(
        builder: (context, point, _) {
          if (point.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async {
              await point.loadWallet();
              await point.loadTransactions();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildWalletCard(point)),
                SliverToBoxAdapter(child: _buildChargeButton()),
                SliverToBoxAdapter(child: _buildInfoBanner()),
                SliverToBoxAdapter(child: _buildPlanUpgradeCard()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('거래 내역', style: AppTextStyles.h3),
                  ),
                ),
                if (point.transactions.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyTransactions())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _TransactionTile(tx: point.transactions[index]),
                      childCount: point.transactions.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(PointProvider point) {
    final wallet = point.wallet;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                '내 포인트 잔액',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '1P = 1원',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatNumber(wallet?.balance ?? 0)} P',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          // expiring_soon 안내 (7일 내 만료 예정 합계)
          if ((wallet?.expiringSoon ?? 0) > 0)
            ..._buildExpiringSoon(wallet!.expiringSoon),
        ],
      ),
    );
  }

  List<Widget> _buildExpiringSoon(int amount) {
    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '곧 만료 예정: ${_formatNumber(amount)}P (7일 이내)',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// 충전 버튼 — 외부 브라우저로 웹 충전 페이지 오픈 (§5-1)
  Widget _buildChargeButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ElevatedButton.icon(
        onPressed: _openCharge,
        icon: const Icon(Icons.open_in_new, size: 18),
        label: const Text('포인트 충전하기'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.accent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '포인트 충전 안내',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '충전은 브라우저의 웹 충전 페이지에서 진행됩니다.\n충전 완료 후 앱으로 돌아오면 잔액이 자동 갱신됩니다.\n플랜 구독·이벤트 적립으로도 포인트를 모을 수 있습니다.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanUpgradeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('플랜별 포인트 혜택', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          // v2.5: 플랜별 포인트 + 최대 멤버 수 함께 표시
          _PlanRow(
            icon: Icons.person_outline,
            plan: 'Free',
            desc: '0P · 명함 3장 · 그룹 최대 2명 관리',
            color: AppColors.textSecondary,
          ),
          const Divider(height: 16),
          _PlanRow(
            icon: Icons.workspace_premium,
            plan: 'Pro',
            desc: '10,000P/월 · 명함 10장 · 최대 10명 관리',
            color: AppColors.accent,
          ),
          const Divider(height: 16),
          _PlanRow(
            icon: Icons.business,
            plan: 'Business',
            desc: '500,000P/월 · 명함 무제한 · 멤버 무제한',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}


// ── 거래내역 타일 ──────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final PointTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isEarn = tx.isEarn;
    final amountText = isEarn ? '+${tx.amount}P' : '${tx.amount}P';
    final amountColor = isEarn ? AppColors.success : AppColors.error;

    String dateStr = '';
    final dt = tryParseServerDate(tx.createdAt);
    if (dt != null) {
      dateStr = '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isEarn ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarn ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: AppTextStyles.body1),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // v2.8: 거래 타입 레이블 배지
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isEarn ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tx.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: isEarn ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(dateStr, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountText,
                  style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text('잔액 ${tx.balanceAfter}P',
                  style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 빈 거래내역 ────────────────────────────────────────
class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text('거래 내역이 없습니다.', style: AppTextStyles.body2),
        ],
      ),
    );
  }
}

// ── 플랜 행 ────────────────────────────────────────────
class _PlanRow extends StatelessWidget {
  final IconData icon;
  final String plan;
  final String desc;
  final Color color;
  const _PlanRow({
    required this.icon,
    required this.plan,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(plan,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(desc, style: AppTextStyles.caption),
        ),
      ],
    );
  }
}
