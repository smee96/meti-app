// ── 환경 분기 ────────────────────────────────────────────
// flutter run --dart-define=ENV=staging   → staging 서버 사용
// flutter run                             → mock 모드 (기본)
// flutter run --dart-define=ENV=production → 실서버 (주의)

enum AppEnv { mock, staging, production }

class AppConfig {
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'mock');

  static AppEnv get env {
    switch (_env) {
      case 'staging':
        return AppEnv.staging;
      case 'production':
        return AppEnv.production;
      default:
        return AppEnv.mock;
    }
  }

  /// Mock 모드 여부
  static bool get useMock => env == AppEnv.mock;

  /// 현재 환경 Base URL
  static String get baseUrl {
    switch (env) {
      case AppEnv.staging:
        return 'https://staging.the-meti.pages.dev/api/v1';
      case AppEnv.production:
        return 'https://the-meti.pages.dev/api/v1';
      case AppEnv.mock:
        return 'https://staging.the-meti.pages.dev/api/v1'; // mock 모드에서는 실제 요청 안 함
    }
  }

  /// 환경 이름 표시용
  static String get envLabel {
    switch (env) {
      case AppEnv.staging:
        return 'STAGING';
      case AppEnv.production:
        return 'PRODUCTION';
      case AppEnv.mock:
        return 'MOCK';
    }
  }

  // ── staging 고정 테스트 계정 ─────────────────────────────
  static const String testUserEmail    = 'test@meti.dev';
  static const String testUserPassword = 'MetiTest1234!';
  static const String proUserEmail     = 'pro@meti.dev';
  static const String proUserPassword  = 'MetiTest1234!';
  static const String adminUserEmail   = 'admin@meti.dev';
  static const String adminUserPassword = 'MetiAdmin1234!';
}

class AppConstants {
  // ── 모드 / URL — AppConfig 위임 ───────────────────────
  static bool   get useMock => AppConfig.useMock;
  static String get baseUrl => AppConfig.baseUrl;

  // Storage Keys
  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId       = 'user_id';
  static const String keyUserEmail    = 'user_email';
  static const String keyUserName     = 'user_name';
  static const String keyUserPlan     = 'user_plan';
  static const String keyIsLoggedIn   = 'is_logged_in';

  // Pagination
  static const int defaultPageSize = 20;

  // Plan
  static const String planFree     = 'free';
  static const String planPro      = 'pro';
  static const String planBusiness = 'business';

  // Card Types
  static const String cardTypePersonal = 'personal';
  static const String cardTypeGroup    = 'group';

  // Group Categories
  static const String categoryAssociation = 'association';
  static const String categoryCompany     = 'company';
  static const String categoryClub        = 'club';
  static const String categoryOther       = 'other';

  // Plan Card Limits (기획서 v1.5)
  static const int freeCardLimit     = 1;
  static const int proCardLimit      = 3;
  static const int businessCardLimit = 10;

  // Plan Group Member Limits
  static const int freeGroupMemberLimit     = 2;
  static const int proGroupMemberLimit      = 10;
  static const int businessGroupMemberLimit = -1; // 무제한

  /// 플랜별 그룹 최대 멤버 수 반환 (-1 = 무제한)
  static int groupMemberLimit(String plan) {
    switch (plan) {
      case planPro:      return proGroupMemberLimit;
      case planBusiness: return businessGroupMemberLimit;
      default:           return freeGroupMemberLimit;
    }
  }

  /// 플랜별 그룹 최대 멤버 수 표시 문자열
  static String groupMemberLimitLabel(String plan) {
    final limit = groupMemberLimit(plan);
    return limit == -1 ? '무제한' : '$limit명';
  }

  // Group Purpose Types
  static const List<Map<String, String>> groupPurposes = [
    {'value': 'networking', 'label': '네트워킹'},
    {'value': 'business',   'label': '비즈니스'},
    {'value': 'study',      'label': '스터디'},
    {'value': 'hobby',      'label': '취미/동호회'},
    {'value': 'alumni',     'label': '동문/동창'},
    {'value': 'association','label': '협회/단체'},
    {'value': 'other',      'label': '기타'},
  ];

  // Visibility
  static const String visibilityPublic  = 'public';
  static const String visibilityPrivate = 'private';

  // Message Types
  static const String msgTypeText  = 'text';
  static const String msgTypeImage = 'image';
  static const String msgTypeFile  = 'file';
  static const String msgTypeCard  = 'card';

  // Report Target Types
  static const String reportUser    = 'user';
  static const String reportMessage = 'message';
  static const String reportCard    = 'card';
  static const String reportGroup   = 'group';

  // SNS Platforms
  static const List<String> snsPlatforms = [
    'linkedin', 'twitter', 'instagram', 'facebook',
    'github', 'youtube', 'tiktok', 'website',
  ];

  // Card Templates
  static const List<Map<String, String>> cardTemplates = [
    {'id': 'default',     'name': '기본'},
    {'id': 'modern_blue', 'name': '모던 블루'},
    {'id': 'classic',     'name': '클래식'},
    {'id': 'minimal',     'name': '미니멀'},
    {'id': 'dark',        'name': '다크'},
  ];
}
