import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../../../core/theme/app_theme.dart';

class QrShowScreen extends StatefulWidget {
  final CardModel card;
  const QrShowScreen({super.key, required this.card});

  @override
  State<QrShowScreen> createState() => _QrShowScreenState();
}

class _QrShowScreenState extends State<QrShowScreen> {
  String? _qrUrl;
  String? _expiresAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQr();
  }

  Future<void> _generateQr() async {
    setState(() => _isLoading = true);
    final result =
        await context.read<CardsProvider>().generateQrToken(widget.card.id);
    if (!mounted) return;
    setState(() {
      _qrUrl = result?['qr_url'] as String?;
      _expiresAt = result?['expires_at'] as String?;
      _isLoading = false;
    });
  }

  String get _qrData {
    if (_qrUrl != null) {
      return 'https://meti.app$_qrUrl';
    }
    return 'https://meti.app/cards/public/${widget.card.id}';
  }

  bool get _isPublicCard => widget.card.isPublic == 1;

  // BUG-AOS-004: 만료 문구를 expires_at 기반으로 동적 계산
  String? get _expiryLabel {
    if (_expiresAt == null) return null;
    final expires = DateTime.tryParse(_expiresAt!);
    if (expires == null) return null;
    final remaining = expires.difference(DateTime.now());
    if (remaining.isNegative) return '만료됨 — 새로 생성해주세요';
    if (remaining.inHours >= 1) return '${remaining.inHours}시간 유효';
    if (remaining.inMinutes >= 1) return '${remaining.inMinutes}분 유효';
    return '곧 만료 — 새로 생성해주세요';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('QR 코드', style: TextStyle(color: Colors.white)),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 카드 정보
                Text(
                  widget.card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.card.title != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.card.title!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7), fontSize: 15),
                    ),
                  ),
                if (widget.card.company != null)
                  Text(
                    widget.card.company!,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                  ),
                const SizedBox(height: 32),

                // QR 코드
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      : QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 200,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primaryDark,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // 만료 시간 (expires_at 기반)
                if (_expiryLabel != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _expiryLabel!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                // 비공개 명함 안내 (상세 화면 공유 차단과 정책 통일)
                if (!_isPublicCard) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '비공개 명함입니다. 공개로 전환해야 상대가 열람할 수 있어요.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // 링크 공유 버튼 (비공개 명함은 상세 화면과 동일하게 차단)
                ElevatedButton.icon(
                  onPressed: (_isLoading || !_isPublicCard)
                      ? null
                      : () => Share.share(
                            '[ELID] ${widget.card.name}님의 명함\n$_qrData',
                            subject: 'ELID 명함 — ${widget.card.name}',
                          ),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('링크 공유'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(180, 44),
                  ),
                ),
                const SizedBox(height: 12),

                // 새로고침 버튼
                OutlinedButton.icon(
                  onPressed: _generateQr,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('QR 새로 생성',
                      style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Colors.white, width: 1.5),
                    minimumSize: const Size(180, 44),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
