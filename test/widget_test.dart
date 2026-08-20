import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/core/constants/app_constants.dart';
import 'package:meti_app/main.dart';

void main() {
  testWidgets('ELID app smoke test — 비로그인 랜딩', (WidgetTester tester) async {
    // 온보딩을 이미 본 상태로 둔다. 그러지 않으면 스플래시가 인트로로 넘어가
    // (최대 3회 자동 노출) 랜딩 버튼에 도달하지 않는다.
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingCompleted: true,
    });

    await tester.pumpWidget(const ElidApp());
    expect(find.byType(ElidApp), findsOneWidget);

    // 스플래시 최소 표시 2초 소진 후 비로그인 랜딩 버튼 확인
    // (브랜드 워드마크는 스플래시 사진에 포함되어 텍스트 위젯이 아님)
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('ELID by METI'), findsOneWidget);
  });

  testWidgets('온보딩 미완료 사용자는 인트로를 먼저 본다', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ElidApp());
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    // 인트로로 넘어갔으므로 랜딩 버튼은 아직 없다
    expect(find.text('시작하기'), findsNothing);
  });
}
