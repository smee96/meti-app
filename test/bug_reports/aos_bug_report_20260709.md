# AOS Bug Report — 2026-07-09 (ELID 디지털 명함 앱)

**앱**: ELID (구 METI) · `com.meti.meti_app`
**대상 커밋**: `a8037b7` (main, "명함 템플릿을 디자인 킷 공식 팔레트로 재매핑")
**플랫폼**: Android 에뮬레이터 (emulator-5554, API 34 계열)
**빌드**: `flutter build apk --debug` (Mock 모드, 서버 불필요)
**테스트 도구**: Maestro 2.6.0 + 수동 탐색 + Flutter 위젯 테스트
**테스트 계정**: test@meti.dev / MetiTest1234! (Free), pro@meti.dev / ProTest1234! (Pro)
**테스트 범위**: 디지털 명함 앱 핵심 기능 (제휴-해피트리 연동은 요청에 따라 제외)
**작성자**: QA Agent (Claude) — AOS
**스크린샷**: `test/bug_reports/screenshots_20260709/`

---

## 1. 요약

| 구분 | 결과 |
|------|------|
| Maestro 자동화 (TC-001~027) | 재실행 후 **27/27 PASS** (1차 실패 15건은 전부 스크립트/adb 글리치, §4) |
| 신규 기능 수동 테스트 | 이력 입력·태그·SNS·템플릿·공유·공개뷰어·QR 전 흐름 동작 |
| 발견 버그 | **기능 버그 2건 (Medium), 데이터/표시 이슈 3건 (Low~Medium), 관찰 2건** |
| 리브랜딩(ELID) | 스플래시/로그인/홈/명함 워드마크·앱명·컬러 정상 반영 |

가장 중요한 결함은 **BUG-AOS-001 (공개 명함 뷰어 SNS 아이콘 깨짐)** 으로, 앱에서 직접 만든 명함을 상대방이 공개 링크로 열면 SNS 아이콘이 전부 깨집니다. Mock 시드 데이터로는 드러나지 않아 회귀 스위트를 통과하므로 별도 주의가 필요합니다.

---

## 2. 발견된 버그

### BUG-AOS-001 — 공개 명함 뷰어에서 SNS 아이콘 전부 깨짐 (플랫폼 대소문자 불일치)

| 항목 | 내용 |
|------|------|
| **심각도** | **Medium** (사용자 대면, 공유 명함 품질 저하) |
| **재현율** | 100% (앱에서 생성한 모든 SNS 링크) |
| **영향** | 공개 명함 뷰어(`PublicCardScreen`)의 SNS 섹션 |

**현상**
명함 생성 화면은 SNS 플랫폼을 **첫 글자 대문자**(`Instagram`, `GitHub`, `LinkedIn`, `Twitter/X` …)로 저장합니다. 그러나 공개 뷰어의 아이콘 매핑(`_snsInfo`)은 **소문자 case**(`instagram`, `github` …)로만 비교하고 `toLowerCase()` 처리가 없습니다. 결과적으로 앱에서 만든 명함을 공개 링크로 열면 모든 SNS가 전용 아이콘 대신 **기본 링크 아이콘(`Icons.link`)** 으로 표시되고, `Twitter/X` 는 친화 표기 `Twitter / X` 로 바뀌지 않고 원문 그대로 노출됩니다.

**근거 (코드)**
- 저장(대문자): `lib/features/cards/screens/card_create_screen.dart:19` `_snsPlatforms = ['Instagram','LinkedIn','GitHub','Twitter/X', …]`
- 뷰어(소문자 매칭, `toLowerCase` 없음): `lib/features/cards/screens/public_card_screen.dart:433-455`
  ```dart
  _SnsInfo _snsInfo(String platform) {
    switch (platform) {          // ← toLowerCase() 누락
      case 'linkedin': ...
      case 'github':   ...
      default:  return _SnsInfo(platform, Icons.link, ...);  // ← 대문자는 전부 여기로
    }
  }
  ```
- 참고: 소유자용 **상세 화면**은 `card_detail_screen.dart:539` 에서 `p.toLowerCase()` 로 처리해 **정상 표시**됩니다(스크린샷 `13_detail_sns.png` 에서 Instagram/GitHub 아이콘 정상). 즉 동일 데이터인데 상세는 맞고 공개 뷰어만 깨집니다.

**런타임 재현 (위젯 테스트로 확정)**
`test/sns_platform_case_bug_test.dart` 추가 — 공개 뷰어에 대문자/소문자 SNS 명함을 각각 렌더링:
- 대문자 카드(앱 저장 형식): Instagram 카메라 아이콘·GitHub 코드 아이콘 **미표시**, 기본 `Icons.link` **3개**로 폴백, `Twitter / X` 라벨 **없음**.
- 소문자 카드(대조군): 전용 아이콘 정상, 폴백 없음.
```
00:00 +2: All tests passed!   (버그 재현 + 대조 모두 통과)
```

