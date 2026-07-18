// mock_api.dart — 얇은 진입점 (thin entry-point)
// 실제 로직은 mock/ 하위 파일로 분리되었습니다.
// api_client.dart 가 참조하는 MockUsers / MockApiException 이름을
// 그대로 유지해 api_client.dart 수정을 최소화합니다.

export 'mock/mock_data.dart';       // MockApiException, MockStore
export 'mock/mock_auth.dart';      // MockAuth
export 'mock/mock_cards.dart';     // MockCards
export 'mock/mock_chat.dart';      // MockChat — 채팅 보강
export 'mock/mock_groups.dart';    // MockGroups
export 'mock/mock_lessons.dart';   // MockLessons
export 'mock/mock_payments.dart';  // MockPayments
export 'mock/mock_schedules.dart'; // MockSchedules  — v3.0

// ── MockUsers 호환 어댑터 ───────────────────────────────────────
// api_client.dart 가 MockUsers.xxx() 형식으로 호출하므로
// 각 도메인 클래스를 위임(forward)하는 어댑터 클래스를 제공합니다.
// 추후 api_client.dart 를 도메인 클래스로 직접 교체하면 이 클래스는 삭제합니다.

import 'mock/mock_auth.dart';
import 'mock/mock_cards.dart';
import 'mock/mock_chat.dart';
import 'mock/mock_groups.dart';
import 'mock/mock_lessons.dart';
import 'mock/mock_payments.dart';
import 'mock/mock_schedules.dart'; // v3.0

// ignore_for_file: non_constant_identifier_names
class MockUsers {
  MockUsers._();

  // ── 인증 ──────────────────────────────────────────────────────
  static Map<String, dynamic> register(Map<String, dynamic> body) =>
      MockAuth.register(body);

  static Map<String, dynamic> verifyEmail(String token) =>
      MockAuth.verifyEmail(token);

  static Map<String, dynamic> login(String email, String password) =>
      MockAuth.login(email, password);

  static Map<String, dynamic> getMe(String accessToken) =>
      MockAuth.getMe(accessToken);

  /// v2.9 신규 — PATCH /auth/me
  static Map<String, dynamic> updateProfile(
          String accessToken, Map<String, dynamic> body) =>
      MockAuth.updateProfile(accessToken, body);

  /// v2.9 신규 — POST /auth/me/avatar
  static Map<String, dynamic> uploadAvatar(String accessToken) =>
      MockAuth.uploadAvatar(accessToken);

  static Map<String, dynamic> refreshToken(String refreshToken) =>
      MockAuth.refreshToken(refreshToken);

  static Map<String, dynamic> logout(String? accessToken) =>
      MockAuth.logout(accessToken);

  static Map<String, dynamic> invitePreview(String token) =>
      MockAuth.invitePreview(token);

  static Map<String, dynamic> inviteJoin(
          String accessToken, String token, Map<String, dynamic> body) =>
      MockAuth.inviteJoin(accessToken, token, body);

  // ── 명함 ──────────────────────────────────────────────────────
  static Map<String, dynamic> getCards([String? accessToken]) {
    // api_client.dart 가 accessToken 없이 호출하는 경우 대비
    return accessToken != null
        ? MockCards.getCards(accessToken)
        : {'success': true, 'data': [], 'pagination': {}};
  }

  static Map<String, dynamic> createCard(
          String accessToken, Map<String, dynamic> body) =>
      MockCards.createCard(accessToken, body);

  /// GET /cards/public/:id (인증 불필요)
  static Map<String, dynamic> getPublicCard(int cardId) =>
      MockCards.getPublicCard(cardId);

  /// GET /cards/:id (단건 조회)
  static Map<String, dynamic> getCard(String accessToken, int cardId) =>
      MockCards.getCard(accessToken, cardId);

  static Map<String, dynamic> updateCard(
          String accessToken, int cardId, Map<String, dynamic> body) =>
      MockCards.updateCard(accessToken, cardId, body);

