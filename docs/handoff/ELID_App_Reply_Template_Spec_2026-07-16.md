# ELID 앱 → 서버 회신: 명함 템플릿 디자인 스펙 (웹 공유 페이지 반영용)

> From: 네이티브 앱 개발 에이전트 · To: ELID 서버팀
> 대응: ELID_Server_Reply_to_App_2026-07-15.md §3 (웹 공유 페이지가 template_id를 무시하고 단일 스타일로 렌더링하는 갭)
> 작성: 2026-07-16

## 회신 4건 앱 반영 현황

| # | 항목 | 앱 반영 |
|---|---|---|
| 1 | share_url | ✅ 하드코딩 제거, `card.share_url` 사용 (QR 인코딩 포함). 값이 없으면 웹 origin + `/card/{id}` 폴백 |
| 2 | tag_period | ✅ 병합 저장 중단 → `{tag_type, tag_value, tag_period}` 분리 전송. 앱 화면 3곳(생성·상세·공개뷰어)도 분리 렌더링 |
| 3 | template_id | ✅ 그대로 진행. 웹 반영용 스펙은 아래 §템플릿 스펙 |
| 4 | guardians | ✅ 앱에서 화면·라우트·프로바이더·mock 전부 제거 |

## 템플릿 스펙

공통 규칙:
- 카드 배경 = **선형 그라데이션**, 방향 좌상단(topLeft) → 우하단(bottomRight), `start` → `end` 2색.
- `accent` = 포인트 컬러 (아바타 테두리·이니셜·배지·구분선).
- 텍스트: `light=false`(다크 배경) → 본문 `#FFFFFF`, 보조 `rgba(255,255,255,0.75)`.
  `light=true`(라이트 배경) → 본문 `#0F172A`, 보조 `#64748B`.
- **알 수 없는 template_id는 `default`(엘리드)로 폴백** (앱과 동일 정책 권장).

### 킷 공식 조합 (tokens.json 기반)

| template_id | 이름 | start | end | accent | light |
|---|---|---|---|---|---|
| `default` | 엘리드 | `#1C3D72` | `#06122A` | `#C9A86A` (gold) | ✕ |
| `dark` | 미드나잇 | `#2A2E38` | `#070809` | `#C9A86A` (gold) | ✕ |
| `ocean_coral` | 틸 코랄 | `#0C5163` | `#021C23` | `#E58773` (coral) | ✕ |
| `forest_gold` | 민트 | `#1C3D72` | `#06122A` | `#6ABE9F` (mint) | ✕ |
| `violet_amber` | 바이올렛 | `#1C3D72` | `#06122A` | `#9283DC` (violet) | ✕ |

### 라이트 & 레거시 조합

| template_id | 이름 | start | end | accent | light |
|---|---|---|---|---|---|
| `minimal` | 미니멀 | `#FFFFFF` | `#E2E8F0` | `#0B1E40` | ○ |
| `ivory_navy` | 아이보리 | `#FDF6EC` | `#F0E6D2` | `#0B1E40` | ○ |
| `burgundy_rose` | 버건디 | `#4C0519` | `#9F1239` | `#FDA4AF` | ✕ |
| `modern_blue` | 모던 블루 | `#1E3A8A` | `#3B82F6` | `#93C5FD` | ✕ |
| `classic` | 클래식 | `#1A1A2E` | `#16213E` | `#E2B04A` | ✕ |

원본 소스: 앱 리포 `lib/features/cards/widgets/card_template_styles.dart` (id·이름은 여기서 변경 없이 유지 중 — 향후 추가·변경 시 이 문서 갱신해 재전달하겠습니다).

## 참고 (추가 문의 아님, 상태 공유)

- 채팅+푸시 핸드오프(ELID_Chat_Push_App_Handoff.md)는 수령 완료 — 앱 측 작업(폴링 채팅 보강, 신고/차단 UI, NFC 신청 화면, 외부 브라우저 충전)을 순차 진행 예정.
- FCM §4 스펙 의견과 FCM 프로젝트 생성 주체 협의는 푸시 착수 시점에 별도 회신하겠습니다.
