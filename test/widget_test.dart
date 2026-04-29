import 'package:flutter_test/flutter_test.dart';
import 'package:meti_app/main.dart';

void main() {
  testWidgets('METI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MetiApp());
    expect(find.byType(MetiApp), findsOneWidget);
  });
}
