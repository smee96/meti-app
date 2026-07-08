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

                // 만료 시간
                if (_expiresAt != null)
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
                          '24시간 유효',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // 링크 공유 버튼
                ElevatedButton.icon(
                  onPressed: _isLoading
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
