# ELID by METI — 모바일 앱

Flutter. 디지털 명함 / 글로벌 네트워킹 앱. Maestro E2E 보유 (`.maestro/`).
서버는 `../the-meti` (실제 코드는 `the-meti/webapp`).

## 스토어 출시 전에 채워야 할 것

**아직 스토어에 제출된 적이 없다.** 제출하려면 아래가 전부 필요하다.
`C:\prostore-app`(드롱기 ProStore)이 이미 App Store 심사를 통과했으므로
**그 자산을 복사하는 것이 가장 빠르다.** 전역 스킬 `flutter-release` 참조.

| 항목 | 현재 | 필요 |
|---|---|---|
| `DEVELOPMENT_TEAM` | 미설정 | 설정 필요 |
| `TARGETED_DEVICE_FAMILY` | `"1,2"` | iPad 대응 안 할 거면 `1`. 안 그러면 iPad 스크린샷 세트를 별도로 요구받는다 |
| `PrivacyInfo.xcprivacy` | **없음** | 생성 + **pbxproj Resources에 등록** (파일만 만들면 번들에 안 들어간다) |
| `ITSAppUsesNonExemptEncryption` | **없음** | `false`로 추가하면 수출규정 질문이 아예 안 뜬다 |
| Android 릴리스 서명 | **없음 (debug 서명)** | keystore 생성 + `key.properties`. **둘 다 gitignore + 별도 백업** |
| 스토어 제출 문서 | 없음 | `C:\prostore-app\docs\APP_STORE_SUBMISSION.md`와 `play-store-submission/` 복사 |

**심사 계정 자격증명을 문서에 평문으로 넣지 않는다.** ProStore 문서를 복사할 때
반드시 placeholder로 치환한다 — 그쪽에 실제 계정이 커밋돼 있는 상태다.

## 번들 ID — `com.elid.app` 로 통일됨 (2026-08-20 실행)

| 플랫폼 | 값 |
|---|---|
| iOS 번들ID | `com.elid.app` |
| Android applicationId | `com.elid.app` |

대표 확정(2026-08-08) 후 스토어 출시 준비 단계에서 실행했다. Kotlin 패키지
디렉터리(`android/app/src/main/kotlin/com/elid/app/`)와 Maestro `appId`도 함께 옮겼다.

⚠ **스토어에 아직 등록한 적이 없어 선점 여부가 미확인이다.** 계정 확보 후 등록
시점에 이미 쓰이고 있으면 `com.myelid.app`(보유 도메인 기준)으로 간다.
서버측(`the-meti`)의 `APPLE_APP_ID`·`ANDROID_PACKAGE`·Universal Links 설정이
이 값에 묶여 있으므로 **바꾸면 서버와 같은 시점에 맞춰야 한다.**

macOS·Linux 데스크톱 타깃은 출시 대상이 아니라 옛 식별자를 그대로 뒀다.

## 빌드 환경

iOS 의존성은 **SPM**을 쓴다 (CocoaPods에서 마이그레이션됨). ProStore·dolunch와 다르다.

**이 프로젝트는 D드라이브에 있다.** pub 캐시가 C드라이브면 Kotlin 증분 컴파일이
상대경로 변환에 실패한다. dolunch가 같은 문제를 겪고 아래로 해결했다.

```properties
# android/gradle.properties
kotlin.incremental=false
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
```

힙을 8G로 두면 Gradle 데몬이 OOM으로 죽는다.

## 모빈 전사 컨텍스트

**계약 형태**: 유상 개발 (METI 묶음 계약)
**사업 맥락**: ELID 서버·해피트리·점심어때와 함께 **4개 프로젝트가 월 1,000만원
하나로 묶여** 있다. 정가 기준의 1/4이다.

**스토어 출시는 공수가 크다.** 위 표의 빈칸을 채우는 작업이 원래 계약 범위였는지
확인이 필요하다. 별건이면 인박스에 올린다.

### 전사 정보는 허브에 있다

**`../mobin_ceo`** — 없으면 `https://github.com/smee96/mobin-ceo` 를 clone.
`company/business-map.md`, `company/pricing.md` 참조.
**허브의 파일을 수정하지 않는다.** 예외는 아래 인박스뿐이다.

### 대표 판단이 필요하면 인박스에 남긴다

