// mock_data.dart — 공유 상태(MockStore) + 예외 클래스(MockApiException)
// mock_api.dart 분리 결과물: 모든 mock 파일이 이 파일을 import한다.

// ──────────────────────────────────────────────────────────────
// MockApiException
// ──────────────────────────────────────────────────────────────
class MockApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;
  final bool upgradeRequired;
  final Map<String, dynamic>? extra;

  MockApiException(
    this.message,
    this.statusCode, {
    this.errorCode,
    this.upgradeRequired = false,
    this.extra,
  });

  @override
  String toString() => message;
}

// ──────────────────────────────────────────────────────────────
// MockStore — 모든 mock 파일이 공유하는 static 상태 저장소
// ──────────────────────────────────────────────────────────────
class MockStore {
  MockStore._(); // 인스턴스화 금지

  // ── 유저 ─────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> users = [
    {
      'id': 1,
      'email': 'test@meti.dev',
      'password': 'MetiTest1234!',
      'name': '홍길동',
      'role': 'user',
      'account_type': 'personal',
      'plan': 'free',
      'is_verified': 1,
      'avatar_url': null,
      'created_at': '2026-01-01 00:00:00',
      'point_balance': 3500,
    }
  ];

  // ── 토큰 ─────────────────────────────────────────────────────
  static final Map<String, String> verifyTokens  = {};
  // ignore: unused_field
  static final Map<String, String> resetTokens   = {};
  static final Map<String, String> accessTokens  = {};
  static final Map<String, String> refreshTokens = {};

  // ── 명함 ─────────────────────────────────────────────────────
  static final List<Map<String, dynamic>> cards = [
    {
      'id': 1,
      'user_id': 1,
      'group_id': null,
      'card_type': 'personal',
      'name': '홍길동',
      'title': '시니어 개발자',
      'company': 'METI Corp',
      'email': 'test@meti.dev',
      'phone': '010-1234-5678',
      'website': 'https://meti.dev',
      'bio': 'Flutter & Dart 개발자입니다.',
      'avatar_url': null,
      'template_id': 'modern_blue',
      'is_primary': 1,
      'is_public': 0,
      'is_active': 1,
      'tags': [
        {'tag_type': 'skill', 'tag_value': 'Flutter'},
        {'tag_type': 'skill', 'tag_value': 'Dart'},
      ],
      'sns_links': [],
      'created_at': '2026-01-01 00:00:00',
      'updated_at': '2026-01-01 00:00:00',
      'sns_count': 0,
    },
    {
      'id': 2,
      'user_id': 1,
      'group_id': null,
      'card_type': 'personal',
      'name': '홍길동 (공개)',
      'title': 'Flutter Developer',
      'company': 'METI Corp',
      'email': 'public@meti.app',
      'phone': null,
      'website': null,
      'bio': '공개 명함입니다.',
      'avatar_url': null,
      'template_id': 'minimal',
      'is_primary': 0,
      'is_public': 1,
      'is_active': 1,
      'tags': [
        {'tag_type': 'interest', 'tag_value': '모바일 개발'},
      ],
      'sns_links': [
        {'platform': 'github', 'url': 'https://github.com/meti', 'sort_order': 0},
        {'platform': 'linkedin', 'url': 'https://linkedin.com/in/meti', 'sort_order': 1},
      ],
      'created_at': '2026-02-01 00:00:00',
      'updated_at': '2026-02-01 00:00:00',
      'sns_count': 2,
    },
    {
      'id': 3,
      'user_id': 1,
      'group_id': null,
      'card_type': 'personal',
      'name': '홍길동 (다크)',
      'title': 'Tech Lead',
      'company': null,
      'email': 'tech@meti.app',
      'phone': '010-0000-0000',
      'website': null,
      'bio': null,
      'avatar_url': null,
      'template_id': 'dark',
      'is_primary': 0,
      'is_public': 0,
      'is_active': 1,
      'tags': [],
      'sns_links': [],
      'created_at': '2026-03-01 00:00:00',
      'updated_at': '2026-03-01 00:00:00',
      'sns_count': 0,
    },
  ];

  // ── 레슨 ─────────────────────────────────────────────────────
  static int lessonIdSeq = 10;

  static final Map<int, List<Map<String, dynamic>>> lessons = {
    1: [
      {
        'id': 1,
        'group_id': 1,
        'instructor_id': 2,
        'instructor_name': '김철수',
        'title': '수영 초급 클래스',
        'description': '기초 호흡법과 자유형을 배웁니다.',
        'schedule_type': 'one-time',
        'scheduled_at': '2026-06-01T10:00:00',
        'duration_minutes': 60,
        'capacity': 10,
        'registered_count': 3,
        'location': '실내수영장 A레인',
        'point_cost': 500,
        'status': 'upcoming',
        'is_registered': false,
        'created_at': '2026-05-01T00:00:00Z',
      },
      {
        'id': 2,
        'group_id': 1,
        'instructor_id': 2,
        'instructor_name': '김철수',
        'title': '수영 중급 — 접영 특강',
        'description': '접영 기초 동작 집중 훈련',
        'schedule_type': 'one-time',
        'scheduled_at': '2026-06-08T10:00:00',
        'duration_minutes': 90,
        'capacity': 8,
        'registered_count': 8,
        'location': '실내수영장 B레인',
        'point_cost': 500,
        'status': 'upcoming',
        'is_registered': true,
        'created_at': '2026-05-02T00:00:00Z',
      },
      {
        'id': 3,
        'group_id': 1,
        'instructor_id': 2,
        'instructor_name': '김철수',
        'title': '4월 체험 레슨',
        'description': '무료 체험 레슨',
        'schedule_type': 'one-time',
        'scheduled_at': '2026-04-10T10:00:00',
        'duration_minutes': 45,
        'capacity': 15,
        'registered_count': 12,
        'location': '야외 수영장',
        'point_cost': 500,
        'status': 'ended',
        'is_registered': false,
        'created_at': '2026-04-01T00:00:00Z',
      },
    ],
  };

  // 수강 신청 목록 (lessonId → List<userId>)
  static final Map<int, List<int>> lessonRegistrations = {
    2: [1], // 레슨 2에 userId=1 등록됨
  };

  // ── 그룹 포인트 잔액 ──────────────────────────────────────────
  static final Map<int, int> groupPointBalance = {1: 8000};

  // ── 이벤트 ──────────────────────────────────────────────────
  static int eventIdSeq = 10;

  static final Map<int, List<Map<String, dynamic>>> groupEvents = {
    1: [
      {
        'id': 1,
        'group_id': 1,
        'title': 'METI 개발자 네트워킹 밋업 2026',
        'description': 'Flutter & Dart 개발자들의 오프라인 네트워킹 모임입니다.',
        'location': '서울 강남구 테헤란로 123',
        'starts_at': '2026-07-10T18:00:00',
        'ends_at': '2026-07-10T21:00:00',
        'status': 'upcoming',
        'visibility': 'public',
        'registration_type': 'pre_required',
        'capacity': 30,
        'participant_count': 12,
        'is_joined': false,
        'entry_fee': 0,
        'group_name': 'METI 개발자 모임',
        'organizer_name': '홍길동',
        'creation_cost': 1000,
        'created_at': '2026-06-01T00:00:00Z',
      },
      {
        'id': 2,
        'group_id': 1,
        'title': '수영 특별 행사 — 여름 마라톤',
        'description': '그룹 회원 대상 수영 마라톤 대회',
        'location': '올림픽 수영장',
        'starts_at': '2026-08-15T09:00:00',
        'ends_at': '2026-08-15T17:00:00',
        'status': 'upcoming',
        'visibility': 'public',
        'registration_type': 'pre_required',
        'capacity': 80,
        'participant_count': 45,
        'is_joined': true,
        'entry_fee': 0,
        'group_name': 'METI 개발자 모임',
        'organizer_name': '홍길동',
        'creation_cost': 3000,
        'created_at': '2026-06-10T00:00:00Z',
      },
      {
        'id': 3,
        'group_id': 1,
        'title': '5월 정기 모임',
        'description': '그룹 정기 모임 및 성과 공유',
        'location': '강남 코워킹스페이스',
        'starts_at': '2026-05-20T19:00:00',
        'ends_at': '2026-05-20T21:00:00',
        'status': 'ended',
        'visibility': 'public',
        'registration_type': 'free',
        'capacity': 20,
        'participant_count': 18,
        'is_joined': false,
        'entry_fee': 0,
        'group_name': 'METI 개발자 모임',
        'organizer_name': '홍길동',
        'creation_cost': 1000,
        'created_at': '2026-05-01T00:00:00Z',
      },
    ],
  };

  // 이벤트 참가자 목록 (eventId → List<userId>)
  static final Map<int, List<int>> eventParticipants = {
    2: [1], // 이벤트 2에 userId=1 참가
  };

  // ── 상품 ─────────────────────────────────────────────────────
  static int productIdSeq = 10;
  static int orderIdSeq   = 100;

  static final Map<int, List<Map<String, dynamic>>> products = {
    1: [
      {
        'id': 1,
        'group_id': 1,
        'name': '수영 강습 쿠폰 (10회)',
        'description': '10회 수강 가능한 강습 쿠폰입니다.',
        'type': 'service',
        'price': 5000,
        'stock': 20,
        'sold_count': 7,
        'is_active': true,
        'expires_at': '2026-12-31T23:59:59Z',
        'image_url': null,
        'created_by': '홍길동',
        'created_at': '2026-05-01T00:00:00Z',
      },
      {
        'id': 2,
        'group_id': 1,
        'name': 'METI 굿즈 — 에코백',
        'description': '그룹 로고가 새겨진 에코백입니다.',
        'type': 'physical',
        'price': 8000,
        'stock': 50,
        'sold_count': 12,
        'is_active': true,
        'expires_at': null,
        'image_url': null,
        'created_by': '홍길동',
        'created_at': '2026-05-10T00:00:00Z',
      },
      {
        'id': 3,
        'group_id': 1,
        'name': '프리미엄 명함 디자인 서비스',
        'description': '전문 디자이너가 1:1로 명함을 제작해드립니다.',
        'type': 'service',
        'price': 15000,
        'stock': null,
        'sold_count': 3,
        'is_active': true,
        'expires_at': null,
        'image_url': null,
        'created_by': '홍길동',
        'created_at': '2026-05-15T00:00:00Z',
      },
    ],
  };

  // 주문 목록 (userId → List<Order>)
  static final Map<int, List<Map<String, dynamic>>> orders = {};

  // ── 결제 토큰 ────────────────────────────────────────────────
  static final Map<String, Map<String, dynamic>> paymentTokens = {};

  // ── 포인트 충전 상품 (고정 목록) ─────────────────────────────
  static const List<Map<String, dynamic>> pointChargeProducts = [
    {'id': 1, 'title': '포인트 10,000P',  'amount_krw': 10000,  'points': 10000,  'is_custom': 0},
    {'id': 2, 'title': '포인트 100,000P', 'amount_krw': 100000, 'points': 100000, 'is_custom': 0},
    {'id': 3, 'title': '포인트 500,000P', 'amount_krw': 500000, 'points': 500000, 'is_custom': 0},
    {'id': 4, 'title': '직접 입력',       'amount_krw': 0,      'points': 0,      'is_custom': 1,
     'min_amount': 10000},
  ];
}
