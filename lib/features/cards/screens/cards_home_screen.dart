import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../widgets/business_card_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import 'card_create_screen.dart';
import 'card_detail_screen.dart';
import 'qr_scan_screen.dart';
import 'contacts_screen.dart';

class CardsHomeScreen extends StatefulWidget {
  const CardsHomeScreen({super.key});

  @override
  State<CardsHomeScreen> createState() => _CardsHomeScreenState();
}

class _CardsHomeScreenState extends State<CardsHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardsProvider>().loadMyCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const MetiLogo(size: 32, showText: true),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'QR 스캔',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScanScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.contacts_outlined),
            tooltip: '명함첩',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer2<AuthProvider, CardsProvider>(
        builder: (context, auth, cards, _) {
          return RefreshIndicator(
            onRefresh: cards.loadMyCards,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // 인사 영역
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요,',
                          style: AppTextStyles.body2,
                        ),
                        Row(
                          children: [
                            Text(
                              auth.user?.name ?? '사용자',
                              style: AppTextStyles.h2,
                            ),
                            const SizedBox(width: 8),
                            if (auth.user != null)
                              PlanBadge(plan: auth.user!.plan),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 빠른 액션
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.qr_code,
                                label: 'QR 스캔',
                                color: AppColors.primary,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const QrScanScreen()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.contacts_outlined,
                                label: '명함첩',
                                color: AppColors.accent,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ContactsScreen()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.add_card_outlined,
                                label: '명함 추가',
                                color: AppColors.success,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const CardCreateScreen()),
                                  );
                                  if (result == true) {
                                    cards.loadMyCards();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // 내 명함 섹션 헤더
                        SectionHeader(
                          title: '내 명함',
                          actionLabel: cards.myCards.isNotEmpty ? '전체보기' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // 명함 목록
                if (cards.isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  )
                else if (cards.myCards.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyCardPrompt(
                        onCreate: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CardCreateScreen()),
                          );
                          if (result == true) cards.loadMyCards();
                        },
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final card = cards.myCards[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: BusinessCardWidget(
                            card: card,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CardDetailScreen(card: card),
                              ),
                            ).then((_) => cards.loadMyCards()),
                          ),
                        );
                      },
                      childCount: cards.myCards.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CardCreateScreen()),
          );
          if (result == true && mounted) {
            final provider = context.read<CardsProvider>();
            provider.loadMyCards();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('명함 만들기'),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCardPrompt extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyCardPrompt({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.credit_card, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('아직 명함이 없어요', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          const Text(
            '첫 번째 디지털 명함을 만들어보세요!\n비즈니스 네트워킹을 시작해보세요.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('첫 번째 명함 만들기'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 44)),
          ),
        ],
      ),
    );
  }
}