**왜 회귀 스위트에서 안 잡혔나**
Mock 시드/더미(`mock_cards.dart`, `mock_data.dart`)의 SNS는 `github`/`linkedin` **소문자**라 뷰어에서 우연히 정상 매칭됩니다. **실제 사용자 생성 경로(대문자 저장)** 를 태우는 테스트가 없어 자동 검증 공백입니다.

**권장 수정**
`public_card_screen.dart:434` 를 `switch (platform.toLowerCase())` 로 변경(상세 화면과 동일). 단 `Twitter/X`↔`twitter` 는 소문자화만으로 안 맞으므로 저장 값 정규화(`twitter`) 또는 case에 `'twitter/x'` 추가 필요. 근본적으로는 생성/상세/뷰어 3곳의 플랫폼 키를 **단일 소문자 표준**으로 통일 권장.

---

### BUG-AOS-002 — 신규 명함 기본 템플릿이 브랜드 기본(`엘리드`)이 아님

| 항목 | 내용 |
|------|------|
| **심각도** | **Low** (브랜드 일관성, 의도 확인 필요) |
| **재현율** | 100% |

**현상**
명함 생성 화면 진입 시 미리보기가 **밝은 파랑 `modern_blue`(모던 블루)** 로 열립니다(스크린샷 `06_create_default_template.png`). 템플릿 목록의 **첫 항목이자 브랜드 기본인 `default`(엘리드 — 네이비+골드)** 가 선택돼 있지 않습니다.

**근거**: `card_create_screen.dart:55` `String _selectedTemplate = 'modern_blue';`

**기대**: 신규 명함은 브랜드 기본 `엘리드`(default)로 열리는 것이 리브랜딩 취지에 부합. 의도된 동작이면 무시 가능하나, 리브랜딩 지시서 취지상 확인 권장.

---

### BUG-AOS-003 — 소유자 상세 화면의 "태그" 섹션에 경력/학력이 필터 없이 노출

| 항목 | 내용 |
|------|------|
| **심각도** | **Low~Medium** (표시 정책 불일치) |
| **재현율** | 100% |

**현상**
공개 뷰어는 태그를 경력/학력/스킬/키워드 **섹션으로 분류**해 "상세 이력"에 정리해 보여줍니다. 반면 소유자 **상세 화면**은 `career`/`education` 태그를 일반 "태그" 칩에 그대로 섞어 노출합니다 — 예: `career | ELID QA Team Lead · 2023 - 2026`, `education | Hanguk University CS · 2015 - 2019` (스크린샷 `12_detail_tags.png`, `13_detail_sns.png`).

**연관 데이터 이슈**: 이력의 "기간"이 별도 필드가 아니라 `tag_value` 에 `내용 · 기간` 형태로 **합쳐 저장**됩니다(`card_create_screen._submit`). 이 때문에 상세/수정 재진입 시 기간이 본문에 붙어 보이고 분리 표시가 불가합니다.

**기대**: 상세 화면도 공개 뷰어와 동일하게 경력/학력을 태그 칩에서 제외하고 이력 섹션으로 표시하거나, 최소한 표시 정책을 통일.

---

### BUG-AOS-004 — QR 화면 "24시간 유효" 문구 하드코딩

| 항목 | 내용 |
|------|------|
| **심각도** | **Low** |
| **재현율** | 100% |

**현상**: QR 표시 화면의 만료 배지가 실제 `expires_at` 값과 무관하게 **고정 텍스트 "24시간 유효"** 로 렌더됩니다(스크린샷 `16_qr_private_card.png`).
**근거**: `lib/features/cards/screens/qr_show_screen.dart:148` `Text('24시간 유효', …)` — 하드코딩.
**부수 관찰**: 상세 화면 공유는 비공개 명함을 차단(정상, `15_private_share_blocked.png`)하지만, **QR 화면(`qr_show_screen`)은 is_public 검사 없이** 비공개 명함도 QR·링크 공유가 가능합니다. 공유 정책 일관성 확인 권장.

---

## 3. 관찰 사항 (버그 아님 / 경미)

