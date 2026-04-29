import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../widgets/business_card_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import 'card_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardsProvider>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('명함첩')),
      body: Consumer<CardsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.contacts.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (provider.contacts.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.contacts_outlined,
              title: '저장된 명함이 없어요',
              subtitle: 'QR 스캔이나 명함 상세에서 명함을\n저장해보세요.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadContacts(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final card = provider.contacts[index];
                return BusinessCardWidget(
                  card: card,
                  isCompact: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CardDetailScreen(card: card)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
