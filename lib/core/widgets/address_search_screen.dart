// address_search_screen.dart — 다음(카카오) 우편번호 주소검색
// webview_flutter로 Daum Postcode 위젯을 임베드하고, 선택 결과를
// JS 채널로 받아 AddressResult 로 pop 한다. (인터넷 필요)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 주소검색 결과 (우편번호 + 도로명/지번 주소)
class AddressResult {
  final String zonecode; // 우편번호 (5자리)
  final String address; // 도로명 우선, 없으면 지번
  const AddressResult({required this.zonecode, required this.address});
}

/// 사용:
///   `final r = await Navigator.push<AddressResult>(context,`
///   `  MaterialPageRoute(builder: (_) => const AddressSearchScreen()));`
///   선택 시 `r.zonecode`(우편번호)·`r.address`(주소)를 채운다.
class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  // Daum Postcode 임베드 HTML. 프로토콜 상대경로(//)는 about:blank 기준에서
  // 실패하므로 https:// 절대경로로 스크립트를 불러온다.
  static const String _html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
</head>
<body style="margin:0;padding:0;">
  <div id="wrap" style="width:100%;height:100vh;"></div>
  <script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
  <script>
    function initPostcode() {
      new daum.Postcode({
        oncomplete: function(data) {
          var addr = data.roadAddress || data.jibunAddress || '';
          AddressChannel.postMessage(JSON.stringify({
            zonecode: data.zonecode || '',
            address: addr
          }));
        },
        width: '100%',
        height: '100%'
      }).embed(document.getElementById('wrap'));
    }
    window.onload = initPostcode;
  </script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'AddressChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            final result = AddressResult(
              zonecode: (data['zonecode'] ?? '').toString(),
              address: (data['address'] ?? '').toString(),
            );
            if (mounted) Navigator.pop(context, result);
          } catch (_) {
            if (mounted) Navigator.pop(context);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadHtmlString(_html, baseUrl: 'https://postcode.map.daum.net');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주소 검색')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
