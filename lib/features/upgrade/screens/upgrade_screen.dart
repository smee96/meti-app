import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';


/// 플랜 업그레이드 화면
/// - 한도 초과 다이얼로그에서 "Pro 구독하기" 버튼 누를 때 진입
/// - 현재 플랜 확인 + Pro/Business 플랜 비교 + 구독 신청
class UpgradeScreen extends StatelessWidget {
  /// 진입 출처 (카드 한도 / 멤버 한도 등 컨텍스트 표시용)
  final String? fromContext;
  const UpgradeScreen({super.key, this.fromContext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('플랜 업그레이드'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 컨텍스트 안내 배너 (한도 초과 시)
            if (fromContext != null) _ContextBanner(fromContext: fromContext!),
            if (fromContext != null) const SizedBox(height: 16),

            // 헤더
            _buildHeader(),
            const SizedBox(height: 24),

            // 플랜 카드들
            _PlanCard(
              plan: 'Free',
              price: '무료',
              icon: Icons.person_outline,
              color: AppColors.textSecondary,
              isCurrent: true,
              features: const [
                '명함 최대 3장',
                '그룹 멤버 최대 2명 관리',
                '기본 명함 템플릿',
                'QR 코드 공유',
              ],
              onSelect: null,
            ),
            const SizedBox(height: 12),

            _PlanCard(
              plan: 'Pro',
              price: '10,000P / 월',
              icon: Icons.workspace_premium,
              color: AppColors.accent,
              isCurrent: false,
              isRecommended: true,
              features: const [
                '명함 최대 10장',
                '그룹 멤버 최대 10명 관리',
                '고급 명함 템플릿 전체 이용',
                '월 10,000P 자동 지급',
                '그룹 포인트 이체 기능',
                '우선 고객 지원',
              ],
              onSelect: () => _showSubscribeDialog(context, 'Pro', 10000),
            ),
            const SizedBox(height: 12),

            _PlanCard(
              plan: 'Business',
              price: '500,000P / 월',
              icon: Icons.business,
              color: AppColors.primary,
              isCurrent: false,
              features: const [
                '명함 무제한',
                '그룹 멤버 무제한 관리',
                '전용 명함 디자인 제작',
                '월 500,000P 자동 지급',
                '그룹 포인트 이체 기능',
                '이벤트 개설 권한',
                '전담 고객 매니저',
              ],
              onSelect: () => _showSubscribeDialog(context, 'Business', 500000),
            ),

            const SizedBox(height: 24),

            // 안내 텍스트
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '• 플랜 구독은 인앱 결제로 처리됩니다 (준비 중)\n'
                '• 구독 취소 시 다음 결제일부터 Free 플랜으로 전환됩니다\n'
                '• 문의: support@meti.app',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.rocket_launch_rounded,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 12),
        const Text('더 많은 기능을 사용해보세요', style: AppTextStyles.h2),
        const SizedBox(height: 6),
        const Text(
          '플랜을 업그레이드하고 비즈니스 네트워킹을 확장하세요',
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showSubscribeDialog(
      BuildContext context, String plan, int pointsPerMonth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              plan == 'Pro' ? Icons.workspace_premium : Icons.business,
              color: plan == 'Pro' ? AppColors.accent : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text('$plan 플랜 구독', style: AppTextStyles.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatNumber(pointsPerMonth)}P / 월',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '현재 인앱 결제 기능은 준비 중입니다.\n'
              '서비스 출시 후 정식 구독이 가능합니다.\n\n'
              '문의사항은 support@meti.app 으로 연락 주세요.',
              style: AppTextStyles.body2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
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

// ── 컨텍스트 배너 (한도 초과 진입 시) ──────────────────────
class _ContextBanner extends StatelessWidget {
  final String fromContext;
  const _ContextBanner({required this.fromContext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fromContext,
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 플랜 카드 ─────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String plan;
  final String price;
  final IconData icon;
  final Color color;
  final bool isCurrent;
  final bool isRecommended;
  final List<String> features;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.plan,
    required this.price,
    required this.icon,
    required this.color,
    required this.isCurrent,
    required this.features,
    this.isRecommended = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended
              ? color
              : isCurrent
                  ? AppColors.border
                  : AppColors.border,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isRecommended
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.surfaceVariant
                  : color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '현재 플랜',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '추천',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(price,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 기능 목록
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: isCurrent
                              ? AppColors.textTertiary
                              : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              color: isCurrent
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isCurrent) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '$plan 플랜 구독하기',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