  /// v2.9 신규 — POST /cards/:id/avatar
  static Map<String, dynamic> uploadCardAvatar(
          String accessToken, int cardId) =>
      MockCards.uploadCardAvatar(accessToken, cardId);

  // ── 채팅 ──────────────────────────────────────────────────────
  static Map<String, dynamic> getChatRooms(String accessToken) =>
      MockChat.getChatRooms(accessToken);

  static Map<String, dynamic> createDirectRoom(
          String accessToken, Map<String, dynamic> body) =>
      MockChat.createDirectRoom(accessToken, body);

  static Map<String, dynamic> getChatMessages(
          String accessToken, int roomId) =>
      MockChat.getChatMessages(accessToken, roomId);

  static Map<String, dynamic> sendChatMessage(
          String accessToken, int roomId, Map<String, dynamic> body) =>
      MockChat.sendChatMessage(accessToken, roomId, body);

  static Map<String, dynamic> deleteChatMessage(
          String accessToken, int roomId, int messageId) =>
      MockChat.deleteChatMessage(accessToken, roomId, messageId);

  static Map<String, dynamic> reportChat(
          String accessToken, Map<String, dynamic> body) =>
      MockChat.reportChat(accessToken, body);

  static Map<String, dynamic> blockChatUser(
          String accessToken, Map<String, dynamic> body) =>
      MockChat.blockChatUser(accessToken, body);

  /// GET /cards/contacts/list — 명함첩
  static Map<String, dynamic> getContacts(String accessToken) =>
      MockCards.getContacts(accessToken);

  // ── 그룹 ──────────────────────────────────────────────────────
  /// v2.9: /groups/mine (기존 getMyGroups → getMine으로 경로 변경)
  static Map<String, dynamic> getMyGroupsMine(String accessToken) =>
      MockGroups.getMyGroupsMine(accessToken);

  /// 하위 호환: api_client.dart 가 아직 getMyGroups() 로 부를 경우 대비
  static Map<String, dynamic> getMyGroups(String accessToken) =>
      MockGroups.getMyGroupsMine(accessToken);

  static Map<String, dynamic> joinGroup(
          String accessToken, int groupId, Map<String, dynamic> body) =>
      MockGroups.joinGroup(accessToken, groupId, body);

  /// v2.9 신규 — DELETE /groups/:id/leave
  static Map<String, dynamic> leaveGroup(String accessToken, int groupId) =>
      MockGroups.leaveGroup(accessToken, groupId);

  static Map<String, dynamic> createGroup(
          String accessToken, Map<String, dynamic> body) =>
      MockGroups.createGroup(accessToken, body);

  // ── 레슨 ──────────────────────────────────────────────────────
  static Map<String, dynamic> getLessons(int groupId, {String? status}) =>
      MockLessons.getLessons(groupId, status: status);

  static Map<String, dynamic> createLesson(
          String accessToken, int groupId, Map<String, dynamic> body) =>
      MockLessons.createLesson(accessToken, groupId, body);

  static Map<String, dynamic> registerLesson(
          String accessToken, int lessonId) =>
      MockLessons.registerLesson(accessToken, lessonId);

  static Map<String, dynamic> cancelLessonRegistration(
          String accessToken, int lessonId) =>
      MockLessons.cancelLessonRegistration(accessToken, lessonId);

  static Map<String, dynamic> cancelLesson(
          String accessToken, int lessonId) =>
      MockLessons.cancelLesson(accessToken, lessonId);

  // ── 이벤트 ────────────────────────────────────────────────────
  static Map<String, dynamic> getGroupEvents(int groupId, {String? status}) =>
      MockLessons.getGroupEvents(groupId, status: status);

  static Map<String, dynamic> createGroupEvent(
          String accessToken, int groupId, Map<String, dynamic> body) =>
      MockLessons.createGroupEvent(accessToken, groupId, body);

  static Map<String, dynamic> joinGroupEvent(
          String accessToken, int eventId) =>
      MockLessons.joinGroupEvent(accessToken, eventId);

