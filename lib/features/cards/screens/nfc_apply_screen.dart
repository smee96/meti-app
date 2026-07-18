import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../widgets/business_card_widget.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/utils/charge_launcher.dart';
import 'nfc_applications_screen.dart';

/// NFC 실물카드 신청 (핸드오프 §5-2)
/// - 결제는 포인트 차감 (IAP 비대상, 앱 내 결제 UI 없음)
/// - 부족 시 400 insufficient_points → 외부 브라우저 충전 유도
/// - 같은 명함에 진행 중 신청 있으면 409
class NfcApplyScreen extends StatefulWidget {
  final CardModel card;
  const NfcApplyScreen({super.key, required this.card});

  @override
  State<NfcApplyScreen> createState() => _NfcApplyScreenState();
}

class _NfcApplyScreenState extends State<NfcApplyScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _zipcodeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  int? _price;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _zipcodeCtrl.dispose();
    _addressCtrl.dispose();
    _detailCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final response = await _api.get('/cards/nfc/config');
      if (mounted && response['success'] == true) {
        setState(
            () => _price = (response['data'] as Map)['price'] as int?);
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _api.post('/cards/nfc/apply', body: {
        'card_id': widget.card.id,
        'shipping_name': _nameCtrl.text.trim(),
        'shipping_phone': _phoneCtrl.text.trim(),
        'shipping_zipcode': _zipcodeCtrl.text.trim(),
        'shipping_address': _addressCtrl.text.trim(),
        if (_detailCtrl.text.trim().isNotEmpty)
          'shipping_detail': _detailCtrl.text.trim(),
        if (_memoCtrl.text.trim().isNotEmpty)
          'shipping_memo': _memoCtrl.text.trim(),
      });
      if (!mounted) return;
      if (response['success'] == true) {
        _showSuccessDialog(response['data'] as Map<String, dynamic>);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.errorCode == 'insufficient_points') {
        _showInsufficientDialog(e.extra ?? {});
      } else {
        showErrorSnackBar(context, e.message);
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '신청 중 오류가 발생했습니다.');
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('신청 완료'),
        content: Text(
          'NFC 실물카드 신청이 완료되었습니다.\n\n'
          '결제 포인트: ${_formatNumber(data['amount'] as int? ?? 0)}P\n'
          '남은 잔액: ${_formatNumber(data['balance_after'] as int? ?? 0)}P\n\n'
          '제작이 시작되면 알려드릴게요.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const NfcApplicationsScreen()),
              );
            },
            child: const Text('신청 내역 보기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true); // 상세 화면 배지 갱신용
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 포인트 부족 → 외부 브라우저 웹 충전 페이지 유도 (§5-1: 앱 내 충전 금지)
  void _showInsufficientDialog(Map<String, dynamic> extra) {
    final required = extra['required'] as int? ?? _price ?? 0;
    final balance = extra['balance'] as int? ?? 0;
    final shortage = extra['shortage'] as int? ?? (required - balance);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('포인트가 부족해요'),
        content: Text(
          '필요 포인트: ${_formatNumber(required)}P\n'
          '보유 포인트: ${_formatNumber(balance)}P\n\n'
          '${_formatNumber(shortage)}P가 부족합니다.\n'
          '웹 충전 페이지에서 충전 후 다시 신청해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openExternalChargePage();
            },
            child: const Text('충전하러 가기'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC 실물카드 신청'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: '신청 내역',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NfcApplicationsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 대상 명함 ──────────────────────────────────
              const Text('신청 명함', style: AppTextStyles.h4),
              const SizedBox(height: 8),
              BusinessCardWidget(card: widget.card, isCompact: true),
              const SizedBox(height: 16),

              // ── 가격 안내 ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.nfc, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _price != null
                                ? '${_formatNumber(_price!)} P'
                                : '가격 불러오는 중...',
                            style: AppTextStyles.h3
                                .copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '결제는 보유 포인트에서 차감됩니다.',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 배송 정보 ──────────────────────────────────
              const Text('배송 정보', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _buildField(_nameCtrl, '받는 사람 *', hint: '홍길동'),
              _buildField(_phoneCtrl, '연락처 *',
                  hint: '010-0000-0000',
                  keyboardType: TextInputType.phone),
              _buildField(_zipcodeCtrl, '우편번호 *',
                  hint: '06134', keyboardType: TextInputType.number),
              _buildField(_addressCtrl, '주소 *', hint: '서울 강남구 테헤란로 123'),
              _buildField(_detailCtrl, '상세 주소', hint: '동/호수 (선택)',
                  required: false),
              _buildField(_memoCtrl, '배송 메모', hint: '부재 시 경비실에 맡겨주세요 (선택)',
                  required: false),
              const SizedBox(height: 24),

              // ── 신청 버튼 ──────────────────────────────────
              ElevatedButton.icon(
                onPressed: _isSubmitting || _price == null ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.nfc),
                label: Text(
                  _price != null
                      ? '${_formatNumber(_price!)}P로 신청하기'
                      : '신청하기',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '· 실물 상품 결제로 인앱결제(IAP) 대상이 아닙니다.\n'
                '· 같은 명함에 진행 중인 신청이 있으면 중복 신청할 수 없습니다.\n'
                '· 발급 완료 시 운송장 번호를 신청 내역에서 확인할 수 있습니다.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '필수 입력 항목입니다.' : null
            : null,
      ),
    );
  }
}
