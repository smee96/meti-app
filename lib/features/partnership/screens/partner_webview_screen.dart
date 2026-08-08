// partner_webview_screen.dart — 제휴 게임 인앱 웹뷰 (해피트리 등)
//
// 구조 (통합 가이드 §0·§3, IAP 컴플라이언스):
// · 게임플레이는 인앱 웹뷰로 구동한다. 진입 시 launch-token(1회용·5분)을
//   발급받아 서버가 만들어준 launch_url을 그대로 연다.
// · 결제는 웹뷰 안에서 하지 않는다 — 게임 호스트 밖으로 나가는 내비게이션과
//   스토어 경로(/store)는 전부 외부 브라우저로 넘긴다.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/partner_service_model.dart';
import '../providers/partnership_provider.dart';

class PartnerWebviewScreen extends StatefulWidget {
  final PartnerService service;

  const PartnerWebviewScreen({super.key, required this.service});

  @override
  State<PartnerWebviewScreen> createState() => _PartnerWebviewScreenState();
}

enum _LaunchStatus { issuing, loading, ready, error }

class _PartnerWebviewScreenState extends State<PartnerWebviewScreen> {
  WebViewController? _controller;
  _LaunchStatus _status = _LaunchStatus.issuing;
  String _errorMessage = '';

  /// 게임 호스트 — launch_url 기준. 이 호스트 밖으로 나가는 내비게이션은
  /// 전부 외부 브라우저로 보낸다(결제·외부 링크 분리).
  String _gameHost = '';

  @override
  void initState() {
    super.initState();
    _launch();
  }

  /// 토큰 발급 → 웹뷰 로드. 재시도·새로고침도 이 경로를 탄다 —
  /// launch-token은 1회용(jti)이라 항상 새로 발급받아야 한다.
  Future<void> _launch() async {
    setState(() {
      _status = _LaunchStatus.issuing;
      _errorMessage = '';
    });

    final PartnerLaunchTicket ticket;
    try {
      ticket = await context
          .read<PartnershipProvider>()
          .issueLaunchToken(widget.service.id);
    } on ApiException catch (e) {
      setState(() {
        _status = _LaunchStatus.error;
        _errorMessage = e.message;
      });
      return;
    } catch (_) {
      setState(() {
        _status = _LaunchStatus.error;
        _errorMessage = '접속 준비에 실패했습니다. 네트워크를 확인해주세요.';
      });
      return;
    }

    final launchUrl = ticket.launchUrl;
    if (launchUrl == null || launchUrl.isEmpty) {
      setState(() {
        _status = _LaunchStatus.error;
        _errorMessage = '진입 주소를 받지 못했습니다. 잠시 후 다시 시도해주세요.';
      });
      return;
    }
    if (!mounted) return;

    final uri = Uri.parse(launchUrl);
    _gameHost = uri.host;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigation,
          onPageFinished: (_) {
            if (mounted && _status == _LaunchStatus.loading) {
              setState(() => _status = _LaunchStatus.ready);
            }
          },
          onWebResourceError: (error) {
            // 서브리소스 실패는 무시 — 첫 페이지 자체가 안 뜬 경우만 에러 처리
            if (error.isForMainFrame == false) return;
            if (mounted && _status != _LaunchStatus.ready) {
              setState(() {
                _status = _LaunchStatus.error;
                _errorMessage = '페이지를 불러오지 못했습니다.';
              });
            }
          },
        ),
      )
      ..loadRequest(uri);

    setState(() {
      _controller = controller;
      _status = _LaunchStatus.loading;
    });
  }

  /// 결제·외부 링크 분리 규칙:
  /// · http(s) 외 스킴(intent:, market: 등) → 외부 처리 시도
  /// · 게임 호스트 밖 || 스토어 경로(/store) → 외부 브라우저
  /// · 그 외(게임 호스트 안) → 웹뷰에서 계속
  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    final isHttp = uri.scheme == 'http' || uri.scheme == 'https';
    final isGameHost = isHttp && uri.host == _gameHost;
    final isStorePath = uri.path == '/store' || uri.path.startsWith('/store/');

    if (isGameHost && !isStorePath) return NavigationDecision.navigate;

    launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  Future<void> _handleBack() async {
    final controller = _controller;
    if (controller != null &&
        _status == _LaunchStatus.ready &&
        await controller.canGoBack()) {
      controller.goBack();
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.service.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
              onPressed: _status == _LaunchStatus.issuing ? null : _launch,
            ),
          ],
        ),
        body: switch (_status) {
          _LaunchStatus.issuing => const _CenteredProgress(label: '접속 준비 중…'),
          _LaunchStatus.error => _ErrorView(
              message: _errorMessage,
              onRetry: _launch,
            ),
          _ => Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_status == _LaunchStatus.loading)
                  const _CenteredProgress(label: '불러오는 중…'),
              ],
            ),
        },
      ),
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  final String label;
  const _CenteredProgress({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              message.isEmpty ? '접속에 실패했습니다.' : message,
              style: AppTextStyles.body1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