  static Map<String, dynamic> leaveGroupEvent(
          String accessToken, int eventId) =>
      MockLessons.leaveGroupEvent(accessToken, eventId);

  static Map<String, dynamic> cancelGroupEvent(
          String accessToken, int eventId) =>
      MockLessons.cancelGroupEvent(accessToken, eventId);

  // ── 결제 / 포인트 / 상품 ──────────────────────────────────────
  static Map<String, dynamic> getPointWallet(String accessToken) =>
      MockPayments.getPointWallet(accessToken);

  static Map<String, dynamic> getGroupPointBalance(int groupId) =>
      MockPayments.getGroupPointBalance(groupId);

  static Map<String, dynamic> getPointTransactions(String accessToken) =>
      MockPayments.getPointTransactions(accessToken);

  static Map<String, dynamic> transferPoints(
          String accessToken, Map<String, dynamic> body) =>
      MockPayments.transferPoints(accessToken, body);

  static Map<String, dynamic> joinEvent(String accessToken) =>
      MockPayments.joinEvent(accessToken);

  static Map<String, dynamic> getGroupProducts(int groupId) =>
      MockPayments.getGroupProducts(groupId);

  static Map<String, dynamic> createProduct(
          String accessToken, int groupId, Map<String, dynamic> body) =>
      MockPayments.createProduct(accessToken, groupId, body);

  static Map<String, dynamic> toggleProductActive(
          String accessToken, int productId, bool isActive) =>
      MockPayments.toggleProductActive(accessToken, productId, isActive);

  static Map<String, dynamic> createOrder(
          String accessToken, Map<String, dynamic> body) =>
      MockPayments.createOrder(accessToken, body);

  static Map<String, dynamic> getMyOrders(String accessToken) =>
      MockPayments.getMyOrders(accessToken);

  static Map<String, dynamic> verifyWebPayment(
          String accessToken, Map<String, dynamic> body) =>
      MockPayments.verifyWebPayment(accessToken, body);

  static Map<String, dynamic> verifySubscription(
          String accessToken, Map<String, dynamic> body,
          {String platform = 'apple'}) =>
      MockPayments.verifySubscription(accessToken, body, platform: platform);

  static Map<String, dynamic> cancelSubscription(String accessToken) =>
      MockPayments.cancelSubscription(accessToken);

  static Map<String, dynamic> issuePaymentToken(
          String accessToken, Map<String, dynamic> body) =>
      MockPayments.issuePaymentToken(accessToken, body);

  static Map<String, dynamic> verifyPaymentToken(String token) =>
      MockPayments.verifyPaymentToken(token);

  static Map<String, dynamic> getPointChargeProducts(String accessToken) =>
      MockPayments.getPointChargeProducts(accessToken);

  // ── 레슨 일정 / 출석 (v3.0) ─────────────────────────────────
  /// GET /schedules?group_id=
  static Map<String, dynamic> getSchedules(
          String accessToken, int groupId, {String? status}) =>
      MockSchedules.getSchedules(accessToken, groupId, status: status);

  /// GET /schedules/:id
  static Map<String, dynamic> getScheduleDetail(
          String accessToken, int scheduleId) =>
      MockSchedules.getScheduleDetail(accessToken, scheduleId);

  /// POST /lessons/:groupId/schedules
  static Map<String, dynamic> createSchedule(
          String accessToken, Map<String, dynamic> body, {int groupId = 0}) =>
      MockSchedules.createSchedule(accessToken, body);

  /// GET /schedules/:id/attendances
  static Map<String, dynamic> getAttendances(
          String accessToken, int scheduleId) =>
      MockSchedules.getAttendances(accessToken, scheduleId);

  /// PUT /schedules/:id/attendances
  static Map<String, dynamic> recordAttendances(
          String accessToken, int scheduleId, Map<String, dynamic> body) =>
      MockSchedules.recordAttendances(accessToken, scheduleId, body);
}
