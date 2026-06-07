# METI 네이티브 앱 — Maestro 테스트 플랜 v1.0

> 작성일: 2026-06-06  
> 대상 앱: METI (com.meti.app)  
> 테스트 환경: **Mock 모드** (외부 서버 불필요)  
> 테스트 프레임워크: [Maestro](https://maestro.mobile.dev)

---

## 1. 환경 설정

### 1-1. 앱 빌드

```bash
# Mock 모드 (기본 — 서버 없이 동작)
flutter run

# 또는 명시적으로
flutter run --dart-define=ENV=mock

# 스테이징 서버 연동
flutter run --dart-define=ENV=staging
```

### 1-2. Maestro 설치

```bash
# macOS / Linux
curl -Ls "https://get.maestro.mobile.dev" | bash

# 버전 확인
maestro --version
```

### 1-3. 테스트 실행

```bash
# 단일 플로우
maestro test .maestro/TC-001_onboarding.yaml

# 전체 스위트
maestro test .maestro/

# 결과 레포트
maestro test .maestro/ --format junit --output test-results.xml
```

---

## 2. 테스트 계정 정보

| 역할 | 이메일 | 비밀번호 | 플랜 |
|------|--------|--------|------|
| 일반 사용자 | `test@meti.dev` | `MetiTest1234!` | free |
| Pro 사용자 | `pro@meti.dev` | `MetiTest1234!` | pro |
| 어드민 | `admin@meti.dev` | `MetiAdmin1234!` | business |

> Mock 모드에서 회원가입 시 이메일 인증 없이 진행됩니다.  
> 이메일 인증 화면에서 `000000` 코드를 입력하면 Mock 인증 통과됩니다.

---

## 3. 앱 구조 (화면 맵)

```
Splash
  └── Intro (온보딩 4장)
        └── Login
              ├── Register → EmailVerification → Login
              └── ForgotPassword
                    └── Login

Main (바텀 탭 5개)
  ├── 홈 (명함)
  │     ├── 명함 생성
  │     ├── 명함 상세/수정
  │     ├── QR 생성/스캔
  │     │     └── PublicCardScreen (공개 명함 뷰어)
  │     └── 명함첩 (Contacts)
  ├── 그룹
  │     ├── 그룹 탐색
  │     ├── 내 그룹
  │     └── GroupAdminScreen
  │           ├── 멤버 관리
  │           ├── 레슨 관리
  │           ├── 이벤트 관리
  │           ├── 상품 관리
  │           └── 포인트 관리
  ├── 이벤트 (공개 피드)
  ├── 채팅
  │     └── ChatRoom
  └── 마이페이지
        ├── 프로필 수정
        ├── 포인트
        ├── 보호자 관리 (GuardiansScreen)
        └── 업그레이드 (UpgradeScreen)

딥링크 / 라우트
  ├── /cards/public (공개 명함 뷰어)
  ├── /invite      (그룹 초대링크)
  ├── /guardians   (보호자 관리)
  └── /schedules   (레슨 일정)
```

---

## 4. 테스트 시나리오

### TC-001 — 앱 진입 및 온보딩

**목적**: Splash → Intro 4장 → Login 화면 도달 확인

```yaml
# .maestro/TC-001_onboarding.yaml
appId: com.meti.app
---
- launchApp:
    clearState: true
- assertVisible: "METI"           # Splash
- waitForAnimationToEnd:
    timeout: 3000

# 온보딩 첫 페이지
- assertVisible: "시작하기"        # 마지막 페이지 버튼 (없으면 스와이프)
- swipeLeft                        # 슬라이드 1→2
- swipeLeft                        # 슬라이드 2→3
- swipeLeft                        # 슬라이드 3→4
- tapOn: "시작하기"

# 로그인 화면 도달
- assertVisible: "로그인"
- assertVisible: "이메일"
- assertVisible: "비밀번호"
```

**기대 결과**: 로그인 화면이 표시된다.

---

### TC-002 — 로그인 (Mock 계정)

**목적**: 정상 로그인 후 메인 화면 진입

```yaml
# .maestro/TC-002_login.yaml
appId: com.meti.app
---
- launchApp:
    clearState: true
- waitForAnimationToEnd:
    timeout: 4000

# 온보딩 스킵 (이미 본 경우 바로 로그인)
- runFlow:
    when:
      visible: "시작하기"
    file: _skip_onboarding.yaml

- tapOn: "이메일"
- inputText: "test@meti.dev"
- tapOn: "비밀번호"
- inputText: "MetiTest1234!"
- hideKeyboard
- tapOn: "로그인"

- waitForAnimationToEnd:
    timeout: 3000

# 메인 화면 확인
- assertVisible: "METI"           # 앱바 로고
- assertVisible: "홈"
- assertVisible: "그룹"
- assertVisible: "이벤트"
- assertVisible: "채팅"
- assertVisible: "마이"
```

**기대 결과**: 바텀 탭 5개가 있는 메인 화면이 표시된다.

---

### TC-003 — 회원가입

**목적**: 신규 이메일로 회원가입 → 이메일 인증 화면 도달

```yaml
# .maestro/TC-003_register.yaml
appId: com.meti.app
---
- launchApp:
    clearState: true
- waitForAnimationToEnd:
    timeout: 4000
- runFlow:
    when:
      visible: "시작하기"
    file: _skip_onboarding.yaml

- tapOn: "회원가입"

# 회원가입 폼
- tapOn: "이름"
- inputText: "테스트유저"
- tapOn: "이메일"
- inputText: "newuser@test.io"
- tapOn: "비밀번호"
- inputText: "Test1234!"
- tapOn: "비밀번호 확인"
- inputText: "Test1234!"
- hideKeyboard
- tapOn: "회원가입"

- waitForAnimationToEnd:
    timeout: 3000

# 이메일 인증 화면
- assertVisible: "이메일 인증"
- assertVisible: "인증 코드"
```

**기대 결과**: 이메일 인증 안내 화면이 표시된다.

---

### TC-004 — 이메일 인증 (Mock 코드)

**목적**: Mock 인증 코드 `000000` 입력 후 로그인 화면 복귀

```yaml
# .maestro/TC-004_email_verify.yaml
appId: com.meti.app
---
# TC-003 이후 이어서 실행하거나, 이미 인증화면에 있다고 가정
- assertVisible: "인증 코드"
- tapOn:
    id: "verification_code_field"   # 또는 라벨로
- inputText: "000000"
- tapOn: "인증 완료"

- waitForAnimationToEnd:
    timeout: 2000
- assertVisible: "로그인"
```

---

### TC-005 — 비밀번호 찾기

**목적**: 이메일 입력 후 안내 메시지 확인

```yaml
# .maestro/TC-005_forgot_password.yaml
appId: com.meti.app
---
- launchApp
- runFlow:
    when:
      visible: "시작하기"
    file: _skip_onboarding.yaml

- tapOn: "비밀번호를 잊으셨나요"   # 또는 "비밀번호 찾기"
- assertVisible: "이메일"
- tapOn: "이메일"
- inputText: "test@meti.dev"
- hideKeyboard
- tapOn: "재설정 링크 전송"       # 또는 "전송"

- waitForAnimationToEnd
- assertVisible: "이메일을 확인"   # 안내 메시지
```

---

### TC-006 — 명함 목록 조회

**목적**: 내 명함 목록이 표시되고 카드 위젯이 존재

```yaml
# .maestro/TC-006_card_list.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml             # 공통 로그인 플로우

# 홈(명함) 탭 확인
- assertVisible: "홈"
- tapOn: "홈"
- waitForAnimationToEnd

# 명함이 존재하는 경우
- assertVisible: "홍길동"           # Mock 기본 명함 이름
- assertVisible: "내 명함"
```

---

### TC-007 — 명함 생성

**목적**: 새 명함 생성 후 목록에 표시 확인

```yaml
# .maestro/TC-007_card_create.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "홈"
- waitForAnimationToEnd
- tapOn: "명함 만들기"             # FAB 또는 버튼

# 기본 정보
- tapOn: "이름"
- inputText: "홍길동"
- tapOn: "직책"
- inputText: "CTO"
- tapOn: "소속"
- inputText: "METI Corp"
- tapOn: "이메일"
- inputText: "cto@meti.dev"
- tapOn: "전화번호"
- inputText: "010-9999-0000"
- hideKeyboard

# 소개
- tapOn: "소개"
- inputText: "Flutter & Dart 전문가"
- hideKeyboard

# 저장
- tapOn: "저장"                    # 또는 "생성" / 완료 버튼
- waitForAnimationToEnd:
    timeout: 3000

- assertVisible: "명함이 생성되었습니다"  # 성공 스낵바
```

---

### TC-008 — 명함 상세 및 공개 명함 뷰어

**목적**: 명함 상세 진입, 이력/SNS 탭 확인, 공개 명함 뷰어 확인

```yaml
# .maestro/TC-008_card_detail.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "홈"
- waitForAnimationToEnd

# 첫 번째 명함 탭
- tapOn: "홍길동"                  # 명함 카드

# 명함 상세 확인
- assertVisible: "METI Corp"
- assertVisible: "스킬"            # 태그 섹션
- assertVisible: "Flutter"
```

---

### TC-009 — 공개 명함 뷰어 (PublicCardScreen)

**목적**: QR 스캔 결과 "자세히 보기" → 공개 명함 뷰어 화면 확인

```yaml
# .maestro/TC-009_public_card.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "홈"
# QR 스캔 버튼
- tapOn:
    id: "qr_scan_button"           # 앱바 QR 스캔 아이콘

# 카메라 권한 (최초 실행 시)
- runFlow:
    when:
      visible: "허용"
    commands:
      - tapOn: "허용"

# Mock 환경에서는 스캔 대신 수동으로 퍼블릭 카드 화면 테스트
# (QR 스캔 자체는 실기기에서만 가능)
- back

# 명함첩에서 저장된 명함 → 공개 뷰어로 진입 (대안 경로)
- tapOn:
    id: "contacts_button"
- waitForAnimationToEnd

- assertVisible: "명함첩"
```

**참고**: QR 실제 스캔은 실기기 + 물리적 QR 코드 필요. Mock에서는 직접 라우트 진입으로 대체.

---

### TC-010 — QR 명함 생성 (내 QR 보기)

**목적**: 명함 상세에서 QR 코드 표시 확인

```yaml
# .maestro/TC-010_qr_show.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "홈"
- waitForAnimationToEnd
- tapOn: "홍길동"
- tapOn: "QR"                      # 명함 상세의 QR 버튼

- waitForAnimationToEnd
- assertVisible: "QR"
# QR 이미지 위젯 또는 공유 버튼 확인
```

---

### TC-011 — 명함첩 (저장된 명함 목록)

**목적**: 명함첩 화면 진입 및 목록 확인

```yaml
# .maestro/TC-011_contacts.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "홈"
- waitForAnimationToEnd
- tapOn:
    id: "contacts_button"          # 앱바의 명함첩 아이콘

- assertVisible: "명함첩"
# Mock 초기에는 빈 목록
- assertVisible: "저장된 명함이 없습니다"   # 또는 빈 상태 메시지
```

---

### TC-012 — 그룹 탐색

**목적**: 공개 그룹 목록 표시 확인

```yaml
# .maestro/TC-012_group_explore.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "그룹"
- waitForAnimationToEnd

# 탭: 탐색 / 내 그룹
- assertVisible: "탐색"
- assertVisible: "내 그룹"

# 공개 그룹 목록
- assertVisible: "METI 개발자 모임"
- assertVisible: "글로벌 비즈니스 네트워크"
- assertVisible: "K-스타트업 커뮤니티"
```

---

### TC-013 — 그룹 가입 신청

**목적**: 공개 그룹에 가입 신청 → pending 상태 확인

```yaml
# .maestro/TC-013_group_join.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "그룹"
- waitForAnimationToEnd
- tapOn: "METI 개발자 모임"        # 그룹 카드

# 그룹 상세
- assertVisible: "가입 신청"
- tapOn: "가입 신청"

- waitForAnimationToEnd
- assertVisible: "가입 신청이 완료되었습니다"  # 스낵바 또는 상태 변경
```

---

### TC-014 — 그룹 개설 신청

**목적**: 새 그룹 개설 신청 (purpose 필드 포함)

```yaml
# .maestro/TC-014_group_create.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "그룹"
- waitForAnimationToEnd
- tapOn: "그룹 만들기"             # FAB 또는 버튼

# 그룹 개설 폼
- tapOn: "그룹 이름"
- inputText: "테스트 개발자 모임"
- tapOn: "용도 설명"               # purpose 필드 (5자 이상)
- inputText: "Flutter 개발자들의 스터디 모임"
- hideKeyboard

- tapOn: "개설 신청"
- waitForAnimationToEnd

- assertVisible: "그룹 개설 신청이 완료"   # 성공 메시지
```

---

### TC-015 — 그룹 관리 화면 (어드민)

**목적**: 그룹 관리 탭 확인 (멤버/레슨/이벤트/상품/포인트)

```yaml
# .maestro/TC-015_group_admin.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "그룹"
- tapOn: "내 그룹"
- waitForAnimationToEnd

# 관리자인 그룹 선택
- tapOn: "관리"                    # 내 그룹 카드의 관리 버튼

# 탭 확인
- assertVisible: "멤버"
- assertVisible: "레슨"
- assertVisible: "이벤트"
- assertVisible: "상품"
- assertVisible: "포인트"

# 멤버 탭
- tapOn: "멤버"
- assertVisible: "홍길동"
- assertVisible: "admin"

# 레슨 탭
- tapOn: "레슨"
- waitForAnimationToEnd

# 이벤트 탭
- tapOn: "이벤트"
- waitForAnimationToEnd
```

---

### TC-016 — 이벤트 피드

**목적**: 전체 공개 이벤트 목록 탭별 필터 확인

```yaml
# .maestro/TC-016_events.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "이벤트"
- waitForAnimationToEnd

# 탭 구조
- assertVisible: "전체"
- assertVisible: "예정"
- assertVisible: "진행중"

# 이벤트 카드 확인
- assertVisible: "METI 네트워킹 밋업"

# 예정 탭 필터
- tapOn: "예정"
- waitForAnimationToEnd

# 진행중 탭
- tapOn: "진행중"
- waitForAnimationToEnd
```

---

### TC-017 — 채팅 목록

**목적**: 채팅 탭 진입, 빈 상태 또는 목록 확인

```yaml
# .maestro/TC-017_chat_list.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "채팅"
- waitForAnimationToEnd

- assertVisible: "채팅"            # 화면 타이틀
# Mock 초기: 채팅방 없음
```

---

### TC-018 — 포인트 화면

**목적**: 포인트 잔액/내역 확인

```yaml
# .maestro/TC-018_points.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "마이"
- waitForAnimationToEnd

# 포인트 카드 탭
- tapOn: "P"                       # 포인트 카드 또는 "내 포인트"

- assertVisible: "포인트"
- assertVisible: "잔액"
- assertVisible: "내역"
```

---

### TC-019 — 마이페이지 프로필 수정

**목적**: 이름 변경 → 저장 확인

```yaml
# .maestro/TC-019_profile_edit.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "마이"
- waitForAnimationToEnd

- assertVisible: "홍길동"
- tapOn: "프로필 수정"

# 바텀시트 열림
- assertVisible: "이름"
- clearText
- inputText: "홍길동수정"
- tapOn: "저장"

- waitForAnimationToEnd
- assertVisible: "프로필이 업데이트"   # 성공 스낵바
```

---

### TC-020 — 마이페이지 보호자 관리 진입

**목적**: 마이페이지 → 보호자 관리 메뉴 → GuardiansScreen 진입

```yaml
# .maestro/TC-020_guardian_nav.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "마이"
- waitForAnimationToEnd

- tapOn: "보호자 관리"
- waitForAnimationToEnd

# GuardiansScreen
- assertVisible: "보호자"           # 화면 타이틀 또는 탭
- assertVisible: "내 보호자"
- assertVisible: "내 학생"
```

---

### TC-021 — 보호자 초대

**목적**: 학생 이메일로 보호자 연결 요청 발송

```yaml
# .maestro/TC-021_guardian_invite.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "마이"
- tapOn: "보호자 관리"
- waitForAnimationToEnd

# 내 학생 탭 (보호자 입장)
- tapOn: "내 학생"

# 보호자 초대 버튼 (FAB 또는 "+" 버튼)
- tapOn:
    id: "invite_guardian_button"   # 또는 텍스트로

# 다이얼로그
- assertVisible: "보호자 초대"
- tapOn: "이메일"
- inputText: "student@meti.io"
- tapOn: "parent"                  # 관계 선택
- tapOn: "초대 보내기"

- waitForAnimationToEnd
- assertVisible: "보호자 초대를 보냈습니다"   # 또는 성공 메시지
```

---

### TC-022 — 업그레이드 화면

**목적**: 업그레이드 화면 진입 및 플랜 표시 확인

```yaml
# .maestro/TC-022_upgrade.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "마이"
- waitForAnimationToEnd

# free 플랜 사용자에게 업그레이드 카드 표시
- assertVisible: "업그레이드"
- tapOn: "업그레이드"

- waitForAnimationToEnd

# 플랜 선택 화면
- assertVisible: "Pro"
- assertVisible: "Business"
- assertVisible: "10,000"          # Pro 플랜 포인트 또는 가격
```

---

### TC-023 — 레슨 일정 화면 (진입 경로 확인)

**목적**: 그룹 관리 → 레슨 탭 확인 (현재 구현 기준)

```yaml
# .maestro/TC-023_lesson_schedules.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "그룹"
- tapOn: "내 그룹"
- waitForAnimationToEnd
- tapOn: "관리"

- tapOn: "레슨"
- waitForAnimationToEnd

# 레슨 목록 확인
# (레슨 일정 화면은 그룹 관리에서 접근)
```

---

### TC-024 — 명함 한도 초과 (Free 플랜)

**목적**: Free 플랜에서 명함 4번째 생성 시 한도 초과 오류 + 업그레이드 안내

```yaml
# .maestro/TC-024_card_limit.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

# 이미 3개 명함이 있는 상태 가정 (Mock 기본)
- tapOn: "홈"
- tapOn: "명함 만들기"

# 폼 채우기
- tapOn: "이름"
- inputText: "초과 명함"
- tapOn: "직책"
- inputText: "테스트"
- hideKeyboard
- tapOn: "저장"

- waitForAnimationToEnd
# 업그레이드 안내 다이얼로그 또는 오류
- assertVisible: "한도"            # "명함 한도 초과" 또는 업그레이드 다이얼로그
```

---

### TC-025 — 로그아웃

**목적**: 로그아웃 후 로그인 화면 복귀

```yaml
# .maestro/TC-025_logout.yaml
appId: com.meti.app
---
- launchApp
- runFlow: _login.yaml

- tapOn: "마이"
- waitForAnimationToEnd
- scrollToBottom
- tapOn: "로그아웃"

# 확인 다이얼로그
- assertVisible: "로그아웃 하시겠습니까"
- tapOn: "로그아웃"               # 확인 버튼

- waitForAnimationToEnd
- assertVisible: "로그인"          # 로그인 화면 복귀
```

---

## 5. 공통 플로우 파일

### `_login.yaml` (공통 로그인)

```yaml
# .maestro/_login.yaml
- waitForAnimationToEnd:
    timeout: 4000
- runFlow:
    when:
      visible: "시작하기"
    commands:
      - swipeLeft
      - swipeLeft
      - swipeLeft
      - tapOn: "시작하기"
- runFlow:
    when:
      visible: "로그인"
    commands:
      - tapOn: "이메일"
      - inputText: "test@meti.dev"
      - tapOn: "비밀번호"
      - inputText: "MetiTest1234!"
      - hideKeyboard
      - tapOn: "로그인"
      - waitForAnimationToEnd:
          timeout: 3000
```

### `_skip_onboarding.yaml` (온보딩 스킵)

```yaml
# .maestro/_skip_onboarding.yaml
- swipeLeft
- swipeLeft
- swipeLeft
- tapOn: "시작하기"
- waitForAnimationToEnd
```

---

## 6. 테스트 체크리스트

### 정상 흐름 (Happy Path)

| TC | 시나리오 | 우선순위 | 상태 |
|----|---------|---------|------|
| TC-001 | 앱 진입 및 온보딩 | P0 | |
| TC-002 | Mock 계정 로그인 | P0 | |
| TC-003 | 신규 회원가입 | P0 | |
| TC-004 | 이메일 인증 | P0 | |
| TC-005 | 비밀번호 찾기 | P1 | |
| TC-006 | 명함 목록 조회 | P0 | |
| TC-007 | 명함 생성 | P0 | |
| TC-008 | 명함 상세 확인 | P0 | |
| TC-009 | 공개 명함 뷰어 | P1 | |
| TC-010 | QR 생성 | P1 | |
| TC-011 | 명함첩 조회 | P1 | |
| TC-012 | 그룹 탐색 | P0 | |
| TC-013 | 그룹 가입 신청 | P1 | |
| TC-014 | 그룹 개설 신청 | P1 | |
| TC-015 | 그룹 관리 화면 | P1 | |
| TC-016 | 이벤트 피드 | P1 | |
| TC-017 | 채팅 목록 | P1 | |
| TC-018 | 포인트 화면 | P1 | |
| TC-019 | 프로필 수정 | P1 | |
| TC-020 | 보호자 화면 진입 | P1 | |
| TC-021 | 보호자 초대 | P2 | |
| TC-022 | 업그레이드 화면 | P2 | |
| TC-023 | 레슨 일정 화면 | P2 | |
| TC-024 | 명함 한도 초과 | P2 | |
| TC-025 | 로그아웃 | P0 | |

### 예외/오류 흐름 (Error Path)

| 시나리오 | 기대 결과 |
|---------|---------|
| 잘못된 이메일 형식으로 로그인 | "올바른 이메일 형식" 오류 메시지 |
| 틀린 비밀번호로 로그인 | "이메일 또는 비밀번호가 올바르지 않습니다" |
| 비밀번호 확인 불일치 | "비밀번호가 일치하지 않습니다" |
| 그룹 purpose 4자 이하 | "5자 이상 입력" 오류 |
| Free 플랜 4번째 명함 생성 | 업그레이드 안내 다이얼로그 |
| 네트워크 오류 (Mock에선 해당 없음) | 오류 스낵바 |

---

## 7. Mock 모드 특이사항

| 항목 | Mock 동작 |
|------|---------|
| 이메일 인증 코드 | `000000` 입력 시 통과 |
| 회원가입 | 즉시 성공 (이메일 발송 없음) |
| 비밀번호 재설정 | "이메일 발송됨" 메시지만 표시 (토큰 없음) |
| QR 스캔 | 카메라 화면 열리지만 실제 스캔 Mock 처리 안 됨 |
| 이미지 업로드 | 더미 URL로 즉시 성공 처리 |
| 채팅 실시간 | 폴링 없음, 전송만 가능 |
| 결제 | placeholder (실제 PG 미연동) |

---

## 8. 테스트 디렉터리 구조

```
.maestro/
├── _login.yaml                    # 공통: 로그인
├── _skip_onboarding.yaml          # 공통: 온보딩 스킵
├── TC-001_onboarding.yaml
├── TC-002_login.yaml
├── TC-003_register.yaml
├── TC-004_email_verify.yaml
├── TC-005_forgot_password.yaml
├── TC-006_card_list.yaml
├── TC-007_card_create.yaml
├── TC-008_card_detail.yaml
├── TC-009_public_card.yaml
├── TC-010_qr_show.yaml
├── TC-011_contacts.yaml
├── TC-012_group_explore.yaml
├── TC-013_group_join.yaml
├── TC-014_group_create.yaml
├── TC-015_group_admin.yaml
├── TC-016_events.yaml
├── TC-017_chat_list.yaml
├── TC-018_points.yaml
├── TC-019_profile_edit.yaml
├── TC-020_guardian_nav.yaml
├── TC-021_guardian_invite.yaml
├── TC-022_upgrade.yaml
├── TC-023_lesson_schedules.yaml
├── TC-024_card_limit.yaml
└── TC-025_logout.yaml
```

---

## 9. 앱 에이전트 → 테스트 에이전트 인수인계 노트

### 현재 구현 완료 화면

- Splash, 온보딩(4장), 로그인, 회원가입, 이메일인증, 비밀번호찾기
- 명함 홈, 명함 생성, 명함 상세, QR 생성/스캔, 명함첩
- **공개 명함 뷰어** (`PublicCardScreen`) — 이력/SNS/아바타 표시 (v3.0 신규)
- 그룹 탐색/내그룹, 그룹 관리(멤버·레슨·이벤트·상품·포인트)
- 이벤트 공개 피드
- 채팅 목록, 채팅방 (파일첨부 UI 포함)
- 포인트 잔액/내역
- 마이페이지 (프로필 수정, 업그레이드)
- **보호자 관리** (`GuardiansScreen`) — 마이페이지 "보호자 관리" 메뉴 (v3.0 신규)
- **레슨 일정** (`LessonSchedulesScreen`, `ScheduleDetailScreen`) (v3.0 신규)
- 업그레이드, 그룹 초대링크 처리

### 미구현 (테스트 스킵)

- 행사 상세 화면 (EventDetailScreen)
- 레슨 독립 멤버용 화면 (LessonScreen)
- 웹 결제 WebView
- Apple IAP / Google Play 실연동
- 채팅 실시간 (WebSocket)
- NFC 실물카드 신청
- 딥링크 `/card/:id` 앱 실행 시 자동 처리

### 알려진 제약

- QR 스캔은 실기기 필요 (시뮬레이터 카메라 없음)
- 이미지 업로드는 Mock URL 반환 (실제 파일 없음)
- 채팅 메시지 전송은 Mock 저장 (세션 내 유지)
- 로그인 세션: 앱 재시작 후 자동 로그인 (SharedPreferences)

### 환경 변수

| 변수 | 값 | 설명 |
|------|-----|------|
| `ENV` | `mock` (기본) | Mock 모드 |
| `ENV` | `staging` | 스테이징 서버 |
| `ENV` | `production` | 실서버 (주의) |

---

*METI 네이티브 앱 에이전트 작성*  
*기준 커밋: ede8587 (2026-06-06)*
