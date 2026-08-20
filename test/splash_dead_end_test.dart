import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/main.dart';

/// 실기기 회귀 (2026-08-20)
///
/// 온보딩 마지막 장의 "이미 계정이 있으신가요? 로그인"은 pushReplacement라
/// 스택이 [스플래시, 로그인]이 된다. 이때 스플래시는 사용자를 낚아채지 않으려고
/// 시작 흐름을 중단하는데, 시작 버튼을 띄우지 않고 끝내면 **뒤로가기로 돌아왔을 때
/// 로딩 인디케이터만 도는 막다른 화면**이 된다.
void main() {
  testWidgets('온보딩 → 로그인 → 뒤로가기 시 스플래시가 무한 로딩으로 남지 않는다',
      (WidgetTester tester) async {
    // 온보딩 미완료 = 첫 실행 경로
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ElidApp());
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pumpAndSettle();

    // 스플래시가 온보딩을 자동으로 띄운다
    expect(find.text('건너뛰기'), findsOneWidget,
        reason: '첫 실행이면 온보딩이 노출돼야 한다');

    // 마지막 장까지 이동
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }

    // "이미 계정이 있으신가요?  로그인" → pushReplacement(login)
    await tester.tap(find.textContaining('로그인'));
    await tester.pumpAndSettle();

    // 로그인 화면 위에서 뒤로 → 스플래시로 돌아온다
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // 핵심: 시작 버튼이 있어야 한다. 없으면 앱을 껐다 켜는 수밖에 없다.
    expect(find.text('시작하기'), findsOneWidget,
        reason: '스플래시로 돌아왔을 때 진행할 수단이 있어야 한다');
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: '무한 로딩 인디케이터가 남아 있으면 안 된다');
  });
}