- **포인트 만료 표기**: 포인트 화면에 `곧 만료 예정: 2,000P (0일 후)` 로 "0일 후"가 표기됨(`18_points_screen.png`). Mock 데이터 특성이나, 0/음수 일수의 문구 처리(예: "오늘 만료") 확인 권장.
- **템플릿 스와치 구분**: `엘리드`·`민트`·`바이올렛` 은 동일 네이비 배경에 악센트 색만 달라 칩 스와치가 유사합니다. 실제 악센트(골드/민트/바이올렛)는 구분되므로(`06b_template_mint.png` 등) 기능 문제는 아니나, 목록에서 육안 구분이 다소 어렵습니다.
- **템플릿 id↔이름 레거시 불일치(정상)**: `forest_gold=민트`, `violet_amber=바이올렛`, `ocean_coral=틸 코랄` — 서버 호환 위한 의도된 매핑(코드 주석 명시). 디버깅 시 혼동 주의용 기록.
- **is_public 기본값 3중 불일치(잠재)**: `CardModel.fromJson` 기본 `1`, mock `createCard` 기본 `0`, 생성 UI 스위치 기본 `true`. 생성 UI가 항상 명시 전송하므로 현재 문제 없으나, 필드 누락 응답 시 동작이 갈릴 수 있어 기록.

---

## 4. Maestro 자동화 상세 (27/27 PASS)

1차 실행에서 15건이 실패했으나 **전수 조사 결과 앱 결함이 아닌 스크립트/환경 문제**였고, 원인 수정·재실행 후 전부 PASS했습니다.

| TC | 1차 | 원인 | 재실행 |
|----|-----|------|--------|
| TC-003 / TC-004 (회원가입/이메일인증) | Fail | 스크립트가 구 텍스트 `"회원가입"` 탭 시도. 실제 로그인 화면 버튼은 **`무료로 시작하기`**(`login_screen.dart:429`). 앱 정상 | PASS |
| TC-014 (그룹 개설) | Fail | `_login` 헬퍼 타이밍. 그룹 개설 자체는 정상("개설 신청 완료" pending 다이얼로그, `21_group_create_result.png`) | PASS |
| TC-018 (포인트) | Fail | 좌표 탭 플레이크. 포인트 화면 정상 렌더(잔액 3,500P, `18_points_screen.png`) | PASS |
| TC-019~027 | Fail(0s) | adb `pm list packages` 일시 글리치로 `clearState` 실패(앱 무관) | 재실행 **9/9 PASS** |
| `_login` / `_skip_onboarding` | Fail | 헬퍼 플로우 단독 실행 탓(정상, 버그 아님) | — |

> 참고: `.maestro/` 스크립트의 TC-003/004가 아직 구버전 텍스트(`회원가입`)를 사용하고 있어, 개발/QA 에이전트가 최신 로그인 UI(`무료로 시작하기`)에 맞춰 갱신하면 1차부터 green이 됩니다.

---

## 5. 리브랜딩(ELID) 점검 — 정상

- 스플래시(`01_launch.png`)·로그인(`02_login_screen.png`)·홈·명함 카드에 `EL`+골드`I`+`D` 워드마크 정상.
- 앱 표시명 `ELID`(`AndroidManifest.xml:3 android:label="ELID"`), 패키지 ID `com.meti.meti_app` 유지(변경 금지 준수).
- 테마 네이비 `#0B1E40` / 골드 `#C9A86A` 유지, 명함 배지 `ELID` 노출.
- "ELID by METI" 병기는 스플래시 하단 1곳(의도 확인은 지시상 보고 대상 아님).

---

## 6. 재현/검증 자료

- 스크린샷: `test/bug_reports/screenshots_20260709/` (01~21)
- BUG-AOS-001 재현 위젯 테스트: `test/sns_platform_case_bug_test.dart` (`flutter test` 로 실행, 2/2 통과)
- 탐색 플로우(임시): 로그인→명함 생성(이력·태그·SNS)→상세→QR / 비공개 공유 차단 / 포인트 / 그룹 개설

---

## 7. 개발 에이전트 픽업 우선순위

1. **BUG-AOS-001** (Medium) — `public_card_screen.dart:434` `toLowerCase()` + `Twitter/X` 키 정규화. SNS 플랫폼 키 표준 통일 권장.
2. **BUG-AOS-003** (Low~Med) — 상세 화면 태그 섹션에서 career/education 제외 또는 이력 섹션 분리 + 기간 별도 필드화.
3. **BUG-AOS-002 / 004** (Low) — 기본 템플릿 `default`(엘리드) 여부 결정, QR 만료 문구 동적화 + QR 공유 is_public 정책 정합.
4. **[테스트 스크립트 전용 — 앱 버그 아님]** Maestro `.maestro/TC-003_register.yaml`·`TC-004_email_verify.yaml` 이 구버전 로그인 텍스트 `"회원가입"` 을 탭하도록 되어 있음. 현재 로그인 화면의 실제 진입 버튼은 **`무료로 시작하기`**(`login_screen.dart:429`). 두 yaml의 `- tapOn: "회원가입"` → `- tapOn: ".*무료로 시작하기.*"` 로 갱신하면 1차 실행부터 green. (앱 동작은 정상이므로 코드 수정 불필요, 스크립트만 갱신.)
