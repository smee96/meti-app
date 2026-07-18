import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';

/// NFC 실물카드 신청 내역 (핸드오프 §5-2)
/// status: pending(신청됨) / approved(제작중) / issued(발급완료 + 운송장)
class NfcApplicationsScreen extends StatefulWidget {
  const NfcApplicationsScreen({super.key});

  @override
  State<NfcApplicationsScreen> createState() => _NfcApplicationsScreenState();
}

class _NfcApplicationsScreenState extends State<NfcApplicationsScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await _api.get('/cards/nfc/applications');
      if (mounted && response['success'] == true) {
        setState(() => _applications = response['data'] as List);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('NFC 카드 신청 내역')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _applications.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.nfc,
                  title: '신청 내역이 없어요',
                  subtitle: '명함 상세에서 NFC 실물카드를\n신청할 수 있습니다.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _applications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ApplicationTile(
                        app: Map<String, dynamic>.from(_applications[i] as Map)),
                  ),
                ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final Map<String, dynamic> app;
  const _ApplicationTile({required this.app});

  String get _statusLabel {
    switch (app['status'] as String?) {
      case 'pending':
        return '신청됨';
      case 'approved':
        return '제작중';
      case 'issued':
        return '발급완료';
      default:
        return app['status'] as String? ?? '';
    }
  }

  Color get _statusColor {
    switch (app['status'] as String?) {
      case 'pending':
        return AppColors.info;
      case 'approved':
        return AppColors.accent;
      case 'issued':
        return AppColors.success;
      default:
        return AppColors.textTertiary;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatNumber(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    final trackingNo = app['tracking_no'] as String?;
    final carrier = app['carrier'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.nfc, color: _statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['card_name'] as String? ?? '명함',
                      style: AppTextStyles.body1
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(app['created_at'] as String?)} · ${_formatNumber(app['amount'] as int? ?? 0)}P',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 배송지
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${app['shipping_name']} · ${app['shipping_address']}'
                  '${app['shipping_detail'] != null ? ' ${app['shipping_detail']}' : ''}',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          // 운송장 (발급완료 시)
          if (trackingNo != null && trackingNo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  '${carrier ?? '택배'} $trackingNo',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.success),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
