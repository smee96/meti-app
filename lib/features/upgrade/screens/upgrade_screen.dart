import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

/// 플랜 업그레이드 화면 (v2.6)
/// - 한도 초과 다이얼로그에서 "Pro 구독하기" 버튼 누를 때 진입
/// - 현재 플랜 확인 + Pro/Business 플랜 비교 + 구독 신청 (Mock 결제)
class UpgradeScreen extends StatefulWidget {
  /// 진입 출처 (카드 한도 / 멤버 한도 등 컨텍스트 표시용)
  final String? fromContext;
  const UpgradeScreen({super.key, this.fromContext});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final ApiClient _api = ApiClient();
  bool _isSubscribing = false;

  // ── 구독 신청 처리 ──────────────────────────────────────
  Future<void> _handleSubscribe(
      BuildContext context, String plan, int pointsPerMonth) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // 결제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              plan == 'pro' ? Icons.workspace_premium : Icons.business,
              color: plan == 'pro' ? AppColors.accent : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '${plan == 'pro' ? 'Pro' : 'Business'} 플랜 구독',
              style: AppTextStyles.h3,
            ),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      const Text(
                        '구독 정보',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 구독 즉시 ${_formatNumber(pointsPerMonth)}P 지급\n'
                    '• 매월 자동 갱신\n'
                    '• 취소 시 다음 결제일부터 Free 전환',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '※ 현재 Mock 결제로 진행됩니다.\n'
              '실서비스 출시 후 인앱 결제(Apple/Google)로 전환됩니다.',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('구독 시작'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubscribing = true);
    try {
      // v2.8: 플랫폼 감지 후 Apple/Google 엔드포인트 분기
      // iOS/macOS → verify-apple (Apple IAP receipt)
      // Android   → verify-google (Google Play purchase token)
      // Web/기타  → verify-apple (Mock 기본값)
      final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
      final String verifyEndpoint = isAndroid
          ? '/payments/subscription/verify-google'
          : '/payments/subscription/verify-apple';
      final String receiptKey = isAndroid ? 'purchase_token' : 'receipt_data';
      final res = await _api.post(
        verifyEndpoint,
        body: {
          'plan': plan,
          receiptKey: 'mock-receipt-${DateTime.now().millisecondsSinceEpoch}',
        },
      );
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final granted = data['points_granted'] as int? ?? pointsPerMonth;
        final newBalance = data['new_balance'] as int? ?? 0;

        await navigator.push(
          PageRouteBuilder(
            opaque: false,
            barrierDismissible: false,
            barrierColor: Colors.black54,
            pageBuilder: (dlgCtx, _, __) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.success, Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('구독 완료!',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    '${plan == 'pro' ? 'Pro' : 'Business'} 플랜이 활성화되었습니다.',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '+${_formatNumber(granted)}P 지급 완료',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '현재 잔액: ${_formatNumber(newBalance)}P',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      navigator.pop(); // 성공 다이얼로그 닫기
                      navigator.pop(); // UpgradeScreen 닫기
                    },
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(res['message']?.toString() ?? '구독 처리 실패'),
          backgroundColor: AppColors.error,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('구독 처리 중 오류가 발생했습니다.'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubscribing = false);
    }
  }

  // ── 구독 취소 처리 ──────────────────────────────────────
  Future<void> _handleCancelSubscription(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('구독 취소'),
        content: const Text(
            '구독을 취소하시겠습니까?\n다음 결제일부터 Free 플랜으로 전환됩니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('유지하기')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final res = await _api.delete('/payments/subscription');
      if (!mounted) return;
      if (res['success'] == true) {
        messenger.showSnackBar(SnackBar(
          content: Text(res['message'] as String? ?? '구독이 취소되었습니다.'),
          backgroundColor: AppColors.success,
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('처리 중 오류가 발생했습니다.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 플랜은 로그인 사용자 정보에서 읽는다 (free | pro | business)
    final currentPlan = context.watch<AuthProvider>().user?.plan ?? 'free';
    // 추천 배지는 "바로 다음 단계" 플랜에만 붙인다
    final recommendedPlan = currentPlan == 'free'
        ? 'pro'
        : (currentPlan == 'pro' ? 'business' : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('플랜 업그레이드'),
        centerTitle: true,
        actions: [
          // 구독 취소는 유료 플랜 구독 중일 때만 노출
          if (currentPlan != 'free')
            TextButton(
              onPressed: () => _handleCancelSubscription(context),
              child: const Text(
                '구독 취소',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 컨텍스트 안내 배너 (한도 초과 시)
                if (widget.fromContext != null)
                  _ContextBanner(fromContext: widget.fromContext!),
                if (widget.fromContext != null)
                  const SizedBox(height: 16),

                // 헤더
                _buildHeader(),
                const SizedBox(height: 24),

                // Free 플랜 (현재)
                _PlanCard(
                  plan: 'Free',
                  planKey: 'free',
                  price: '무료',
                  icon: Icons.person_outline,
                  color: AppColors.textSecondary,
                  isCurrent: currentPlan == 'free',
                  features: const [
                    '명함 기본 1장 (추가 5,000원/장)',  // v2.7
                    '그룹 멤버 최대 2명 관리',
                    '기본 명함 템플릿',
                    'QR 코드 공유',
                  ],
                  onSelect: null,
                  isLoading: false,
                ),
                const SizedBox(height: 12),

                // Pro 플랜
                _PlanCard(
                  plan: 'Pro',
                  planKey: 'pro',
                  price: '10,000P / 월',
                  icon: Icons.workspace_premium,
                  color: AppColors.accent,
                  isCurrent: currentPlan == 'pro',
                  isRecommended: recommendedPlan == 'pro',
                  features: const [
                    '명함 기본 3장 (추가 5,000원/장)',  // v2.7
                    '그룹 멤버 최대 10명 관리',
                    '고급 명함 템플릿 전체 이용',
                    '월 10,000P 자동 지급',
                    '그룹 포인트 이체 기능',
                    '우선 고객 지원',
                  ],
                  onSelect: _isSubscribing
                      ? null
                      : () => _handleSubscribe(context, 'pro', 10000),
                  isLoading: _isSubscribing,
                ),
                const SizedBox(height: 12),

                // Business 플랜
                _PlanCard(
                  plan: 'Business',
                  planKey: 'business',
                  price: '500,000P / 월',
                  icon: Icons.business,
                  color: AppColors.primary,
                  isCurrent: currentPlan == 'business',
                  isRecommended: recommendedPlan == 'business',
                  features: const [
                    '명함 기본 10장 (추가 5,000원/장)',  // v2.7
                    '그룹 멤버 무제한 관리',
                    '전용 명함 디자인 제작',
                    '월 500,000P 자동 지급',
                    '그룹 포인트 이체 기능',
                    '이벤트 개설 권한',
                    '전담 고객 매니저',
                  ],
                  onSelect: _isSubscribing
                      ? null
                      : () => _handleSubscribe(context, 'business', 500000),
                  isLoading: _isSubscribing,
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
                    '• 플랜 구독은 인앱 결제(Apple/Google)로 처리됩니다\n'
                    '• 구독 취소 시 다음 결제일부터 Free 플랜으로 전환됩니다\n'
                    '• 구독 지급 포인트는 다음 갱신일에 만료됩니다 (v2.7)\n'
                    '• 직접 충전·보상 포인트는 90일 후 만료됩니다\n'
                    '• 명함 추가 구매(5,000원/장)는 웹 결제로 처리됩니다\n'
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

          // 구독 처리 중 오버레이
          if (_isSubscribing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        '구독 처리 중...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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

  String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ── 컨텍스트 배너 (한도 초과 진입 시) ───────────────────────
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
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fromContext,
              style: const TextStyle(
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

// ── 플랜 카드 ──────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final String plan;
  final String planKey;
  final String price;
  final IconData icon;
  final Color color;
  final bool isCurrent;
  final bool isRecommended;
  final List<String> features;
  final VoidCallback? onSelect;
  final bool isLoading;

  const _PlanCard({
    required this.plan,
    required this.planKey,
    required this.price,
    required this.icon,
    required this.color,
    required this.isCurrent,
    required this.features,
    required this.isLoading,
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
          color: isRecommended ? color : AppColors.border,
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

          // 기능 목록 + 구독 버튼
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
                // 현재 플랜이거나 신청 대상이 아닌 플랜(예: Pro 구독 중의 Free)은 버튼 숨김
                if (!isCurrent && (onSelect != null || isLoading)) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        disabledBackgroundColor:
                            color.withValues(alpha: 0.4),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              '$plan 플랜 구독하기',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
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
