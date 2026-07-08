import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/features/cards/screens/public_card_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('공개 명함 1뎁스: 기본 정보 + 상세 이력 진입 타일', (tester) async {
    // mock 모드: 존재하지 않는 id → career/education/skill/keyword 태그가 있는 더미 명함
    await tester.pumpWidget(
      const MaterialApp(home: PublicCardScreen(cardId: 999)),
    );
    await tester.pumpAndSettle();

    // 1뎁스: 기본 명함 정보
    expect(find.text('홍길동'), findsOneWidget);
    expect(find.text('test@meti.dev'), findsOneWidget);

    // 1뎁스에는 경력/학력 섹션이 직접 노출되지 않는다
    expect(find.text('경력'), findsNothing);
    expect(find.text('학력'), findsNothing);

    // 상세 이력 진입 타일
    expect(find.text('상세 이력'), findsOneWidget);
    expect(find.textContaining('경력 1'), findsOneWidget);

    // 2뎁스 진입 (타일이 화면 밖일 수 있어 스크롤 후 탭)
    await tester.ensureVisible(find.text('상세 이력'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('상세 이력'));
    await tester.pumpAndSettle();

    // 2뎁스: 경력·학력·스킬·키워드 섹션
    expect(find.text('경력'), findsOneWidget);
    expect(find.text('학력'), findsOneWidget);
    expect(find.text('스킬'), findsOneWidget);
    expect(find.text('키워드'), findsOneWidget);
    expect(find.text('METI Corp · 시니어 개발자 · 2024~현재'), findsOneWidget);
    expect(find.text('서울대학교 컴퓨터공학과 · 2018 졸업'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
  });
}
