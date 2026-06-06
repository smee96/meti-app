# iOS Bug Report — 2026-06-06

> **작성**: iOS 테스트 에이전트  
> **기준**: v3.0 소스 정적 분석  
> **상태**: 🔴 미수정 3건 / 🟡 미수정 3건 / 🟢 미수정 2건

---

## 수정 현황

| ID | 심각도 | 제목 | 수정 여부 |
|----|--------|------|-----------|
| BUG-001 | 🔴 Critical | iOS Info.plist 카메라·사진 권한 선언 누락 | [ ] |
| BUG-002 | 🔴 Critical | GuardianProvider main.dart 미등록 | [ ] |
| BUG-003 | 🔴 Critical | ScheduleProvider main.dart 미등록 | [ ] |
| BUG-004 | 🟡 Medium | Mock 모드에서 레슨 일정 group_id 쿼리 파라미터 무시 | [ ] |
| BUG-005 | 🟡 Medium | Mock 환경에서 신규 회원가입 후 이메일 인증 진행 불가 | [ ] |
| BUG-006 | 🟡 Medium | 보호자 Mock 초기 데이터에 accepted 상태 데이터 없음 | [ ] |
| BUG-007 | 🟢 Low | url_launcher용 LSApplicationQueriesSchemes 미선언 | [ ] |
| BUG-008 | 🟢 Low | 초대 딥링크 iOS URL Scheme 미설정 | [ ] |

---

## 상세 내용

---

### [BUG-001] 🔴 iOS Info.plist 카메라·사진 권한 선언 누락

- **파일**: `ios/Runner/Info.plist`
- **증상**: QR 스캔 버튼 터치 즉시 앱 크래시 / 이미지 선택 버튼 터치 즉시 앱 크래시
- **원인**: `mobile_scanner`, `image_picker` 패키지가 요구하는 iOS 권한 3종 미선언

**수정 내용** — `ios/Runner/Info.plist` `<dict>` 내에 추가:
```xml
<key>NSCameraUsageDescription</key>
<string>QR 코드 스캔 및 명함 사진 촬영에 사용됩니다.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>명함 프로필 사진 선택에 사용됩니다.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>명함 이미지 저장에 사용됩니다.</string>
```

---

### [BUG-002] 🔴 GuardianProvider main.dart 미등록

- **파일**: `lib/main.dart:31`
- **증상**: 보호자 화면(`/guardians`) 진입 시 `ProviderNotFoundException` 런타임 크래시
- **원인**: `GuardianProvider`가 `lib/features/guardians/providers/guardian_provider.dart`에 구현되어 있고 `guardians_screen.dart`에서 `context.read<GuardianProvider>()`로 참조하지만, `main.dart` `MultiProvider`에 미등록

**수정 내용** — `lib/main.dart`:
```dart
// import 추가
import 'features/guardians/providers/guardian_provider.dart';

// MultiProvider providers 목록에 추가
ChangeNotifierProvider(create: (_) => GuardianProvider()),
```

---

### [BUG-003] 🔴 ScheduleProvider main.dart 미등록

- **파일**: `lib/main.dart:31`
- **증상**: 레슨 일정 화면(`/schedules`), 일정 상세 화면(`/schedules/detail`) 진입 시 `ProviderNotFoundException` 런타임 크래시
- **원인**: `ScheduleProvider`가 `lib/features/schedules/providers/schedule_provider.dart`에 구현되어 있지만 `main.dart` `MultiProvider`에 미등록

**수정 내용** — `lib/main.dart`:
```dart
// import 추가
import 'features/schedules/providers/schedule_provider.dart';

// MultiProvider providers 목록에 추가
ChangeNotifierProvider(create: (_) => ScheduleProvider()),
```

---

### [BUG-004] 🟡 Mock 모드에서 레슨 일정 group_id 쿼리 파라미터 무시됨

- **파일**: `lib/core/api/api_client.dart:728`, `api_client.dart:344`
- **증상**: 어느 그룹을 선택해도 레슨 일정이 항상 같은 결과(group_id=0, 빈 목록) 반환
- **원인 추적**:
  1. `schedule_provider.dart:38` → `_api.get('/schedules', queryParams: {'group_id': '$groupId'})`
  2. `api_client.dart:728` → `return _mockDispatch('GET', path, auth: auth)` — **queryParams가 전달되지 않음**
  3. `api_client.dart:344` → `return MockUsers.getSchedules(accessToken!, 0)` — group_id 항상 0 고정

**수정 방향**:
- `_mockDispatch` 시그니처에 `Map<String, dynamic>? queryParams` 파라미터 추가
- `get()` 메서드의 Mock 분기에서 queryParams를 함께 전달
- `api_client.dart:344` 핸들러에서 `queryParams?['group_id']`로 groupId 추출

---

### [BUG-005] 🟡 Mock 환경에서 신규 회원가입 후 이메일 인증 진행 불가

- **파일**: `lib/core/api/mock/mock_auth.dart:26`, `lib/features/auth/screens/email_verification_screen.dart`
- **증상**: 신규 회원가입 → 이메일 인증 화면에서 올바른 토큰을 입력할 방법 없음 → 인증 항상 실패
- **원인**: v3.0 보안패치로 회원가입 응답에서 `verify_token` 제거됨. `mock_auth.dart:40`에서 `MockStore.verifyTokens`에 토큰 저장은 유지되지만 앱 화면에서 확인 수단 없음
- **참고**: 기존 계정 `test@meti.dev`는 `is_verified=1`이므로 로그인 자체는 테스트 가능

**수정 방향**: Mock 빌드(`AppConstants.useMock == true`) 한정으로 이메일 인증 화면에 토큰 자동 입력 버튼 복원

---

### [BUG-006] 🟡 보호자 Mock 초기 데이터에 accepted 상태 데이터 없음

- **파일**: `lib/core/api/mock/mock_data.dart` (guardianLinks 초기값)
- **증상**: 보호자 화면 "내 보호자 목록" / "내 학생 목록"이 항상 빈 화면으로 표시됨
- **원인**: `MockStore.guardianLinks` 초기 데이터가 `status: 'pending'` 1건만 존재. `getMyStudents()`는 `status == 'accepted'`만 필터링하므로 화면 자체를 확인할 수 없음

**수정 방향**: 초기 Mock 데이터에 `status: 'accepted'` 링크 1건 이상 추가

---

### [BUG-007] 🟢 url_launcher용 LSApplicationQueriesSchemes 미선언

- **파일**: `ios/Runner/Info.plist`
- **증상**: 명함의 SNS 링크, 웹사이트 URL 등 외부 링크 클릭 시 iOS에서 열리지 않을 수 있음

**수정 내용** — `ios/Runner/Info.plist` 추가:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
</array>
```

---

### [BUG-008] 🟢 초대 딥링크 iOS URL Scheme 미설정

- **파일**: `ios/Runner/Info.plist`
- **증상**: 외부(SMS, 카카오 등)에서 초대 링크 클릭 시 앱으로 진입 불가
- **원인**: `CFBundleURLTypes` (Custom URL Scheme) 또는 Associated Domains 미설정
- **관련 코드**: `lib/routes/app_router.dart:86` — `/invite` 라우트 구현은 완료되어 있으나 iOS 진입점 없음

**수정 방향**: 앱 URL Scheme 결정 후 `CFBundleURLTypes` 추가 또는 Apple Developer 콘솔에서 Associated Domains 설정

---

*수정 완료 시 해당 BUG의 `[ ]`를 `[x]`로 변경해주세요.*
