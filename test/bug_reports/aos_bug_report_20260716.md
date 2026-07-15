# AOS Bug Report — 2026-07-16 (ELID 탐색 테스트: 이벤트·채팅·마이페이지·포인트·계정 차등)

**앱**: ELID (구 METI) · `com.meti.meti_app`
**대상 커밋**: `a4898d2` (main) — 회귀 리포트(2026-07-15)의 후속 탐색 세션
**플랫폼**: Android 에뮬레이터 (Pixel_5_API29)
**테스트 계정**: test@meti.dev (Free) · pro@meti.dev (Pro) · admin@meti.dev (Business)
**작성자**: QA Agent (Claude) — AOS
**스크린샷**: `test/bug_reports/screenshots_20260716/`

---

## 1. 요약

Maestro 스위트(27 TC)가 얕게 지나가는 영역을 수동 탐색한 결과, **신규 버그 4건(전부 Low~Low/Med)** 과 관찰 4건을 발견했습니다. 코어 명함 플로우와 무관한 주변 기능(채팅 빈 상태 CTA, 마이페이지 일부 메뉴, 이벤트 날짜 표기, 포인트 내역 정렬)에 몰려 있습니다.

| ID | 심각도 | 요약 |
|----|--------|------|
| BUG-AOS-005 | Low~Med | 채팅 빈 상태 "명함첩 보기" CTA 무동작 (빈 콜백) |
| BUG-AOS-006 | Low | 마이페이지 '비밀번호 변경'·'알림 설정' 메뉴 + 설정(톱니) 아이콘 무동작 (빈 콜백 3곳) |
| BUG-AOS-007 | Low | 이벤트 카드 날짜가 raw ISO(`2026-06-15T18:00:00Z`)로 노출 — 'ko' 로케일 미초기화 |
| BUG-AOS-008 | Low | 포인트 거래 내역 최신순 정렬 미적용 (서버 응답 순서 그대로 렌더) |

---

## 2. 버그 상세

### BUG-AOS-005 — 채팅 빈 상태 "명함첩 보기" CTA 무동작 (Low~Med)

- **재현**: 채팅 탭(채팅방 0개) → "명함첩 보기" 버튼 탭 → 아무 반응 없음 (`exp03_chat_empty_dead_cta.png`)
- **근거**: `lib/features/chat/screens/chat_list_screen.dart:63` — `onAction: () {}` 빈 콜백
- **기대**: 명함첩(연락처) 화면으로 이동. 홈 퀵액션 '명함첩'과 동일 목적지
- **참고**: 사용자 대면 CTA가 죽어 있어 빈 상태에서 채팅 시작 경로가 끊김 → Med에 가까움

### BUG-AOS-006 — 마이페이지 무동작 컨트롤 3곳 (Low)

- **재현**: 마이 탭에서 ① '비밀번호 변경' ② '알림 설정' ③ 우상단 설정(톱니) 아이콘 탭 → 전부 무반응. 두 메뉴는 이동 화살표(>)까지 표시됨 (`exp05_mypage_menus.png`)
- **근거**: `lib/features/mypage/screens/mypage_screen.dart:286` (비밀번호 변경), `:291` (알림 설정), `:251` (설정 아이콘) — 모두 `() {}` 빈 콜백
- **기대**: 화면 미구현이면 메뉴 숨김 또는 "준비 중" 안내. 활성 스타일+화살표로 노출하면서 무동작은 UX 결함

### BUG-AOS-007 — 이벤트 날짜 raw ISO 노출 (Low)

