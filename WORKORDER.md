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

## 결정 필요 — 인박스에 올리고 진행

**iOS 번들ID(`com.meti.metiApp`)와 Android applicationId(`com.meti.meti_app`)가
불일치한다.** 웹뷰·딥링크 연동에서 혼선 소지가 있다. 지금 정리할지 그대로 갈지
대표 판단이 필요하다 → `D:\project\mobin_ceo\reports\inbox\`에 올린다.
서버의 `APPLE_APP_ID`/`ANDROID_PACKAGE` 설정값과 대조한 결과도 첨부한다.

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
