# 작업지시 — ELID 앱 (2026-08-20 v2)

발행: 부사장 세션 (mobin_ceo) · 승인: 대표 이규한

**이 지시서는 2026-08-08자 v1을 대체한다.** v1의 목표(해피트리 제휴 진입 흐름,
B-2 잔액 표시)는 완료·보고됐다(`a526673`, 인박스 8/09 완료 보고).

## 목표

**스토어에 올릴 수 있는 상태까지 앱을 완성한다.**

대표 방침: *"결제는 나중에 붙이더라도, 일단 앱에 다 붙이고 서버쪽도 마무리한다."*
결제는 **화면만 붙이고 실제 결제는 열지 않는다.** 서버가 검증 없이 플랜을
내주던 경로를 막았기 때문이다(아래 1번).

---

## 1. 결제 UI — 붙이되 **503을 정상 분기로 처리** [지금 착수]

서버가 2026-08-20에 구독 결제 검증 경로를 **503으로 차단**했다.

```
POST /api/v1/payments/subscription/verify-apple   → 503
POST /api/v1/payments/subscription/verify-google  → 503
POST /api/v1/payments/verify-web                  → 503 (이전부터)
{"success": false, "error": "구독 결제 기능 준비 중입니다. (스토어 검증 연동 전)"}
```

차단 사유는 서버 회신문 §3에 있다 — 영수증을 Apple/Google에 검증하지 않고
곧바로 플랜을 부여하고 있어서, **위조 영수증으로 유료 플랜을 취득할 수 있는
상태**였다. 앱 문제가 아니라 서버 측 보안 조치다.

**할 것**

- [ ] 구독/결제 UI는 계획대로 붙인다
- [ ] **503을 정상 분기로 처리** — "준비 중입니다" 안내. 5xx라고 크래시하거나
      일반 오류 토스트로 흘리지 말 것. 서버가 명시적으로 요청한 사항이다
- [ ] 상품 ID를 정해 **서버에 공유** — 번들ID 확정(2번) 후에 정한다.
      서버 현재 값은 `com.meti.pro_monthly` / `com.meti.business_monthly`
- [ ] 플랜 한도 초과(`upgrade_required: true`) 분기는 명함·그룹 **동일 처리**
      (서버가 그룹에도 이미 내려주고 있음 — 8/20 회신 §2)

---

## 2. 번들ID `com.elid.app` 전환 — **실행 시점이 왔다** [지금 착수]

2026-08-08에 대표가 확정했고, v1 지시서는 *"실행 시점은 지금이 아니다,
스토어 출시 준비 단계에서 서명·딥링크와 묶어 진행"*으로 미뤄뒀다.
**지금이 그 단계다.**

- [ ] iOS 번들ID (`com.meti.metiApp`) · Android applicationId
      (`com.meti.meti_app`) → **양쪽 `com.elid.app`으로 통일**
- [ ] 선점돼 있으면 `com.myelid.app` (보유 도메인 my-elid.com 기준).
      **확정값을 인박스에 확정 통지로 보고**
- [ ] **서버와 같은 시점에 맞춘다** — 서버의 `APPLE_APP_ID` / `ANDROID_PACKAGE`
      / Universal Links 설정이 이 값에 묶여 있다. 서버 세션에 통지문이 가 있고
      (`../the-meti/ELID_Decision_BundleID_2026-08-08.md`), 서버 TASKS.md에도
      "앱이 값을 주면 즉시 반영" 항목으로 들어가 있다
- [ ] 상품 ID 규칙도 이때 확정해 서버에 전달

---

## 3. Android 릴리스 서명 준비 [지금 가능 — 대표 대기 아님]

딥링크(App Links) 실검증에 **릴리스 키스토어의 SHA256 지문**이 필요하다.
이건 외부 계정 없이 지금 만들 수 있다. **막혀 있는 딥링크 작업의 절반이
여기서 풀린다.**

- [ ] 릴리스 키스토어 생성 → SHA256 지문 산출 → **서버에 전달**
- [ ] ⚠ **키스토어를 분실하면 앱 업데이트가 영구히 불가능하다.** ProStore
      선례대로 대표 PC의 별도 백업 폴더에 보관한다
      (참고: `C:\Users\mobin_chairman\ProStore-Keystore-Backup\`)
- [ ] `android/key.properties`와 `android/*.jks`가 `.gitignore`에 있는지 확인
- [ ] 절차는 전역 스킬 **`flutter-release`**를 따른다

---

## 4. iOS 스토어 준비 — 계정 없이 가능한 것부터 [지금 착수]

Apple Team ID가 없어 Associated Domains capability 연결은 못 한다(대표 대기).
그 외는 지금 할 수 있다.

- [ ] `PrivacyInfo.xcprivacy` 생성 + 타깃 등록
- [ ] `ITSAppUsesNonExemptEncryption = false`
- [ ] 스크린샷 규격 준비 — ProStore가 **모빈에서 유일하게 iOS 심사를 통과한
      앱**이다. 그 자산을 복사하되 **심사용 테스트 계정 자격증명은 반드시
      placeholder로 치환**할 것 (평문 커밋 사고 방지)
- [ ] `DEVELOPMENT_TEAM`은 Team ID 수령 후

---

## 5. 딥링크 런타임 라우팅

- Android: 3번(SHA256)이 끝나면 **먼저 진행 가능**
- iOS: Team ID 수령 후
- 초대 링크 경로는 **서버가 301로 흡수**했으므로 intent-filter를 고칠 필요 없다
  (8/20 회신 §1). 다만 앱이 **새로 링크를 만들 때는 `/invite/{token}`** 정식
  경로를 쓴다 — `/app/invite/*`로 진입하면 웹 리다이렉트를 한 번 거친다

---

## 대표를 기다리는 것 (개발 블로커)

| 항목 | 막히는 작업 |
|---|---|
| **Apple 개발자 계정 → Team ID** | iOS 딥링크 capability, `DEVELOPMENT_TEAM`, 심사 제출 |
| **Firebase 소유 Google 계정** | FCM 푸시 (v1 지시서 §4에서 계속 대기 중) |
| Apple·Google 결제 자격증명 | 실결제 개방 (당분간 불필요 — 503 유지가 방침) |

**기다리는 항목 때문에 1~5의 착수 가능한 것을 미루지 않는다.**

## 보고

- 작업 세션이 끝나면 **현황 보고**를 인박스에 올린다
  (`../mobin_ceo/reports/inbox/YYYY-MM-DD-elid-app-현황.md`)
- 번들ID 확정 등 **결정된 사항은 확정 통지**로 (`...-elid-app-확정-<주제>.md`)
- 대표 판단이 필요한 건은 **별도 파일**로. 현황 보고에 섞지 않는다
- 형식: `../mobin_ceo/reports/inbox/README.md`