- **재현**: 이벤트 탭 → 카드 날짜가 `2026-06-15T18:00:00Z` 그대로 표시 (`exp01_events_raw_iso_date.png`)
- **원인 (코드 확정)**: `lib/features/events/screens/events_screen.dart:198` — `DateFormat('MM/dd HH:mm', 'ko')`. 앱 어디에서도 `initializeDateFormatting('ko')`를 호출하지 않아 'ko' 로케일 데이터 부재로 **항상 throw** → `:200` catch가 원본 ISO 문자열 반환. 'ko' 로케일 지정은 이 파일 한 곳뿐이라 다른 화면(채팅 목록 등)은 정상
- **수정 제안**: ① 로케일 인자 제거(`DateFormat('MM/dd HH:mm')`) — 최소 수정, 타 화면과 통일 ② 또는 `main()`에서 `initializeDateFormatting('ko')` 후 앱 전역 'ko' 포맷 사용

### BUG-AOS-008 — 포인트 거래 내역 정렬 미적용 (Low)

- **재현**: 마이 → 포인트 내역 → 거래가 03.01 → 02.28 → 04.15 → 04.21 → 04.25 순으로 표시 — 최신순도 과거순도 아님 (`exp04_points_history_unsorted.png`)
- **근거**: `lib/features/points/screens/point_screen.dart:61` — `point.transactions[index]` 응답 배열 그대로 렌더, 정렬 없음. 잔액 연쇄(10000→15000→17000→16000→3500)는 배열 순서 기준으로 일관 → 배열이 시간순이라는 전제인데 mock 시드 2번째 항목 날짜(02.28)가 1번째(03.01)보다 과거라 화면상 모순 노출
- **수정 제안**: 클라이언트에서 `created_at` 기준 내림차순(최신순) 정렬 + mock 시드 날짜 정합 수정

---

## 3. 관찰 사항 (버그 아님 / 정책 확인 필요)

1. **이벤트 '예정' 배지 vs 과거 날짜**: 오늘(07/16) 기준 지난 이벤트(06/15, 05/20)에 '예정' 배지. 클라이언트가 서버 `status` 필드를 그대로 표시하고 날짜 파생 없음 — mock 시드 날짜가 오래된 탓이나, 실서버에서도 status 갱신이 늦으면 동일 노출. 날짜 기반 파생 여부는 서버 정책 확인 필요
2. **이벤트 참가 신청 후 UI 미갱신**: 신청 성공 스낵바 후에도 버튼 '참가 신청'·참가자 수 그대로. 중복 신청은 서버(mock)가 "이미 참가 신청한 이벤트입니다"로 차단(정상, `exp02_event_dup_blocked.png`)하지만, 신청 상태(참가 취소 버튼 전환)가 목록 갱신 없이는 반영 안 됨
3. **채팅방 mock 시드 부재**: mock `/chat`이 항상 빈 배열 → `ChatRoomScreen`(메시지 송수신 UI)은 mock 모드에서 도달 불가 = **자동/수동 테스트 커버리지 공백**. mock 채팅방 시드 1개 추가 권장
4. **계정 차등 정상**: FREE/PRO(파랑)/BUSINESS(보라) 배지, 포인트(3,500/15,000/50,000P), Pro 이상에서 업그레이드 배너 미노출 — 모두 정상 (`exp06`, `exp07`)
5. **테스트 문서 정정**: admin 계정 비밀번호는 `AdminTest1234!` (mock_data.dart:63). 기존 문서의 `MetiAdmin1234!`는 로그인 실패("이메일 또는 비밀번호가 올바르지 않습니다")

---

## 4. 개발 에이전트 픽업 우선순위

1. **BUG-AOS-005** — `chat_list_screen.dart:63` onAction에 명함첩 이동 연결 (홈 퀵액션과 동일 라우트)
2. **BUG-AOS-007** — `events_screen.dart:198` 'ko' 로케일 인자 제거 또는 main()에서 initializeDateFormatting
3. **BUG-AOS-006** — 미구현 메뉴 3곳: 숨김 처리 또는 "준비 중" 스낵바 (구현 예정이면 화면 연결)
4. **BUG-AOS-008** — 거래 내역 클라이언트 최신순 정렬 + mock 시드 날짜 정합
5. (제안) mock 채팅방 시드 추가 → ChatRoomScreen 테스트 가능화
