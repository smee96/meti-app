# 작업지시 — ELID 앱 (2026-08-08 주말)

발행: 부사장 세션 (mobin_ceo) · 승인: 대표
목표: **해피트리 제휴 탭의 앱 쪽 진입 흐름을 준비한다.**

## 선행 의존성을 알고 시작한다

서버 쪽(the-meti/webapp)이 이번 주말에 launch-token 발급과 JWKS를 구현 중이다.
**서버 완성 전에는 실토큰 왕복을 못 한다.** 그래서 이번 지시는
"서버가 준비되는 즉시 붙일 수 있는 상태"까지가 목표다. 서버를 기다리며
막히지 말고, 목(mock) 토큰으로 흐름을 먼저 완성한다.

## 구현할 것

### 1. 해피트리 제휴 진입 흐름

스펙: `../the-meti/ELID_Reply_to_HappyTree_v0.1.md` (확정본),
`../the-meti/ELID_HappyTree_Integration_Guide.md` (구조: 인앱 웹뷰 + 외부 결제)

- 제휴 탭(또는 진입점)에서 서버에 launch-token 요청
- 받은 토큰으로 해피트리 `/play?token=...` 웹뷰 오픈
- **결제는 웹뷰 안에서 하지 않는다** — 외부 브라우저로 나가는 구조다
  (스토어 인앱결제 정책 회피가 설계 의도다). 웹뷰에서 결제 URL을 감지하면
  외부 브라우저로 넘긴다
- 토큰 만료·실패 시 재요청 UX

### 2. 잔액 표시 (B-2)

해피트리 잔액 조회 API(`/api/partner/v1/balance`)를 호출해 코인 잔액을
제휴 탭에 표시한다. 서버 프록시를 거칠지 앱에서 직접 부를지는
스펙 문서를 따르고, 불명확하면 서버 세션과 같은 스펙을 보고 판단한 뒤
근거를 기록한다.

## 결정 완료 (2026-08-08 대표 확정) — 번들ID는 `com.elid.*`로 통일

iOS 번들ID(`com.meti.metiApp`)·Android applicationId(`com.meti.meti_app`) 불일치
건은 대표가 결정했다: **양 플랫폼 동일하게 `com.elid.app`으로 통일한다.**
미출시 상태인 지금이 바꿀 수 있는 마지막 시점이라서다. 인박스 질의는 불필요.
스토어 등록 시 `com.elid.app`이 선점돼 있으면 보유 도메인(my-elid.com) 기준
`com.myelid.app`으로 하고, 확정값을 인박스로 보고한다.

**실행 시점은 지금이 아니다.** 이번 주말 작업(제휴 진입 흐름)에서는 건드리지 말고,
스토어 출시 준비 단계에서 서명·딥링크 작업과 묶어 진행한다. 변경할 때 서버 쪽
`APPLE_APP_ID`/`ANDROID_PACKAGE`·Universal Links 설정과 **같은 시점에 맞춰야
한다** — 서버 세션에는 통지문이 가 있다
(`../the-meti/ELID_Decision_BundleID_2026-08-08.md`). 변경 착수 전에 서버 세션이
그 문서를 봤는지 확인하고, 완료하면 인박스로 보고한다.

## 여유가 되면 (선택)

스토어 출시 준비 갭 채우기 — `CLAUDE.md`의 표 참조:
`DEVELOPMENT_TEAM` 설정, `PrivacyInfo.xcprivacy` 생성+타깃 등록,
`ITSAppUsesNonExemptEncryption=false`, Android 릴리스 서명.
절차는 전역 스킬 `flutter-release`. **ProStore 문서를 복사할 때 심사 계정
자격증명은 반드시 placeholder로 치환한다.**

## 빌드 주의

이 프로젝트는 D드라이브다. Kotlin 증분 컴파일 이슈가 있으면
`android/gradle.properties`에 `kotlin.incremental=false` + 힙 4G/1G
(dolunch와 동일 대응).

완료 보고: `D:\project\mobin_ceo\reports\inbox\2026-08-09-elid-app-완료.md`
