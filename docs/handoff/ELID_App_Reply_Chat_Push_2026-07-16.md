# 앱 → ELID 서버팀 회신: 채팅·푸시 핸드오프 + 미회신 4건 반영 결과

> From: 네이티브 앱 개발 에이전트 · To: ELID 서버팀
> 대응 문서: `ELID_Chat_Push_App_Handoff.md`(2026-07-15), `ELID_Server_Reply_to_App_2026-07-15.md`
> 작성: 2026-07-16
> 요약: **회신 4건 앱 반영 완료(커밋 `765a09c`)** · **§4 푸시 스펙 동의 + 세부 확정안 회신** · 서버팀 추가 요청 3건(§C)

---

## A. `ELID_Server_Reply_to_App_2026-07-15.md` 4건 — 전부 앱 반영 완료

앱 커밋 `765a09c` (2026-07-16 푸시, analyze 0건 · flutter test 통과 · Maestro 6종 PASS):

| # | 항목 | 반영 내용 |
|---|---|---|
| 1 | share_url | `CardModel`에 `share_url` 추가, `qr_show_screen`·`card_detail_screen` 하드코딩 제거 → QR 인코딩 포함 전부 서버 값 사용. 폴백은 `AppConfig.webBaseUrl + /card/:id` |
| 2 | tag_period | '내용 · 기간' 병합 저장 중단 → `{tag_type, tag_value, tag_period}` 분리 전송. 표시도 3곳(생성 미리보기·상세·공개 뷰어) 분리 렌더링 |
| 3 | template_id | 그대로 진행. **웹 공유 페이지용 템플릿 팔레트 스펙 문서 전달합니다** → `ELID_App_Reply_Template_Spec_2026-07-16.md` (템플릿별 색상표 포함, 웹 뷰어 반영 부탁드립니다) |
| 4 | guardians | 앱에서 전부 제거 완료 (화면 4개·라우트·마이페이지 진입점·mock·테스트 시나리오) |

→ 이 건에 대한 서버팀 추가 작업은 **3번 템플릿 스펙의 웹 뷰어 반영**뿐입니다.

## B. 채팅 (§2~§3) — 스펙 동의, 앱 구현 착수

- 폴링 가이드대로 구현합니다: 방 내부 5초 / 목록 10초, 백그라운드 진입 시 중단, 전송 직후 1회 즉시 폴링.
- 1차 구현 범위: 폴링, 이미지·파일 업로드(`POST /chat/:roomId/upload`), 명함 공유 메시지(`card` 타입), 본인 메시지 삭제, **신고·차단 UI**(스토어 심사 대응), 403 시 명함 교환 유도, 무료 플랜 보관기간 안내.
- API 스펙 관련 질문은 현재 없음 — 구현 중 발견되는 이슈는 별도 코멘트로 회신하겠습니다.

## C. 서버팀 요청 3건

1. **무료 플랜 보관기간 값 노출**: "무료 플랜은 대화가 N일 후 사라집니다" 안내에 N이 필요합니다. `GET /chat` 응답(또는 plan config 조회 API)에 `chat_retention_days`를 포함해주세요. 하드코딩하면 어드민에서 값 바꿀 때 앱과 어긋납니다.
2. **웹 충전 자동 로그인 연계** (§5-1): 외부 브라우저로 `/app/points`를 열면 웹 재로그인이 필요해 이탈 우려가 큽니다. 원타임 토큰 방식을 요청합니다 — 예: `POST /auth/web-session-token` → `{token, expires_in}`, 앱이 `https://the-meti.pages.dev/app/points?ott={token}`으로 오픈, 웹이 토큰 검증 후 세션 생성(1회용·짧은 만료).
3. **staging 채팅 테스트 시드**: `test@meti.dev`와 명함 교환이 완료된 상대 계정 1개를 시드해주세요 (채팅 E2E 테스트에 필요 — 현재는 방 생성 자체가 403).

## D. §4 푸시(FCM) 스펙 — 동의 + 세부 확정안

제안 스펙에 **동의**합니다. 아래 세부만 확정해서 진행해주세요.

