// mock_chat.dart — 채팅 Mock API (서버 스펙: ELID_Chat_Push_App_Handoff.md §2)
// 포함: getChatRooms, createDirectRoom, getChatMessages, sendChatMessage,
//       deleteChatMessage, reportChat, blockChatUser
// 정책:
//   - 명함을 교환한 상대(exchangedPairs)와만 방 생성 가능 — 아니면 403
//   - GET /chat 응답 최상위에 chat_retention_days (free=7, 유료=0=무제한)
//   - GET messages는 최신순(DESC) 반환 + 호출 시 읽음 처리
//   - 메시지 삭제는 본인 것만, 소프트 삭제(is_deleted)

import 'mock_data.dart';

class MockChat {
  MockChat._();

  // ── 상태 ─────────────────────────────────────────────────────
  // 명함 교환 완료 쌍 ('작은ID-큰ID'). test(1)↔pro(2)만 교환됨.
  static final Set<String> exchangedPairs = {'1-2'};

  // 유저별 차단 목록
  static final Map<int, Set<int>> blockedUsers = {};

  static int roomIdSeq = 2;
  static int messageIdSeq = 100;

  // 채팅방: unread = {userId: count}
  static final List<Map<String, dynamic>> rooms = [
    {
      'id': 1,
      'member_ids': [1, 2],
      'last_message': '이번 주 목요일 오후는 어떠세요?',
      'last_message_at': '2026-07-17T09:42:00Z',
      'unread': {1: 2, 2: 0},
    },
  ];

  // 방별 메시지 (저장은 오래된순, 응답은 DESC)
  static final Map<int, List<Map<String, dynamic>>> messages = {
    1: [
      {
        'id': 1, 'room_id': 1, 'sender_id': 2, 'sender_name': '김프로',
        'message_type': 'text',
        'content': '홍길동님 안녕하세요! 명함 보고 연락드립니다.',
        'is_deleted': 0, 'created_at': '2026-07-16T14:00:00Z',
      },
      {
        'id': 2, 'room_id': 1, 'sender_id': 1, 'sender_name': '홍길동',
        'message_type': 'text',
        'content': '반갑습니다, 김프로님! 어떤 일로 연락 주셨나요?',
        'is_deleted': 0, 'created_at': '2026-07-16T14:03:00Z',
      },
      {
        'id': 3, 'room_id': 1, 'sender_id': 2, 'sender_name': '김프로',
        'message_type': 'file',
        'content': 'ELID_제휴제안서.pdf',
        'file_name': 'ELID_제휴제안서.pdf', 'file_size': 524288,
        'is_deleted': 0, 'created_at': '2026-07-16T14:05:00Z',
      },
      {
        'id': 4, 'room_id': 1, 'sender_id': 1, 'sender_name': '홍길동',
        'message_type': 'card',
        'content': '명함을 공유했습니다.',
        'card_id': 2, 'card_name': '홍길동 (공개)',
        'is_deleted': 0, 'created_at': '2026-07-16T14:10:00Z',
      },
      {
        'id': 5, 'room_id': 1, 'sender_id': 2, 'sender_name': '김프로',
        'message_type': 'text',
        'content': '명함 잘 받았습니다. 미팅 가능하신 날짜 알려주세요!',
        'is_deleted': 0, 'created_at': '2026-07-17T09:40:00Z',
      },
      {
        'id': 6, 'room_id': 1, 'sender_id': 2, 'sender_name': '김프로',
        'message_type': 'text',
        'content': '이번 주 목요일 오후는 어떠세요?',
        'is_deleted': 0, 'created_at': '2026-07-17T09:42:00Z',
      },
    ],
  };

  // ── 헬퍼 ─────────────────────────────────────────────────────
  static Map<String, dynamic> _userFromToken(String accessToken) {
    final email = MockStore.accessTokens[accessToken];
    if (email == null) throw MockApiException('인증이 필요합니다.', 401);
    return MockStore.users.firstWhere((u) => u['email'] == email);
  }

  static String _pairKey(int a, int b) => a < b ? '$a-$b' : '$b-$a';

