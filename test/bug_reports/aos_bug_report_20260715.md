# AOS Regression Report — 2026-07-15 (ELID 디지털 명함 앱)

**앱**: ELID (구 METI) · `com.meti.meti_app`
**대상 커밋**: `a4898d2` (main, "fix: QA 리포트(2026-07-09) 버그 4건 수정 + 테스트 스크립트 갱신")
**플랫폼**: Android 에뮬레이터 (Pixel_5_API29)
**빌드**: `flutter build apk --debug` (Mock 모드, 서버 불필요)
**테스트 도구**: Maestro + adb 수동 탐색 + Flutter 위젯 테스트
**테스트 계정**: test@meti.dev / MetiTest1234! (Free)
**작성자**: QA Agent (Claude) — AOS
**스크린샷**: `test/bug_reports/screenshots_20260715/`

---

## 1. 요약 — 전부 GREEN ✅

| 구분 | 결과 |
|------|------|
| **BUG-AOS-001~004 수정 회귀 검증** | **4/4 수정 확인** (§2) |
| Maestro 자동화 (TC-001~027) | **27/27 PASS — 1차 실행에서 전부 통과** (재실행 불필요) |
| Flutter 위젯 테스트 | 4/4 PASS (SNS 대소문자 회귀 테스트 2건 포함) |
| 신규 발견 버그 | **없음** |

2026-07-09 리포트의 버그 4건이 커밋 `a4898d2`에서 모두 수정되었음을 코드·위젯테스트·에뮬레이터 런타임 3중으로 확인했습니다. 지난 세션에서 스크립트 문제로 1차 실패했던 TC-003/004도 갱신된 스크립트(`무료로 시작하기`)로 1차부터 PASS합니다.

---

## 2. 수정 검증 상세

### ✅ BUG-AOS-001 — 공개 명함 뷰어 SNS 아이콘 대소문자 매칭 (Medium)

- **수정 내용**: `public_card_screen.dart` `_snsInfo`가 `switch (platform.toLowerCase())`로 정규화. `twitter/x`·`tiktok`·`kakao`·`website` 케이스 추가 (상세 화면 `_iconFor`와 정책 통일).
- **검증**:
  - 위젯 테스트 `test/sns_platform_case_bug_test.dart` 2/2 PASS — ① 앱 저장 형식(대문자 `Instagram`/`GitHub`) 명함을 공개 뷰어에 렌더링 → 전용 아이콘 표시, `Icons.link` 폴백 0건, `Twitter / X` 친화 표기 확인 ② 소문자(mock 시드 형식) 대조군 회귀 없음.
  - 런타임: 앱에서 직접 생성한 명함(Instagram/GitHub 대문자 저장, `reg02_tab2_filled.png`)의 상세 화면 SNS 전용 아이콘 정상(`reg05_detail_sns_tags.png`). 공개 뷰어 렌더 경로는 위젯 테스트로 검증(공개 뷰어 화면 진입은 QR 스캔 전용이라 에뮬레이터 런타임 재현 생략 — 동일 `_snsInfo` 코드 경로).

### ✅ BUG-AOS-002 — 신규 명함 기본 템플릿 (Low)

- **수정 내용**: `card_create_screen.dart` `_selectedTemplate = 'default'` (엘리드 네이비×골드).
- **검증**: 명함 만들기 진입 시 템플릿 첫 칩 **엘리드가 기본 선택**(네이비 칩 하이라이트), 미리보기 카드에 골드 아바타 링·ELID 골드 배지 적용 (`reg01_create_default_template.png`).

### ✅ BUG-AOS-003 — 소유자 상세 화면 이력/태그 분리 (Low~Med)

