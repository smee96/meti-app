import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/main.dart';

void main() {
  testWidgets('ELID app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ElidApp());
    expect(find.byType(ElidApp), findsOneWidget);

    // 스플래시 로고 표시 타이머(1.4s) 소진 후 워드마크 확인
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('ELID', findRichText: true), findsWidgets);
  });
}
