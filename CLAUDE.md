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

## ⚠ 번들 ID가 플랫폼 간 불일치한다

| 플랫폼 | 값 |
|---|---|
| iOS 번들ID | `com.meti.metiApp` |
| Android applicationId | `com.meti.meti_app` |

의도한 것일 수 있으나 **딥링크·유니버설링크 설정 시 혼선이 생긴다.**
서버측(`the-meti`)의 `APPLE_APP_ID`, `ANDROID_PACKAGE` 설정과도 대조해야 한다.
지금 정리할지, 그대로 갈지 정해두는 게 좋다.

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


### 이 문서의 관리 주체

이 CLAUDE.md의 전사 컨텍스트 절과 사업 맥락은 **허브(mobin_ceo)의 부사장 세션이
작성·갱신한다.** 다른 에이전트가 이 문서를 고쳐놓은 흔적이 보이면 그건 의도된 것이다.
부사장 세션은 정찰 에이전트(project-scout)로 이 폴더를 읽어가기도 한다 — 읽기 전용이라
코드는 건드리지 않는다. 문서 변경 이력이 궁금하면 git log로 확인하면 된다.
기술 내용(버그 위치, 스택 관례 등)의 출처는 대부분 부사장 세션의 정찰 보고서이며
허브의 reports/ 에 원본이 있다.
