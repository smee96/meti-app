# ELID 앱 → 서버 전달 (2026-08-20)

대상: 서버 에이전트 · 발신: 앱 개발 세션
관련: `ELID_Decision_BundleID_2026-08-08.md`, `ELID_Server_to_App_Consolidated_Handoff_2026-08-04.md`

앱 쪽 스토어 출시 준비를 진행하며 **서버 설정에 넣어야 할 실값이 확정**됐습니다.
1·2번은 서버에서 바로 반영 가능한 값이고, 3~5번은 확인/요청 사항입니다.

---

## 1. 번들ID 확정 — `com.elid.app` (양 플랫폼 동일)

대표 확정(2026-08-08)대로 통일 작업을 **오늘 실행 완료**했습니다.

| 항목 | 이전 | **확정값** |
|---|---|---|
| iOS 번들ID | `com.meti.metiApp` | **`com.elid.app`** |
| Android applicationId | `com.meti.meti_app` | **`com.elid.app`** |

서버 설정 갱신 부탁드립니다. 현재 서버 기본값이 `com.meti.app`(`types/index.ts:29-30`,
`index.tsx:514`)인데 **어느 플랫폼에서도 쓰인 적 없는 값**이라 그대로 두면 딥링크가 검증되지 않습니다.

- `ANDROID_PACKAGE` = `com.elid.app`
- `APPLE_APP_ID` = `<TeamID>.com.elid.app` → **TeamID는 아직 없습니다** (아래 3번)

⚠ **스토어 등록 이력이 없어 선점 여부는 미확인입니다.** 계정 확보 후 등록 시점에
이미 쓰이고 있으면 `com.myelid.app`으로 가고, 그때 다시 알려드리겠습니다.

## 2. Android 릴리스 서명 SHA256 — assetlinks.json 주입 요청

릴리스 키스토어를 생성했습니다(PKCS12, 유효기간 10,000일, 대표 PC에 백업 완료).

```
SHA256: 09:8F:95:55:28:1A:EC:9C:91:DD:9B:E8:03:06:93:7B:68:70:9F:ED:17:63:98:FC:CE:6B:F1:2F:BF:9E:5E:72
SHA1:   26:03:9F:36:26:2F:39:16:1A:BD:A6:B9:89:4A:FA:21:0A:30:D3:CD
```

`https://my-elid.com/.well-known/assetlinks.json` 에 아래 형태로 넣어주시면
**Android App Links 실검증이 열립니다.**

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.elid.app",
    "sha256_cert_fingerprints": ["09:8F:95:...:5E:72"]
  }
}]
```

> Google Play App Signing을 쓰게 되면 Play가 재서명한 키의 SHA256이 별도로 생기므로,
> 등록 후 그 값도 배열에 **함께** 넣어야 합니다. 스토어 등록 시 다시 전달하겠습니다.

## 3. Apple Team ID — 아직 없습니다

Apple 개발자 계정이 **신규 개설 대상**입니다(대표 확인 2026-08-20). ProStore의
Team ID는 드롱기 소유라 재사용할 수 없습니다. 계정이 나오는 대로 전달하겠습니다.
그때까지 `APPLE_APP_ID`와 `apple-app-site-association`은 비워두셔도 됩니다 —
iOS 유니버설 링크는 어차피 capability 연결 전이라 동작하지 않습니다.

## 4. 구독 상품 ID 규칙 — 확정

번들ID 확정에 맞춰 아래로 갑니다. 서버 현재 값(`com.meti.pro_monthly` /
`com.meti.business_monthly`) 갱신 부탁드립니다.

| 플랜 | 상품 ID |
|---|---|
| Pro (월) | `com.elid.app.pro_monthly` |
| Business (월) | `com.elid.app.business_monthly` |

App Store Connect / Play Console 등록은 계정 확보 후이므로 **지금은 서버 설정값만**
맞춰두면 됩니다.

### 결제 503 차단 — 앱 대응 완료

`verify-apple` / `verify-google` 503을 **정상 분기로 처리**했습니다. 요청하신 대로
빨간 오류 토스트가 아니라 "결제 준비 중" 안내 다이얼로그가 뜨고, 현재 플랜은 그대로
유지된다는 문구를 함께 보여줍니다. 차단이 유지되는 동안 사용자 혼란은 없습니다.

## 5. 앱 쪽 요청 2건

### 5-1. `GET /partner/services` 응답에 `slug`를 넣어주세요

B-2 잔액 조회를 붙이면서 확인한 건인데, `/partner/services` 응답에는 `slug`가 없고
(`id, name, description, webview_url, open_mode`) 잔액 엔드포인트는 `slug === 'happytree'`
로 분기합니다. 그래서 **앱이 지금은 서비스 이름 문자열("해피트리")로 해피트리를 식별**하고
있습니다. 파트너명이 바뀌면 깨집니다. `slug`를 함께 내려주시면 그 값으로 바꾸겠습니다.

### 5-2. 알림 설정 저장 엔드포인트 — 스펙 제안

`notifications` 라우트에 목록·읽음 처리는 있는데 **설정 저장이 없어** 앱이 로컬
(SharedPreferences)에만 저장하고 있습니다. FCM이 붙으면 서버가 발송 여부를 판단해야
하므로 계정 단위 저장이 필요합니다. 아래 형태를 제안합니다 — 앱은 이 키 이름으로
이미 저장 중이라 엔드포인트만 열리면 그대로 실어 보냅니다.

```
GET  /api/v1/notifications/settings   → { success, data: {...아래 키...} }
PUT  /api/v1/notifications/settings   → body 동일, 부분 갱신 허용
```

```json
{
  "push_enabled": true,
  "chat": true,          // 채팅 메시지
  "card_exchange": true, // 명함 교환·저장
  "group": true,         // 그룹 가입 신청·승인·공지
  "event": true,         // 이벤트 변경·리마인더
  "schedule": true,      // 레슨 일정 시작 전
  "point": true,         // 포인트 적립·사용, 구독 상태
  "marketing": false     // 혜택·신규 기능 (기본 off)
}
```

`push_enabled: false`면 나머지 값과 무관하게 발송하지 않는 것으로 합의하면 좋겠습니다.
마케팅 알림은 기본 off로 두었습니다(수신동의 이슈 회피).

---

## 참고 — 앱 쪽 오늘 반영분

- 비밀번호 변경 화면 신설 (`PUT /auth/password` 연동)
- 알림 설정 화면 신설 (로컬 저장, 서버 연동 대기)
- 소셜 로그인 버튼 숨김 (1차 출시 제외 — 대표 확정)
- **한도 초과 응답 처리 버그 수정**: 앱이 HTTP 오류 본문에서 `upgrade_required` /
  `error_code` / `current` / `limit`을 **버리고 있었습니다.** Mock 경로에서만 채워져
  실서버에서는 업그레이드 안내가 뜨지 않던 상태였는데, 이제 명함·그룹 모두 정상 동작합니다.
  서버 응답 형식은 그대로 두시면 됩니다.
- iOS `PrivacyInfo.xcprivacy` 생성, 수출규정 키 추가, iPhone 전용으로 확정

_문의: 이 저장소에 문서로 회신해주시면 앱 세션이 읽습니다._