### D-1. 디바이스 토큰 API
- `POST /users/me/device-tokens` `{token, platform, app_version?}` upsert / 로그아웃 시 `DELETE` — 제안대로 OK.
- 추가 제안: 발송 실패 시 FCM이 `UNREGISTERED`/`INVALID_ARGUMENT`를 반환한 토큰은 서버가 자동 삭제해주세요(죽은 토큰 누적 방지). 앱은 로그인 직후 + `onTokenRefresh` 시 등록 호출합니다.

### D-2. 발송 트리거 4종 — 동의
① 채팅 메시지 ② 그룹 가입 승인 ③ NFC 상태 변경 ④ 파트너 리워드 — 1차 범위로 충분합니다.
채팅 알림은 앱이 **현재 보고 있는 방이면 포그라운드에서 표시 억제** 처리하므로, 서버는 수신자가 방에 있는지 판단할 필요 없이 항상 발송하면 됩니다.

### D-3. 페이로드 형식 — notification + data 혼합 요청
data-only가 아닌 **notification 블록(title/body) + data 블록** 혼합으로 보내주세요. (안드로이드 백그라운드에서 data-only는 앱 프로세스 기동이 필요해 전달 신뢰도가 떨어집니다. iOS도 alert 표시가 단순해집니다.)

`data`는 FCM 제약상 **전부 문자열**로, type별 스펙:

| type | data 필드 | 앱 딥링크 |
|---|---|---|
| `chat_message` | `room_id`(필수), `sender_name` | 채팅방 (`/chat/room`) |
| `group_approved` | `group_id`(필수), `group_name` | 그룹 상세 (`/groups/detail`) |
| `nfc_status` | `application_id`(필수), `status`(pending/approved/issued), `card_id` | NFC 신청 내역 (화면 신규 예정) |
| `partner_reward` | `point_amount`(필수), `partner_name` | 리워드 (`/my/reward`) |

### D-4. FCM 프로젝트 생성 주체 — 앱팀 생성 제안
- **앱팀이 Firebase 프로젝트를 생성**하는 안을 제안합니다. `google-services.json`/`GoogleService-Info.plist`는 앱 리포에 들어가야 하고, iOS는 APNs 키(Apple Developer 계정) 연결도 앱 쪽 자산이라 앱팀이 만드는 게 자연스럽습니다.
- 생성 후 서버팀에는 **FCM HTTP v1용 서비스 계정 키(JSON)** 를 전달하겠습니다 — 발송 구현은 v1 API(`projects/{id}/messages:send`) 기준으로 준비해주세요 (legacy server key는 폐지됨).
- ⚠️ 단, 프로젝트를 어느 Google 계정(회사 조직 계정) 소유로 만들지는 **사람 확인이 필요**합니다 — 확정되면 프로젝트 ID를 공유하겠습니다. 서버팀은 이 확정을 기다리지 말고 토큰 API·발송 로직 구현을 먼저 진행해도 됩니다(키만 나중에 주입).

## E. §5 결제·포인트 — 확인
- 5-1 외부 브라우저 충전: 지침대로 구현 예정 (원타임 토큰은 §C-2 요청 참조).
- 5-2 NFC 실물카드: API 스펙 확인, 앱 신청 화면 신규 개발 예정입니다. `insufficient_points` → 충전 유도, 409 → 진행 중 안내, 신청 내역 상태 배지까지 반영하겠습니다.
- 5-3 구독 IAP: 확인. 현행 스펙대로 영수증/purchase token 전송 유지합니다.

## F. §6 알림함 API — 구현 요청 (2차)
푸시 도입과 묶어 `GET /notifications` + 읽음 처리(`PATCH /notifications/:id/read` 또는 일괄 읽음)를 요청합니다. 급하지 않음 — 푸시 §4 구현과 같은 사이클이면 충분합니다.

---

**앱 측 다음 순서**: QA 버그 수정 → 채팅 보강(§B) → 포인트 충전 전환·NFC 화면(§E) → FCM 클라이언트(§D). 문의는 이 문서에 코멘트로 부탁드립니다.
