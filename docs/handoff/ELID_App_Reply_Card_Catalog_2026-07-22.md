# 앱 → 서버/웹: 명함 디자인 카탈로그(24종) 핸드오프 회신

> From: 네이티브 앱 개발 에이전트 · To: ELID 서버/웹팀
> 작성: 2026-07-22 · 대응 문서: `ELID_Card_Design_Catalog_App_Handoff_2026-07-22.md`

## 0. 수신 확인
- staging `catalog.json`(24종, version 1) + 썸네일 PNG 라이브 확인했습니다.
- 방향 동의: 레이아웃 위젯 7종만 구현하고 색은 카탈로그 주입, 24종 하드코딩 없음.
- 웹 렌더(`/card/{id}`)를 시각 레퍼런스로 사용하겠습니다.

## 1. 회신 요청 3건 답변

### §8-1. 레거시 카드 처리 → **렌더 시 alias 치환만 (비파괴)**
- 저장값은 건드리지 않고, 렌더/편집 진입 시에만 `legacy_alias`로 해석합니다.
- 이유: 서버 스키마·데이터 무변경 원칙 유지, 일괄 마이그레이션 실패 케이스 제거, 웹과 동일 규칙이라 양쪽 표시 일관.
- 자연 마이그레이션: 사용자가 구 카드를 **편집 후 저장**하면 선택 UI가 신규 24종만 노출하므로 그 시점에 신규 id로 저장됩니다.

### §8-2. NFC 배지 판단 기준 → **서버 필드 추가 요청**
- 앱 로컬 판단(신청 내역 조인)은 웹 공유 페이지와 어긋날 수 있어, **카드 응답에 `nfc_status`**(`none | pending | issued`) 필드 추가를 요청합니다. 배지는 `issued`일 때만 표시.
- 서버 부담이 크면 과도기엔 앱이 `GET /cards/nfc/applications`를 조인해 판단하고, 웹은 배지 생략해도 무방합니다. 선호안 회신 주세요.

### §8-3. catalog.json 소비 방식 → **런타임 fetch + 로컬 캐시 + 번들 폴백**
- 권장안 수용: 앱 시작 시 fetch → SharedPreferences/파일 캐시(카탈로그 `version` 비교 갱신).
- 첫 실행 오프라인 대비, 빌드 시점 스냅샷을 앱 번들에 동봉해 최종 폴백으로 사용.
- 요청: 카탈로그 갱신 시 `version` 정수 증가 유지해주세요(변경 감지 기준).

## 2. 추가 조율 1건 — `__center` / `__leftbar` 합성 id 폴백
2026-07-20 §3으로 앱에 이미 배포된 `{구팔레트}__{center|leftbar}` 합성 id(예: `default__center`)가 `legacy_alias` 키에 없습니다.
- 앱 처리: 전체 id 매칭 실패 → **팔레트 부분만 alias 적용** 폴백 (`default__center` → `legacy_alias["default"]` = `deepblue__classic`).
- 웹도 동일 폴백 1줄 추가 요청: alias 미스 시 `split('__')[0]`으로 재조회. (staging에 해당 id 실카드는 테스트분 소수)

## 3. 앱 구현 계획 (참고)
1. `CardDesignCatalog` 서비스: fetch/캐시/폴백 + alias 해석기
2. 레이아웃 위젯 7종(solid/classic/split/serif/band/mono/edge) — 색·텍스트 규칙은 §4 + 원본 PNG 기준, serif는 시스템 세리프(예: NotoSerifKR 검토)
3. 생성/편집 화면: 기존 팔레트 칩+디자인 3종 UI 제거 → 24종 썸네일 그리드(네트워크 이미지 + 로딩/오프라인 폴백)
4. 기존 `kCardTemplateStyles`(10종)·center/leftbar 레이아웃은 렌더 폴백용으로만 유지 후 안정화 시 제거
5. 장식 텍스트(`DIGITAL CARD` 등)는 **고정 장식 유지**로 결정(§6 권장안 수용)

문의는 이 문서에 코멘트로 부탁드립니다.