- **수정 내용**: `card_detail_screen.dart`에 `career`/`education` 태그를 일반 태그 칩에서 분리, 공개 뷰어와 동일한 "이력" 섹션으로 표시.
- **검증**: 경력("ELID QA Team Lead · 2023 - 2026", 서류가방 아이콘)·학력(학사모 아이콘)이 **이력 섹션**에, 일반 태그(`skill | Flutter`)만 **태그 섹션**에 표시 (`reg04_detail_resume_section.png`, `reg05_detail_sns_tags.png`). `career | ...` 형태의 원시 노출 사라짐.
- **잔여(수정 범위 외)**: 기간이 여전히 `tag_value`에 `내용 · 기간`으로 병합 저장됨 — 서버 스펙(tag_value 단일 필드) 변경 필요 사항으로 개발 커밋에 명시됨. 서버 확인 대기 항목으로 유지.

### ✅ BUG-AOS-004 — QR 만료 문구 동적화 + 비공개 공유 정책 (Low)

- **수정 내용**: `qr_show_screen.dart` 만료 배지를 `expires_at` 기반 동적 계산, 비공개 명함에 안내 배너 + 링크 공유 비활성.
- **검증**:
  - 공개 명함 QR: 만료 배지 **"23시간 유효"** (mock expires_at=+24h → 동적 계산 정상), 링크 공유 활성 (`reg06_qr_public_dynamic_expiry.png`).
  - 비공개 명함 QR: 배너 **"비공개 명함입니다. 공개로 전환해야 상대가 열람할 수 있어요."** 표시 + **링크 공유 버튼 비활성(회색)**, QR 새로 생성은 가능 (`reg07_qr_private_banner.png`). 상세 화면 공유 차단 정책과 정합.

---

## 3. Maestro 자동화 — 27/27 PASS (1차 실행)

TC-001~027 전 플로우 1차 실행에서 전부 PASS. 지난 리포트에서 스크립트 갱신 대상이던 TC-003/004(로그인 진입 탭 `무료로 시작하기`)도 반영 확인. 개별 로그는 세션 스크래치패드 `maestro_TC-*.log` 참조(산출물 미포함).

| 영역 | TC | 결과 |
|------|----|------|
| 온보딩/인증 | 001~005 | 5/5 PASS |
| 명함 | 006~010, 024, 026, 027 | 8/8 PASS |
| 명함첩/그룹 | 011~015 | 5/5 PASS |
| 이벤트/채팅/포인트 | 016~018 | 3/3 PASS |
| 프로필/가디언/업그레이드 | 019~022 | 4/4 PASS |
| 레슨/로그아웃 | 023, 025 | 2/2 PASS |

> 참고: TC-020/021(가디언)은 mock 모드 앱 내 네비게이션 검증 기준 PASS. 서버 측은 guardians 기능이 제품 결정으로 폐지(라우트 삭제)된 상태이므로, 실서버 연동 시 해당 화면 노출 여부는 제품 결정 필요(기존 리포트와 동일한 참고 사항).

---

## 4. 관찰 사항 (버그 아님)

- **에뮬레이터 키보드 자동교정**: 이력 입력 테스트 중 "Hankuk Univ CS" 입력이 "Hanguk University CS"로 저장됨 — Gboard 자동교정에 의한 것으로 앱 결함 아님. 자동화 스크립트 작성 시 자동교정 비활성 권장.
- **이월 항목(변동 없음)**: ① 이력 기간의 tag_value 병합 저장(서버 스펙 대기, §2-3) ② is_public 기본값 3곳 불일치(fromJson=1 / mock createCard=0 / 생성 UI=true — 현재 동작 문제 없음) ③ 포인트 "곧 만료 예정 (0일 후)" 표기.

---

## 5. 결론

**커밋 `a4898d2` 기준 AOS 회귀 테스트 전부 통과. 개발 픽업 필요 신규 버그 없음.** 2026-07-09 리포트의 4건 수정은 모두 유효하며, 남은 항목은 서버 스펙 결정 대기(이력 기간 필드 분리, guardians 폐지 반영)뿐입니다.