`../mobin_ceo/reports/inbox/YYYY-MM-DD-elid-app-<주제>.md`
형식은 `../mobin_ceo/reports/inbox/README.md` 참조.


### 대표와 확정한 것은 통지로 남긴다

대표가 이 개발 세션에 직접 붙어 무언가를 확정하는 일이 있다 — 규칙, 수치, 방향.
그 결정은 **이 세션과 커밋 메시지에만 남고 부사장 세션은 알지 못한다.**
허브는 전사 그림을 들고 판단하므로, 확정 사항이 허브에 없으면 판단이 어긋난다.

`../mobin_ceo/reports/inbox/YYYY-MM-DD-elid-app-확정-<주제>.md`

- **판단을 구하는 글이 아니다.** 결정된 것을 기록으로 넘기는 글이다. 3~5줄이면 된다.
- 무엇을 확정했는지 · 언제부터 적용되는지 · 코드 반영이 남았는지
  (예: "시뮬에만 반영, 본게임 이식 미완"). 배경 설명은 생략한다.
- 위의 판단 요청과 헷갈리지 않게 파일명에 `확정`을 넣는다.

**남길 것**: 사업 수치(요율·가격·정책), 아키텍처 방향, 일정 확정,
"이 방식으로 간다"는 대표 결정
**남기지 말 것**: 일상 개발 진행, 대표가 관여하지 않은 기술 선택


### 배포는 Cloudflare 우선, 안 되는 것만 Vultr

**대표 방침 (2026-08-22): 가능하면 Cloudflare를 쓴다.** 아래로 해결되면 그냥 쓴다 —
Pages(정적·SPA) · Workers(API) · D1(SQLite, **DB당 10GB**) · R2(파일, egress 무료) ·
KV · Queues · Cron Triggers · Durable Objects · Redirect Rules(리다이렉트에 서버 불필요).

**아래에 걸리면 Cloudflare로 안 된다 → Vultr 우회를 검토한다.**

JVM·PHP·Python 등 JS/WASM 외 런타임 · MySQL/PostgreSQL 서버 운영 · 10GB 초과 DB ·
상시 실행 데몬 · Workers CPU 시간을 넘는 장시간 작업 · 네이티브 바이너리(ffmpeg 등) ·
로컬 파일시스템 의존 · 고정 아웃바운드 IP 요구 · SMTP 직접 발송 · 임의 TCP/UDP 소켓

**판단 순서**
1. 걸리는 게 없으면 → 그냥 Cloudflare. 논의할 것 없다
2. 걸리면 → **그 부분만 떼어낼 수 있는지 먼저 본다.** 예: 무거운 이미지 변환만
   분리하고 나머지는 Workers에 남긴다
3. 못 떼면 → Vultr. 이때 **왜 Cloudflare로 안 되는지 인박스에 한 줄 남긴다**

3번의 기록이 없으면 나중에 "이게 왜 Vultr에 있지?"를 처음부터 다시 조사하게 된다.
실제로 2026-08-22 실사 전까지 허브에 Vultr 기록이 한 줄도 없었다.

**⚠ 기존 Vultr 서버(`141.164.43.43`)에 새로 얹지 않는다.** 체크앤바이 레거시
7종 + MySQL 18.6GB가 이미 올라가 있고 RAM이 빠듯하다(스왑 사용 중). 단일 장애점이라
여기에 추가하면 기존 실서비스까지 같이 위험해진다. Vultr가 필요하면 **인박스에
올려 대표 판단을 받는다** — 별도 인스턴스를 띄울지 함께 정한다.

기준표 원본: `../mobin_ceo/config/infra-policy.md`

### 이 문서의 관리 주체

이 CLAUDE.md의 전사 컨텍스트 절과 사업 맥락은 **허브(mobin_ceo)의 부사장 세션이
작성·갱신한다.** 다른 에이전트가 이 문서를 고쳐놓은 흔적이 보이면 그건 의도된 것이다.
부사장 세션은 정찰 에이전트(project-scout)로 이 폴더를 읽어가기도 한다 — 읽기 전용이라
코드는 건드리지 않는다. 문서 변경 이력이 궁금하면 git log로 확인하면 된다.
기술 내용(버그 위치, 스택 관례 등)의 출처는 대부분 부사장 세션의 정찰 보고서이며
허브의 reports/ 에 원본이 있다.
