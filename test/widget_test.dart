import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/main.dart';

void main() {
  testWidgets('ELID app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ElidApp());
    expect(find.byType(ElidApp), findsOneWidget);

    // 스플래시 최소 표시 2초 소진 후 비로그인 랜딩 버튼 확인
    // (브랜드 워드마크는 스플래시 사진에 포함되어 텍스트 위젯이 아님)
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('ELID by METI'), findsOneWidget);
  });
}
