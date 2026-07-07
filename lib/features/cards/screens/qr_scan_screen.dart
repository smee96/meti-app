import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../routes/app_router.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _isCameraSupported = true;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    } catch (e) {
      setState(() => _isCameraSupported = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null) return;

    setState(() => _isProcessing = true);
    _controller?.stop();

    // QR URL에서 토큰 추출
    // 예: https://meti.app/cards/qr/uuid-token
    final uri = Uri.tryParse(raw);
    String? token;
    if (uri != null && uri.pathSegments.length >= 3) {
      final segments = uri.pathSegments;
      final qrIndex = segments.indexOf('qr');
      if (qrIndex != -1 && qrIndex + 1 < segments.length) {
        token = segments[qrIndex + 1];
      }
    }

    if (token == null) {
      showErrorSnackBar(context, '유효하지 않은 QR 코드입니다.');
      setState(() => _isProcessing = false);
      _controller?.start();
      return;
    }

    final card =
        await context.read<CardsProvider>().getCardByQrToken(token);

    if (!mounted) return;

    if (card != null) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => _CardScanResultDialog(
          card: card,
          onSave: () async {
            final provider = context.read<CardsProvider>();
            final cardId = card.id;
            final success = await provider.saveCard(cardId);
            if (!context.mounted) return;
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
            if (!context.mounted) return;
            if (success) {
              // ignore: use_build_context_synchronously
              showSuccessSnackBar(context, '명함이 저장되었습니다!');
            } else {
              // ignore: use_build_context_synchronously
              showErrorSnackBar(context, '명함 저장에 실패했습니다.');
            }
          },
          onViewDetail: () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              AppRoutes.publicCard,
              arguments: {'card_id': card.id},
            );
          },
        ),
      );
    } else {
      showErrorSnackBar(context, 'QR 코드 스캔 실패. 다시 시도해주세요.');
      setState(() => _isProcessing = false);
      _controller?.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR 스캔', style: TextStyle(color: Colors.white)),
      ),
      body: _isCameraSupported
          ? Stack(
              children: [
                MobileScanner(
                  controller: _controller!,
                  onDetect: _onDetect,
                ),
                // 스캔 오버레이
                CustomPaint(
                  painter: _ScanOverlayPainter(),
                  child: const SizedBox.expand(),
                ),
                // 가이드 텍스트
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Text(
                    'ELID QR 코드를 프레임 안에\n맞춰주세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: Colors.white70, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    '카메라를 사용할 수 없습니다',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '웹 환경에서는 QR 스캔이 지원되지 않습니다',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('돌아가기',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    final scanSize = size.width * 0.65;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: scanSize,
      height: scanSize,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );

    // 코너 표시
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLength = 24.0;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    final dirs = [
      [const Offset(1, 0), const Offset(0, 1)],
      [const Offset(-1, 0), const Offset(0, 1)],
      [const Offset(1, 0), const Offset(0, -1)],
      [const Offset(-1, 0), const Offset(0, -1)],
    ];
    for (var i = 0; i < corners.length; i++) {
      canvas.drawLine(corners[i], corners[i] + dirs[i][0] * cornerLength, cornerPaint);
      canvas.drawLine(corners[i], corners[i] + dirs[i][1] * cornerLength, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CardScanResultDialog extends StatelessWidget {
  final dynamic card;
  final VoidCallback onSave;
  final VoidCallback onViewDetail;

  const _CardScanResultDialog({
    required this.card,
    required this.onSave,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          const SizedBox(height: 12),
          const Text('명함 스캔 완료!', style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(card.name ?? '', style: AppTextStyles.h4),
          if (card.title != null)
            Text(card.title, style: AppTextStyles.body2),
          if (card.company != null)
            Text(card.company, style: AppTextStyles.body2),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: onViewDetail,
          child: const Text('자세히 보기'),
        ),
        ElevatedButton(
          onPressed: onSave,
          child: const Text('명함첩에 저장'),
        ),
      ],
    );
  }
}
