import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meti_app/core/api/api_client.dart';
import 'package:meti_app/core/constants/app_constants.dart';
import 'package:meti_app/features/chat/screens/chat_list_screen.dart';
import 'package:meti_app/features/chat/screens/chat_room_screen.dart';

/// mock 로그인 후 토큰·유저ID를 prefs에 저장 (test@meti.dev = user 1, free)
Future<void> _loginAsTestUser() async {
  final api = ApiClient();
  final res = await api.post('/auth/login',
      body: {'email': 'test@meti.dev', 'password': 'MetiTest1234!'},
      auth: false);
  final data = res['data'] as Map<String, dynamic>;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(AppConstants.keyAccessToken, data['access_token']);
  await prefs.setString(AppConstants.keyRefreshToken, data['refresh_token']);
  await prefs.setInt(AppConstants.keyUserId, (data['user'] as Map)['id'] as int);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('mock 채팅 API: 명함 미교환 403 / 교환 상대 방 생성 / 전송·삭제', () async {
    await _loginAsTestUser();
    final api = ApiClient();

    // 명함 미교환(user 3) → 403
    try {
      await api.post('/chat/direct', body: {'target_user_id': 3});
      fail('403이 발생해야 합니다');
    } on ApiException catch (e) {
      expect(e.statusCode, 403);
      expect(e.message, contains('명함을 교환한'));
    }

    // 교환된 상대(user 2) → 기존 방(1) 반환
    final direct = await api.post('/chat/direct', body: {'target_user_id': 2});
    expect(direct['success'], true);
    final roomId = (direct['data'] as Map)['id'] as int;
    expect(roomId, 1);

    // 목록: retention 7일(free) + unread 배지
    final rooms = await api.get('/chat');
    expect(rooms['chat_retention_days'], 7);
    expect((rooms['data'] as List).length, 1);

    // 메시지 전송 → 최신순 조회 첫 항목으로 반영
    final sent = await api.post('/chat/$roomId/messages',
        body: {'content': '테스트 메시지', 'message_type': 'text'});
    final sentId = (sent['data'] as Map)['id'] as int;
    final msgs = await api.get('/chat/$roomId/messages');
    expect((msgs['data'] as List).first['id'], sentId);

    // 본인 메시지 삭제 → is_deleted 소프트 삭제
    final del = await api.delete('/chat/$roomId/messages/$sentId');
    expect(del['success'], true);
    final after = await api.get('/chat/$roomId/messages');
    expect((after['data'] as List).first['is_deleted'], true);

    // 신고/차단 API 정상 응답
    final report = await api.post('/chat/report', body: {
      'target_type': 'user', 'target_id': 2, 'reason': '스팸/광고',
    });
    expect(report['success'], true);
  });

  testWidgets('채팅 목록: 방·보관기간 배너 표시 후 방 진입', (tester) async {
    await tester.runAsync(_loginAsTestUser);

    await tester.pumpWidget(const MaterialApp(home: ChatListScreen()));
    // mock 응답 지연(400ms) 소화
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('김프로'), findsOneWidget);
    expect(find.textContaining('무료 플랜은 대화가'), findsOneWidget);

    // 방 진입
    await tester.tap(find.text('김프로'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.byType(ChatRoomScreen), findsOneWidget);
    expect(find.text('반갑습니다, 김프로님! 어떤 일로 연락 주셨나요?'), findsOneWidget);
    // 명함 공유 메시지 + 파일 첨부 메시지 렌더링
    expect(find.text('명함 보기'), findsOneWidget);
    expect(find.text('ELID_제휴제안서.pdf'), findsOneWidget);

    // 폴링 타이머 정리
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
