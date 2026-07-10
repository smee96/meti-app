// SNS 플랫폼 대소문자 매칭 회귀 테스트 (BUG-AOS-001, QA 2026-07-09)
//
// 이력:
//   - 생성 화면은 SNS 플랫폼을 'Instagram'/'GitHub'/'Twitter/X' 처럼 첫 글자
//     대문자로 저장하는데, 공개 뷰어 _snsInfo() 가 소문자 case로만 매칭해
//     앱에서 만든 명함의 SNS 아이콘이 전부 기본 링크 아이콘으로 깨졌음.
//   - 수정: public_card_screen._snsInfo 가 toLowerCase() 정규화 + 'twitter/x'
//     별칭 case 처리 (card_detail의 _SnsDetailIcon과 동일 정책).
// 이 테스트는 수정 후 기대 동작(대문자 저장 형식도 전용 아이콘 표시)을 고정한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/core/api/mock/mock_data.dart';
import 'package:meti_app/features/cards/screens/public_card_screen.dart';

Map<String, dynamic> _publicCard({
  required int id,
  required List<Map<String, dynamic>> sns,
}) => {
      'id': id,
      'user_id': 1,
      'group_id': null,
      'card_type': 'personal',
      'name': 'SNS Case Test',
      'title': 'QA Engineer',
      'company': 'ELID QA',
      'email': 'pro@meti.dev',
      'phone': null,
      'website': null,
      'bio': null,
      'avatar_url': null,
      'template_id': 'default',
      'is_primary': 0,
      'is_public': 1,
      'is_active': 1,
      'tags': const [],
      'sns_links': sns,
      'created_at': '2026-07-09 00:00:00',
      'updated_at': '2026-07-09 00:00:00',
      'sns_count': sns.length,
    };

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // 앱이 실제로 저장하는 형태(첫 글자 대문자) — id 8001
    MockStore.cards.add(_publicCard(id: 8001, sns: [
      {'platform': 'Instagram', 'url': 'https://instagram.com/elid_qa', 'sort_order': 0},
      {'platform': 'GitHub', 'url': 'https://github.com/elid-qa', 'sort_order': 1},
      {'platform': 'Twitter/X', 'url': 'https://x.com/elid_qa', 'sort_order': 2},
    ]));
    // mock 시드가 쓰는 소문자 — id 8002
    MockStore.cards.add(_publicCard(id: 8002, sns: [
      {'platform': 'instagram', 'url': 'https://instagram.com/elid_qa', 'sort_order': 0},
      {'platform': 'github', 'url': 'https://github.com/elid-qa', 'sort_order': 1},
    ]));
  });

  tearDown(() {
    MockStore.cards.removeWhere((c) => c['id'] == 8001 || c['id'] == 8002);
  });

  testWidgets('앱 저장 형식(대문자) SNS도 공개 뷰어에서 전용 아이콘으로 표시된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PublicCardScreen(cardId: 8001)),
    );
    await tester.pumpAndSettle();

    // 카드 로드 확인
    expect(find.text('SNS Case Test'), findsOneWidget);

    // 대문자 플랫폼도 소문자 정규화로 전용 아이콘 매칭
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget,
        reason: 'Instagram 전용 아이콘');
    expect(find.byIcon(Icons.code), findsOneWidget, reason: 'GitHub 전용 아이콘');
    expect(find.byIcon(Icons.alternate_email), findsOneWidget,
        reason: 'Twitter/X 전용 아이콘');

    // 기본 link 아이콘 폴백 없음
    expect(find.byIcon(Icons.link), findsNothing,
        reason: '전용 아이콘 매칭 실패 폴백이 없어야 함');

    // 'Twitter/X' 는 친화 표기 'Twitter / X' 로 표시
    expect(find.text('Twitter / X'), findsOneWidget);
    expect(find.text('Twitter/X'), findsNothing);
  });

  testWidgets('소문자 SNS(mock 시드 형식)도 계속 정상 표시 (회귀 방지)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PublicCardScreen(cardId: 8002)),
    );
    await tester.pumpAndSettle();

    expect(find.text('SNS Case Test'), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byIcon(Icons.code), findsOneWidget);
    expect(find.byIcon(Icons.link), findsNothing);
  });
}
