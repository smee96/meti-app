class AppConstants {
  // ── 모드 설정 ──────────────────────────────────────────
  /// true  → Mock 데이터로 동작 (백엔드 없이 UI 테스트)
  /// false → 실제 API 서버 사용
  static const bool useMock = true;

  // API
  static const String baseUrl = 'https://the-meti.pages.dev/api/v1';
  // static const String baseUrl = 'http://localhost:3000/api/v1'; // 로컬 개발용

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserPlan = 'user_plan';
  static const String keyIsLoggedIn = 'is_logged_in';

  // Pagination
  static const int defaultPageSize = 20;

  // Plan
  static const String planFree = 'free';
  static const String planPro = 'pro';
  static const String planBusiness = 'business';

  // Card Types
  static const String cardTypePersonal = 'personal';
  static const String cardTypeGroup = 'group';

  // Group Categories (레거시 - 호환성 유지)
  static const String categoryAssociation = 'association';
  static const String categoryCompany = 'company';
  static const String categoryClub = 'club';
  static const String categoryOther = 'other';

  // Plan Card Limits (v2.2)
  static const int freeCardLimit = 3;
  static const int proCardLimit = 10;
  static const int businessCardLimit = -1; // 무제한

  // Plan Group Member Limits (v2.5) — 1P=1₩, 그룹당 최대 멤버 수
  // free=2명, pro=10명, business=무제한(null)
  static const int freeGroupMemberLimit = 2;
  static const int proGroupMemberLimit = 10;
  static const int businessGroupMemberLimit = -1; // 무제한

  /// 플랜별 그룹 최대 멤버 수 반환 (-1 = 무제한)
  static int groupMemberLimit(String plan) {
    switch (plan) {
      case planPro:
        return proGroupMemberLimit;
      case planBusiness:
        return businessGroupMemberLimit;
      default:
        return freeGroupMemberLimit;
    }
  }

  /// 플랜별 그룹 최대 멤버 수 표시 문자열
  static String groupMemberLimitLabel(String plan) {
    final limit = groupMemberLimit(plan);
    return limit == -1 ? '무제한' : '$limit명';
  }

  // Group Purpose Types (v2.2)
  static const List<Map<String, String>> groupPurposes = [
    {'value': 'networking', 'label': '네트워킹'},
    {'value': 'business', 'label': '비즈니스'},
    {'value': 'study', 'label': '스터디'},
    {'value': 'hobby', 'label': '취미/동호회'},
    {'value': 'alumni', 'label': '동문/동창'},
    {'value': 'association', 'label': '협회/단체'},
    {'value': 'other', 'label': '기타'},
  ];

  // Visibility
  static const String visibilityPublic = 'public';
  static const String visibilityPrivate = 'private';

  // Message Types
  static const String msgTypeText = 'text';
  static const String msgTypeImage = 'image';
  static const String msgTypeFile = 'file';
  static const String msgTypeCard = 'card';

  // Report Target Types
  static const String reportUser = 'user';
  static const String reportMessage = 'message';
  static const String reportCard = 'card';
  static const String reportGroup = 'group';

  // SNS Platforms
  static const List<String> snsPlatforms = [
    'linkedin', 'twitter', 'instagram', 'facebook',
    'github', 'youtube', 'tiktok', 'website',
  ];

  // Card Templates
  static const List<Map<String, String>> cardTemplates = [
    {'id': 'default', 'name': '기본'},
    {'id': 'modern_blue', 'name': '모던 블루'},
    {'id': 'classic', 'name': '클래식'},
    {'id': 'minimal', 'name': '미니멀'},
    {'id': 'dark', 'name': '다크'},
  ];
}