  static Map<String, dynamic>? _firstOrNull(
      Iterable<Map<String, dynamic>> items, bool Function(Map<String, dynamic>) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  static Map<String, dynamic>? _findUser(int userId) {
    for (final u in MockStore.users) {
      if (u['id'] == userId) return u;
    }
    return null;
  }

  static List<Map<String, dynamic>> _otherMembers(
      Map<String, dynamic> room, int myId) {
    final ids = (room['member_ids'] as List).cast<int>();
    return ids.where((id) => id != myId).map((id) {
      final u = _findUser(id);
      return {
        'user_id': id,
        'name': u?['name'] ?? '알 수 없음',
        'avatar_url': u?['avatar_url'],
      };
    }).toList();
  }

  static Map<String, dynamic> _roomResponse(
      Map<String, dynamic> room, int myId) {
    return {
      'id': room['id'],
      'unread_count': (room['unread'] as Map)[myId] ?? 0,
      'last_message': room['last_message'],
      'last_message_at': room['last_message_at'],
      'members': _otherMembers(room, myId),
    };
  }

  // ── GET /chat ────────────────────────────────────────────────
  static Map<String, dynamic> getChatRooms(String accessToken) {
    final user = _userFromToken(accessToken);
    final myId = user['id'] as int;
    final blocked = blockedUsers[myId] ?? {};

    final myRooms = rooms.where((r) {
      final ids = (r['member_ids'] as List).cast<int>();
      if (!ids.contains(myId)) return false;
      // 내가 차단한 상대와의 방은 목록에서 제외
      return !ids.any((id) => id != myId && blocked.contains(id));
    }).toList()
      ..sort((a, b) => (b['last_message_at'] as String? ?? '')
          .compareTo(a['last_message_at'] as String? ?? ''));

    final plan = user['plan'] as String? ?? 'free';
    return {
      'success': true,
      'data': myRooms.map((r) => _roomResponse(r, myId)).toList(),
      'chat_retention_days': plan == 'free' ? 7 : 0, // 0 = 무제한
      'pagination': {
        'page': 1, 'limit': 20, 'total': myRooms.length,
        'total_pages': 1, 'has_next': false,
      },
    };
  }

  // ── POST /chat/direct ────────────────────────────────────────
  static Map<String, dynamic> createDirectRoom(
      String accessToken, Map<String, dynamic> body) {
    final user = _userFromToken(accessToken);
    final myId = user['id'] as int;
    final targetId = body['target_user_id'] as int? ?? 0;

    if (targetId <= 0 || targetId == myId) {
      throw MockApiException('유효하지 않은 상대입니다.', 422);
    }
    if (!exchangedPairs.contains(_pairKey(myId, targetId))) {
      throw MockApiException('명함을 교환한 상대방과만 채팅할 수 있습니다.', 403);
    }

    // 서버 응답 스펙: {room_id, is_new} (staging 검증 2026-07-18)
    for (final r in rooms) {
      final ids = (r['member_ids'] as List).cast<int>();
      if (ids.contains(myId) && ids.contains(targetId)) {
        return {
          'success': true,
          'data': {'room_id': r['id'], 'is_new': false},
        };
      }
    }

    final room = {
      'id': ++roomIdSeq,
      'member_ids': [myId, targetId],
      'last_message': null,
      'last_message_at': null,
      'unread': {myId: 0, targetId: 0},
    };
    rooms.add(room);
    messages[room['id'] as int] = [];
    return {
      'success': true,
      'data': {'room_id': room['id'], 'is_new': true},
      'message': '채팅방이 생성되었습니다.',
    };
  }

  // ── GET /chat/:roomId/messages ───────────────────────────────
  static Map<String, dynamic> getChatMessages(
      String accessToken, int roomId) {
    final user = _userFromToken(accessToken);
    final myId = user['id'] as int;
    final room = _firstOrNull(rooms, (r) => r['id'] == roomId);
    if (room == null ||
        !(room['member_ids'] as List).cast<int>().contains(myId)) {
      throw MockApiException('채팅방을 찾을 수 없습니다.', 404);
    }

    // 조회 = 읽음 처리 (서버 last_read_at 갱신과 동일)
    (room['unread'] as Map)[myId] = 0;

    final list = List<Map<String, dynamic>>.from(messages[roomId] ?? []);
    return {
      'success': true,
      'data': list.reversed.map(Map<String, dynamic>.from).toList(), // DESC
      'pagination': {
        'page': 1, 'limit': 30, 'total': list.length,
        'total_pages': 1, 'has_next': false,
      },
    };
  }

  // ── POST /chat/:roomId/messages ──────────────────────────────
  static Map<String, dynamic> sendChatMessage(
      String accessToken, int roomId, Map<String, dynamic> body) {
    final user = _userFromToken(accessToken);
    final myId = user['id'] as int;
    final room = _firstOrNull(rooms, (r) => r['id'] == roomId);
    if (room == null ||
        !(room['member_ids'] as List).cast<int>().contains(myId)) {
      throw MockApiException('채팅방을 찾을 수 없습니다.', 404);
    }

    final type = body['message_type'] as String? ?? 'text';
    String? cardName;
    if (type == 'card') {
      final cardId = body['card_id'] as int? ?? 0;
      final card = _firstOrNull(MockStore.cards, (c) => c['id'] == cardId);
      cardName = card?['name'] as String?;
    }

    final msg = <String, dynamic>{
      'id': ++messageIdSeq,
      'room_id': roomId,
      'sender_id': myId,
      'sender_name': user['name'],
      'message_type': type,
      'content': body['content'] ??
          (type == 'card' ? '명함을 공유했습니다.' : ''),
      if (body['file_name'] != null) 'file_name': body['file_name'],
      if (body['file_size'] != null) 'file_size': body['file_size'],
      if (body['file_url'] != null) 'file_url': body['file_url'],
      if (body['card_id'] != null) 'card_id': body['card_id'],
      if (cardName != null) 'card_name': cardName,
      'is_deleted': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    (messages[roomId] ??= []).add(msg);

    // 방 메타 갱신 + 상대 unread 증가
    room['last_message'] = type == 'card'
        ? '명함을 공유했습니다.'
        : type == 'image'
            ? '사진을 보냈습니다.'
            : type == 'file'
                ? '파일을 보냈습니다.'
                : msg['content'];
    room['last_message_at'] = msg['created_at'];
    final unread = room['unread'] as Map;
    for (final id in (room['member_ids'] as List).cast<int>()) {
      if (id != myId) unread[id] = ((unread[id] as int?) ?? 0) + 1;
    }

    return {'success': true, 'data': Map<String, dynamic>.from(msg)};
  }

  // ── POST /chat/:roomId/upload ────────────────────────────────
  // 서버 스펙: 업로드 성공 시 메시지 자동 생성 → {message, file_url} 반환 (별도 send 불필요)
  static Map<String, dynamic> uploadChatFile(
      String accessToken, int roomId, Map<String, dynamic> body) {
    final fileName = body['file_name'] as String? ?? 'image.jpg';
    final fileType = body['file_type'] as String? ?? 'image';
    final fileUrl =
        'https://staging.the-meti.pages.dev/uploads/chat/$roomId/$fileName';

    final sent = sendChatMessage(accessToken, roomId, {
      'message_type': fileType,
      'content': fileName,
      'file_name': fileName,
      'file_url': fileUrl,
    });
    return {
      'success': true,
      'data': {'message': sent['data'], 'file_url': fileUrl},
    };
  }

  // ── DELETE /chat/:roomId/messages/:msgId ─────────────────────
  static Map<String, dynamic> deleteChatMessage(
      String accessToken, int roomId, int messageId) {
    final user = _userFromToken(accessToken);
    final myId = user['id'] as int;
    final msg =
        _firstOrNull(messages[roomId] ?? [], (m) => m['id'] == messageId);
    if (msg == null) throw MockApiException('메시지를 찾을 수 없습니다.', 404);
    if (msg['sender_id'] != myId) {
      throw MockApiException('본인 메시지만 삭제할 수 있습니다.', 403);
    }
    // 서버와 동일하게 0/1 int (staging 검증 2026-07-18)
    msg['is_deleted'] = 1;
    msg['content'] = '';
    return {'success': true, 'data': null, 'message': '메시지가 삭제되었습니다.'};
  }

  // ── POST /chat/report ────────────────────────────────────────
  static Map<String, dynamic> reportChat(
      String accessToken, Map<String, dynamic> body) {
    _userFromToken(accessToken);
    final targetType = body['target_type'] as String?;
    final reason = body['reason'] as String?;
    if (targetType == null || body['target_id'] == null || reason == null) {
      throw MockApiException('신고 대상과 사유를 입력해주세요.', 422);
    }
    return {
      'success': true,
      'data': null,
      'message': '신고가 접수되었습니다. 검토 후 조치하겠습니다.',
    };
  }

  // ── POST /chat/block ─────────────────────────────────────────
  static Map<String, dynamic> blockChatUser(
      String accessToken, Map<String, dynamic> body) {
    final user = _userFromToken(accessToken);
    final myId = user['id'] as int;
    final targetId = body['blocked_user_id'] as int? ?? 0;
    if (targetId <= 0 || targetId == myId) {
      throw MockApiException('유효하지 않은 상대입니다.', 422);
    }
    (blockedUsers[myId] ??= {}).add(targetId);
    return {'success': true, 'data': null, 'message': '사용자를 차단했습니다.'};
  }
}
