class AppConstants {
  // ── 모드 설정 ──────────────────────────────────────────
  /// true  → Mock 데이터로 동작 (백엔드 없이 UI 테스트)
  /// false → 실제 API 서버 사용
  static const bool useMock = true;

  // API
  static const String baseUrl = 'https://api.meti.app/api/v1';
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

  // Group Categories
  static const String categoryAssociation = 'association';
  static const String categoryCompany = 'company';
  static const String categoryClub = 'club';
  static const String categoryOther = 'other';

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
