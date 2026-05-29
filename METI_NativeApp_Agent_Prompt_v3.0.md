# METI 네이티브 앱 개발 에이전트 시작 프롬프트 v3.0

> 최종 업데이트: 2026-05-29  
> 변경 이력: **v2.9 → v3.0** — Guardian(보호자) API 신규 · Lesson Schedule/Attendance API 신규 · auth 보안 패치 · 채팅 보관 정책 · 채팅 파일 업로드 · 파트너 WebView URL · 백엔드 현황 최신화

---

## 🔔 이 문서의 목적

**v2.8 + v2.9 프롬프트 + v1.7 스펙** 기준으로 이미 전달된 내용을 **기반**으로 하며,  
본 문서는 **그 이후 백엔드에서 추가/변경된 사항만** delta(차이) 형식으로 기술합니다.

> v2.8 · v2.9 문서와 v1.7 기획서를 함께 읽어야 전체 API 명세가 완성됩니다.

---

## 📌 기준 정보

- **Base URL**: `https://the-meti.pages.dev/api/v1`
- **인증**: JWT Bearer Token (Access 7일 / Refresh 30일, Token Rotation)
- **스토리지**: Cloudflare R2 (`the-meti-storage`)
  - Public CDN URL: `https://pub-9e92c640989d47f69f8e3f749c4de9c0.r2.dev`
- **GitHub (백엔드)**: https://github.com/smee96/THE-METI
- **GitHub (앱)**: https://github.com/smee96/meti-app
- **최신 배포**: https://the-meti.pages.dev (2026-05-29, 커밋 `0c65554`)
- **앱 번들 ID**: `com.cardconnect.network`

---

## 🗂️ v3.0 변경사항 요약

| 영역 | 변경 유형 | 내용 |
|------|----------|------|
| `POST /guardians/link` | **신규 API** | 보호자 연결 요청 |
| `POST /guardians/link/:id/accept` | **신규 API** | 연결 수락 (학생/super_admin) |
| `POST /guardians/link/:id/reject` | **신규 API** | 연결 거절 (학생 본인) |
| `GET /guardians` | **신규 API** | 보호자·학생 목록 (`?role=mine\|students`) |
| `GET /guardians/pending` | **신규 API** | 대기 중인 연결 요청 목록 |
| `DELETE /guardians/:guardianUserId` | **신규 API** | 보호자 연결 해제 (양방향) |
| `GET /guardians/lesson-groups` | **신규 API** | 내 학생들의 레슨 그룹 목록 |
| `GET /lessons/:groupId/schedules` | **신규 API** | 레슨 일정 목록 (페이지네이션) |
| `POST /lessons/:groupId/schedules` | **신규 API** | 레슨 일정 생성 (강사급) |
| `GET /lessons/:groupId/schedules/:id` | **신규 API** | 일정 상세 + 출석 현황 |
| `POST /lessons/:groupId/schedules/:id/attendance` | **신규 API** | 출석 배치 처리 |
| `GET /lessons/:groupId/students` | **신규 API** | 학생 목록 + 보호자 정보 + 출석률 |
| `POST /auth/register` 응답 | **보안 패치** | `verify_token` 응답 제거 |
| `POST /auth/forgot-password` 응답 | **보안 패치** | `reset_token` 응답 제거 |
| 채팅 보관 정책 | **신규 정책** | 플랜별 메시지 보관 일수 (free 1일 / pro 90일 / business 무제한) |
| 채팅 파일 업로드 | **신규 기능** | 채팅방 이미지(5MB) / 파일(20MB) R2 업로드 |
| 파트너 WebView URL | **스키마 추가** | `partner_services.webview_url` 컬럼 추가 |

---

## 1. auth 보안 패치 (v3.0)

### 1-A. 회원가입 응답 변경

```diff
// POST /auth/register → 201
{
  "success": true,
  "data": {
    "user_id": 2,
    "email": "user@example.com"
-   "verify_token": "uuid-..."   // ← 제거됨 (보안 패치)
  },
  "message": "회원가입이 완료되었습니다. 이메일 인증을 진행해주세요."
}
```

**앱 처리**: 회원가입 성공 후 `verify_token`을 사용하지 말고, "이메일을 확인하세요" 안내 화면으로 이동.  
**현황**: 이메일 발송 서비스 미연동. 개발/테스트 시 DB에서 직접 토큰 확인 필요.

> ⚠️ **Mock 수정 필요**: `MockAuth.register()` 응답에서 `verify_token` 제거.  
> 단, 테스트 편의를 위해 Mock 환경에서는 `verify_token`을 유지해도 무방.

---

### 1-B. 비밀번호 재설정 응답 변경

```diff
// POST /auth/forgot-password → 200
{
  "success": true,
- "data": { "reset_token": "uuid-..." },   // ← 제거됨 (보안 패치)
+ "data": null,
  "message": "비밀번호 재설정 이메일이 발송되었습니다."
}
```

**앱 처리**: `data`가 `null`이어도 정상 처리. "이메일을 확인하세요" 안내만 표시.

---

### 1-C. 앱 코드 수정 대상 (verify_token 의존 제거)

v3.0 보안 패치에 따라 수정이 필요한 앱 파일 목록입니다.

**`lib/features/auth/screens/register_screen.dart`** (L88~94)
```diff
// 기존 — verify_token을 arguments로 전달
Navigator.pushReplacementNamed(
  context,
  AppRoutes.emailVerification,
  arguments: {
    'email': _emailCtrl.text.trim(),
-   'verify_token': result['verify_token'],   // ← 실서버 응답에 없으므로 null이 됨
  },
);

// 수정 — verify_token 전달 제거
Navigator.pushReplacementNamed(
  context,
  AppRoutes.emailVerification,
  arguments: {
    'email': _emailCtrl.text.trim(),
    // verify_token 제거: 실서버에서 응답하지 않음
  },
);
```

**`lib/features/auth/screens/email_verification_screen.dart`** (L19, L27, L102~135)
```diff
// 기존 — _devToken 표시 블록 (개발 편의용)
String? _devToken; // 개발환경에서만 표시
...
_devToken = args['verify_token'] as String?;
...
if (_devToken != null) ...[
  // 토큰 자동 입력 버튼
]

// 수정 — _devToken 관련 코드 전체 제거
// 실서버에서 verify_token을 응답하지 않으므로 개발 편의 UI도 제거
// 테스트 시에는 Mock DB (MockStore.verifyTokens) 에서 직접 확인
```

> 💡 **Mock 환경 테스트**: `MockAuth.register()`는 내부적으로 `MockStore.verifyTokens`에  
> 토큰을 저장합니다. 단순히 응답에서 제거만 하면 됩니다. `verifyEmail()` 호출은  
> 여전히 `MockStore.verifyTokens`를 통해 정상 동작합니다.

---

### 1-D. api_client.dart forgot-password Mock 응답 보안 패치

```diff
// api_client.dart _mockDispatch() 내부
if (path == '/auth/forgot-password') {
  return {
    'success': true,
-   'data': {'reset_token': 'mock-reset-token-123'},   // ← 제거
+   'data': null,
    'message': '비밀번호 재설정 이메일이 발송되었습니다.',
  };
}
```

---

## 2. 명함첩 API 경로 정정 (v1.7)

> ⚠️ **v1.6 표기 오류 정정** — 앱 코드에서 `/cards/saved` 경로를 사용 중이라면 반드시 수정하세요.

| 기존 표기 (v1.6) | 실제 구현 (v1.7~) | 비고 |
|-----------------|------------------|------|
| `GET /cards/saved` | `GET /cards/contacts/list` | 저장된 명함 목록 |
| `POST /cards/:id/save` | `POST /cards/:id/save` | 경로 동일, 내부 테이블만 변경 |

**DB 구조**: `POST /cards/:id/save`는 내부적으로 `card_contacts` 테이블을 사용합니다.

```dart
// ❌ 잘못된 경로
final response = await _api.get('/cards/saved');

// ✅ 올바른 경로
final response = await _api.get('/cards/contacts/list');
```

**Mock 처리**: `api_client.dart`에서 `/cards/contacts/list` 경로는 이미 처리 중입니다.  
`/cards/saved` 경로로 호출 시 `null` 응답이 반환되므로 반드시 경로를 수정하세요.

---

## 3. Guardian (보호자) API — 신규 🆕

> **Base Path**: `/api/v1/guardians`  
> **대상**: 미성년자(MINOR) ↔ 보호자(부모/강사) 연결 관리  
> **DB 테이블**: `user_guardians` (migration 0010 기존 존재)

### DB 스키마

```sql
user_guardians
  id                INTEGER PK
  user_id           INTEGER -- 학생(MINOR) FK→users
  guardian_user_id  INTEGER -- 보호자/강사(ADULT) FK→users
  relation          TEXT    -- 'parent' | 'teacher'
  status            TEXT    -- 'pending' | 'active' | 'rejected'
  invited_at        DATETIME
  accepted_at       DATETIME NULL
```

---

### 2-1. 보호자 연결 요청

```
POST /guardians/link   🔐
```

> 보호자(부모/강사)가 학생에게 연결 요청을 보냄

**Request**
```json
{
  "minor_user_id": 5,
  "minor_email": "student@meti.io",
  "relation": "teacher",
  "group_id": 2
}
```

> `minor_user_id` 또는 `minor_email` 중 하나 필수. 둘 다 전송 시 `minor_user_id` 우선.  
> `group_id` optional: 해당 그룹 멤버의 보호자로 자동 등록.

**Response 201**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "minor_user_id": 5,
    "guardian_user_id": 3,
    "relation": "teacher",
    "status": "pending"
  },
  "message": "보호자 연결 요청이 발송되었습니다."
}
```

**에러**
- `400`: minor_user_id / minor_email 모두 미전송 | 자기 자신에게 요청
- `404`: 학생을 찾을 수 없음
- `409`: 이미 연결 완료 또는 대기 중 요청 존재

> ✅ `rejected` 상태인 경우 재요청 가능 (status → `pending` 갱신)

---

### 2-2. 보호자 연결 수락

```
POST /guardians/link/:requestId/accept   🔐
권한: 학생 본인 또는 super_admin
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "request_id": 1,
    "minor_user_id": 5,
    "guardian_user_id": 3,
    "relation": "teacher",
    "status": "active"
  },
  "message": "보호자 연결이 수락되었습니다."
}
```

**에러**: `404` 요청 없음 | `400` 이미 처리된 요청 | `403` 권한 없음

---

### 2-3. 보호자 연결 거절

```
POST /guardians/link/:requestId/reject   🔐
권한: 학생 본인만
```

**Response 200**
```json
{
  "success": true,
  "data": { "request_id": 1, "status": "rejected" },
  "message": "보호자 연결 요청이 거절되었습니다."
}
```

---

### 2-4. 보호자/학생 목록 조회

```
GET /guardians?role=mine        🔐  (내 보호자 목록 — 학생 입장)
GET /guardians?role=students    🔐  (내 학생 목록 — 보호자/강사 입장)
```

**Response 200 — role=students**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "relation": "teacher",
      "status": "active",
      "accepted_at": "2026-05-20T10:00:00Z",
      "student_id": 5,
      "student_name": "김학생",
      "student_email": "student@meti.io",
      "user_type": "MINOR",
      "birth_date": "2012-04-10",
      "avatar_url": null
    }
  ]
}
```

**Response 200 — role=mine**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "relation": "teacher",
      "status": "active",
      "accepted_at": "2026-05-20T10:00:00Z",
      "guardian_id": 3,
      "guardian_name": "김강사",
      "guardian_email": "teacher@meti.io",
      "guardian_avatar": null
    }
  ]
}
```

---

### 2-5. 대기 중인 연결 요청 목록

```
GET /guardians/pending   🔐
권한: 학생 본인 (수락/거절해야 할 요청 목록)
```

**Response 200**
```json
{
  "success": true,
  "data": [
    {
      "request_id": 1,
      "relation": "parent",
      "status": "pending",
      "invited_at": "2026-05-28T09:00:00Z",
      "guardian_id": 4,
      "guardian_name": "박부모",
      "guardian_email": "parent@meti.io",
      "guardian_avatar": null
    }
  ]
}
```

> 로그인 시 또는 주기적 polling으로 확인하여 알림 표시 권장.

---

### 2-6. 보호자 연결 해제

```
DELETE /guardians/:guardianUserId   🔐
권한: 학생 본인 또는 보호자 본인 (양방향 해제 가능)
```

**Response 200**
```json
{
  "success": true,
  "data": null,
  "message": "보호자 연결이 해제되었습니다."
}
```

---

### 2-7. 내 학생들의 레슨 그룹 목록

```
GET /guardians/lesson-groups   🔐
권한: 보호자/강사 (active 담당 학생이 있어야 결과 반환)
```

**Response 200**
```json
{
  "success": true,
  "data": [
    {
      "group_id": 2,
      "group_name": "피아노 레슨반",
      "group_type": "LESSON",
      "description": "초급 피아노 수업",
      "student_count": 3
    }
  ]
}
```

---

## 4. Lesson Schedule/Attendance API — 신규 🆕

> **Base Path**: `/api/v1/lessons/:groupId/`  
> **DB 테이블**: `lesson_schedules`, `lesson_attendances` (migration 0010 기존 존재)

### DB 스키마

```sql
lesson_schedules
  id               INTEGER PK
  group_id         INTEGER FK→groups
  instructor_id    INTEGER FK→users
  title            TEXT
  description      TEXT NULL
  scheduled_at     DATETIME    -- 수업 시작 일시
  duration_minutes INTEGER     -- 수업 시간 (분)
  location         TEXT NULL
  capacity         INTEGER NULL
  status           TEXT        -- 'scheduled' | 'completed' | 'cancelled'
  created_at       DATETIME

lesson_attendances
  id           INTEGER PK
  schedule_id  INTEGER FK→lesson_schedules
  student_id   INTEGER FK→users
  status       TEXT            -- 'present' | 'absent' | 'late' | 'excused'
  note         TEXT NULL
  recorded_at  DATETIME
```

---

### 3-1. 레슨 일정 목록

```
GET /lessons/:groupId/schedules   🔐
```

**Query 파라미터**

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| `page` | int | 페이지 번호 (기본 1) |
| `limit` | int | 페이지 크기 (기본 20) |
| `status` | string | `scheduled` \| `completed` \| `cancelled` (생략 시 전체) |

**Response 200**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "group_id": 2,
      "instructor_id": 3,
      "instructor_name": "김강사",
      "title": "5월 4주차 피아노 수업",
      "description": "바이엘 30번",
      "scheduled_at": "2026-05-28T10:00:00Z",
      "duration_minutes": 60,
      "location": "2층 강의실",
      "capacity": 5,
      "status": "scheduled",
      "attendance_count": 0,
      "created_at": "2026-05-25T09:00:00Z"
    }
  ],
  "pagination": {
    "page": 1, "limit": 20, "total": 1, "has_next": false
  }
}
```

---

### 3-2. 레슨 일정 생성

```
POST /lessons/:groupId/schedules   🔐
권한: group admin / sub_admin / instructor
```

**Request**
```json
{
  "title": "5월 4주차 피아노 수업",
  "description": "바이엘 30번",
  "scheduled_at": "2026-05-28T10:00:00Z",
  "duration_minutes": 60,
  "location": "2층 강의실",
  "capacity": 5
}
```

**Response 201**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "group_id": 2,
    "instructor_id": 3,
    "title": "5월 4주차 피아노 수업",
    "scheduled_at": "2026-05-28T10:00:00Z",
    "duration_minutes": 60,
    "location": "2층 강의실",
    "capacity": 5,
    "status": "scheduled",
    "created_at": "2026-05-25T09:00:00Z"
  },
  "message": "레슨 일정이 생성되었습니다."
}
```

**에러**: `403` 권한 없음 | `404` 그룹 없음

---

### 3-3. 레슨 일정 상세 + 출석 현황

```
GET /lessons/:groupId/schedules/:scheduleId   🔐
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "group_id": 2,
    "title": "5월 4주차 피아노 수업",
    "scheduled_at": "2026-05-28T10:00:00Z",
    "duration_minutes": 60,
    "location": "2층 강의실",
    "status": "completed",
    "attendances": [
      {
        "student_id": 5,
        "student_name": "김학생",
        "avatar_url": null,
        "status": "present",
        "note": null,
        "recorded_at": "2026-05-28T10:05:00Z"
      },
      {
        "student_id": 6,
        "student_name": "이학생",
        "avatar_url": null,
        "status": "absent",
        "note": "결석 사유: 병결",
        "recorded_at": "2026-05-28T10:10:00Z"
      }
    ],
    "stats": {
      "total": 2,
      "present": 1,
      "absent": 1,
      "late": 0,
      "excused": 0
    }
  }
}
```

---

### 3-4. 출석 배치 처리

```
POST /lessons/:groupId/schedules/:scheduleId/attendance   🔐
권한: group admin / sub_admin / instructor
```

**Request**
```json
{
  "attendances": [
    { "student_id": 5, "status": "present",  "note": null },
    { "student_id": 6, "status": "absent",   "note": "병결" },
    { "student_id": 7, "status": "late",     "note": "10분 지각" }
  ]
}
```

> `status` 허용값: `present` | `absent` | `late` | `excused`  
> 배치 처리: 기존 출석 데이터 전체 교체 (upsert)

**Response 200**
```json
{
  "success": true,
  "data": {
    "schedule_id": 1,
    "processed": 3
  },
  "message": "출석이 처리되었습니다."
}
```

---

### 3-5. 학생 목록 + 보호자 정보 + 출석률

```
GET /lessons/:groupId/students   🔐
권한: group admin / sub_admin / instructor
```

**Response 200**
```json
{
  "success": true,
  "data": [
    {
      "student_id": 5,
      "student_name": "김학생",
      "student_email": "student@meti.io",
      "avatar_url": null,
      "attendance_rate": 85.5,
      "total_schedules": 10,
      "attended": 8,
      "guardians": [
        {
          "guardian_id": 4,
          "guardian_name": "박부모",
          "relation": "parent",
          "guardian_email": "parent@meti.io"
        }
      ]
    }
  ]
}
```

---

## 5. 채팅 (Chat) — v3.0 변경사항

### 4-1. 채팅 메시지 보관 정책

| 플랜 | 메시지 보관 기간 |
|------|--------------|
| `free` | **1일** |
| `pro` | **90일** |
| `business` | **무제한** |

> 보관 기간 초과 메시지는 자동 삭제됩니다.  
> 앱에서 "메시지 보관 기간이 만료되었습니다" 안내 표시 권장.

---

### 4-2. 채팅방 파일 업로드 — 신규 🆕

```
POST /chat/rooms/:roomId/upload   🔐
Content-Type: multipart/form-data
```

| 파일 유형 | 필드명 | 최대 크기 | 허용 형식 |
|---------|-------|---------|---------|
| 이미지 | `image` | 5MB | JPG, PNG, WEBP, GIF |
| 파일 | `file` | 20MB | 모든 형식 |

**Request**: `image` 또는 `file` 중 하나 전송

**Response 200**
```json
{
  "success": true,
  "data": {
    "url": "https://pub-9e92c640989d47f69f8e3f749c4de9c0.r2.dev/chat/room_1_1716000000000.jpg",
    "file_type": "image",
    "file_name": "photo.jpg",
    "file_size": 204800
  }
}
```

**R2 키 패턴**:
- 이미지: `chat/room_{roomId}_{timestamp}.{ext}`
- 파일: `chat/files/room_{roomId}_{timestamp}_{originalName}`

**에러**
- `400`: 파일 없음 | 허용 형식 초과 | 크기 초과
- `403`: 채팅방 접근 권한 없음

> ⚠️ **Flutter web preview**: `http.MultipartFile.fromPath()` 대신  
> `http.MultipartFile.fromBytes()` 사용 권장 (web 호환성)

---

## 6. 파트너 서비스 (Partner Services) — 스키마 추가

`partner_services` 테이블에 `webview_url` 컬럼 추가 (migration 0020).

**GET /partner-services 응답 스키마 추가**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "파트너 서비스명",
      "description": "설명",
      "logo_url": "https://...",
      "webview_url": "https://partner.example.com/app",   // ← v3.0 신규
      "is_active": 1
    }
  ]
}
```

> `webview_url`이 있는 파트너 서비스는 앱 내 WebView로 인앱 표시.  
> `webview_url`이 null이면 기존 방식(외부 브라우저 또는 링크 이동)으로 처리.

---

## 7. 앱 화면 구성 — v3.0 신규/변경

### 6-A. 보호자 관리 화면 (`/guardians`)

#### 학생 입장

```
[ 보호자 목록 ]
─────────────────────
● 활성 보호자
  [박부모]  parent  연결됨
  [김강사]  teacher 연결됨  [해제]

● 대기 중인 요청
  [이선생]  teacher "연결 수락 요청"  [수락] [거절]
─────────────────────
```

#### 보호자/강사 입장

```
[ 내 학생 목록 ]
─────────────────────
  [김학생]  MINOR  출석률 85%
  [이학생]  MINOR  출석률 70%  [레슨 그룹 보기]
─────────────────────
[+ 학생 추가 (이메일/ID 입력)]
```

**API 연결**

| 화면 | API |
|------|-----|
| 보호자 목록 (학생) | `GET /guardians?role=mine` |
| 학생 목록 (보호자) | `GET /guardians?role=students` |
| 대기 요청 목록 | `GET /guardians/pending` |
| 수락 | `POST /guardians/link/:id/accept` |
| 거절 | `POST /guardians/link/:id/reject` |
| 연결 요청 | `POST /guardians/link` |
| 해제 | `DELETE /guardians/:guardianUserId` |

---

### 6-B. 레슨 일정/출석 화면

```
[ 레슨 일정 목록 ]             ← GET /lessons/:groupId/schedules
─────────────────────
  [2026-05-28] 피아노 수업  출석 5/5  ✅ completed
  [2026-06-04] 피아노 수업  출석 -/-  📅 scheduled  [출석 처리]
─────────────────────

[ 일정 상세 ]                  ← GET /lessons/:groupId/schedules/:id
─────────────────────
  제목, 날짜/시간, 장소
  ─── 출석 현황 ───
  [김학생]  ● 출석
  [이학생]  ✗ 결석  병결
  [박학생]  △ 지각  10분
  ─── 통계 ───
  출석 1 / 결석 1 / 지각 1

[ 출석 처리 시트 ]             ← POST /lessons/:groupId/schedules/:id/attendance
  각 학생: [출석 ▼] 메모 입력
  [저장]
```

**API 연결**

| 화면 | API |
|------|-----|
| 일정 목록 | `GET /lessons/:groupId/schedules` |
| 일정 생성 | `POST /lessons/:groupId/schedules` |
| 일정 상세 + 출석 현황 | `GET /lessons/:groupId/schedules/:id` |
| 출석 처리 | `POST /lessons/:groupId/schedules/:id/attendance` |
| 학생 + 출석률 | `GET /lessons/:groupId/students` |

---

### 6-C. 채팅방 파일 업로드

```
[ 채팅 입력창 ]
  [📎]  →  선택: [이미지] [파일]
         →  선택 후 즉시 POST /chat/rooms/:roomId/upload
         →  반환된 URL을 메시지로 전송 (또는 메시지 body에 포함)
```

---

## 8. Mock API 업데이트 사항 (v3.0)

v3.0 신규 API를 Mock 환경에서 지원하기 위해 다음 파일을 수정/추가해야 합니다.

### 8-A. `mock_data.dart` — Guardian/Schedule 상태 추가

기존 `MockStore` 클래스 끝 (`pointChargeProducts` 아래)에 추가:

```dart
// ── 보호자 연결 (Guardian) ────────────────────────────────────
// guardianLinks: user_guardians 테이블 Mock
// - user_id (학생) ↔ guardian_user_id (보호자/강사)
static final List<Map<String, dynamic>> guardianLinks = [
  {
    'id': 1,
    'user_id': 1,              // 학생: test@meti.dev (id=1)
    'guardian_user_id': 2,     // 보호자: mock user id=2
    'relation': 'parent',
    'status': 'pending',       // 수락 대기 중
    'invited_at': '2026-05-28T09:00:00Z',
    'accepted_at': null,
  },
];
static int guardianLinkIdSeq = 10;

// ── 레슨 일정 (Schedule) ─────────────────────────────────────
// schedules: lesson_schedules 테이블 Mock (groupId → List<Schedule>)
static final Map<int, List<Map<String, dynamic>>> lessonSchedules = {
  1: [
    {
      'id': 1,
      'group_id': 1,
      'instructor_id': 1,
      'instructor_name': '홍길동',
      'title': '5월 4주차 수영 수업',
      'description': '자유형 집중 훈련',
      'scheduled_at': '2026-05-28T10:00:00Z',
      'duration_minutes': 60,
      'location': '실내수영장 A레인',
      'capacity': 5,
      'status': 'completed',
      'attendance_count': 2,
      'created_at': '2026-05-25T09:00:00Z',
    },
    {
      'id': 2,
      'group_id': 1,
      'instructor_id': 1,
      'instructor_name': '홍길동',
      'title': '6월 1주차 수영 수업',
      'description': null,
      'scheduled_at': '2026-06-04T10:00:00Z',
      'duration_minutes': 60,
      'location': '실내수영장 A레인',
      'capacity': 5,
      'status': 'scheduled',
      'attendance_count': 0,
      'created_at': '2026-05-30T09:00:00Z',
    },
  ],
};
static int scheduleIdSeq = 10;

// ── 출석 (Attendance) ─────────────────────────────────────────
// attendances: lesson_attendances 테이블 Mock (scheduleId → List<Attendance>)
static final Map<int, List<Map<String, dynamic>>> lessonAttendances = {
  1: [
    {
      'student_id': 1,
      'student_name': '홍길동',
      'avatar_url': null,
      'status': 'present',
      'note': null,
      'recorded_at': '2026-05-28T10:05:00Z',
    },
    {
      'student_id': 3,
      'student_name': '이영희',
      'avatar_url': null,
      'status': 'absent',
      'note': '병결',
      'recorded_at': '2026-05-28T10:10:00Z',
    },
  ],
};
```

---

### 8-B. 신규 파일: `lib/core/api/mock/mock_guardians.dart`

```dart
// mock_guardians.dart — Guardian(보호자) API Mock 구현
import 'mock_data.dart';

class MockGuardians {
  MockGuardians._();

  // 토큰에서 userId 추출 헬퍼
  static int _getUserId(String accessToken) {
    // 토큰 형식: 'mock-access-{userId}-{timestamp}'
    final parts = accessToken.split('-');
    if (parts.length >= 3) return int.tryParse(parts[2]) ?? 1;
    return 1;
  }

  // ── 2-1. 보호자 연결 요청 POST /guardians/link ────────────────
  static Map<String, dynamic> linkGuardian(
    String accessToken,
    Map<String, dynamic> body,
  ) {
    final guardianUserId = _getUserId(accessToken);
    final minorUserId = body['minor_user_id'] as int?;
    final minorEmail  = body['minor_email']  as String?;
    final relation    = body['relation']     as String? ?? 'parent';

    if (minorUserId == null && minorEmail == null) {
      throw MockApiException('minor_user_id 또는 minor_email 중 하나가 필요합니다.', 400);
    }

    // 대상 학생 찾기
    Map<String, dynamic>? student;
    if (minorUserId != null) {
      final matches = MockStore.users.where((u) => u['id'] == minorUserId).toList();
      if (matches.isEmpty) throw MockApiException('학생을 찾을 수 없습니다.', 404);
      student = matches.first;
    } else {
      final matches = MockStore.users.where((u) => u['email'] == minorEmail).toList();
      if (matches.isEmpty) throw MockApiException('학생을 찾을 수 없습니다.', 404);
      student = matches.first;
    }

    if (student['id'] == guardianUserId) {
      throw MockApiException('자기 자신에게 연결 요청을 보낼 수 없습니다.', 400);
    }

    // 기존 요청 확인 (active 또는 pending → 409)
    final existing = MockStore.guardianLinks.where((g) =>
      g['user_id'] == student!['id'] &&
      g['guardian_user_id'] == guardianUserId &&
      (g['status'] == 'active' || g['status'] == 'pending'),
    ).toList();
    if (existing.isNotEmpty) {
      throw MockApiException('이미 연결 요청이 존재합니다.', 409);
    }

    // rejected 상태면 갱신, 없으면 신규 생성
    final rejectedIdx = MockStore.guardianLinks.indexWhere((g) =>
      g['user_id'] == student!['id'] &&
      g['guardian_user_id'] == guardianUserId &&
      g['status'] == 'rejected',
    );

    final id = rejectedIdx >= 0
        ? MockStore.guardianLinks[rejectedIdx]['id'] as int
        : ++MockStore.guardianLinkIdSeq;

    final link = {
      'id': id,
      'user_id': student['id'],
      'guardian_user_id': guardianUserId,
      'relation': relation,
      'status': 'pending',
      'invited_at': DateTime.now().toIso8601String(),
      'accepted_at': null,
    };

    if (rejectedIdx >= 0) {
      MockStore.guardianLinks[rejectedIdx] = link;
    } else {
      MockStore.guardianLinks.add(link);
    }

    return {
      'success': true,
      'data': {
        'id': id,
        'minor_user_id': student['id'],
        'guardian_user_id': guardianUserId,
        'relation': relation,
        'status': 'pending',
      },
      'message': '보호자 연결 요청이 발송되었습니다.',
    };
  }

  // ── 2-2. 보호자 연결 수락 POST /guardians/link/:id/accept ─────
  static Map<String, dynamic> acceptLink(String accessToken, int requestId) {
    final userId = _getUserId(accessToken);
    final idx = MockStore.guardianLinks.indexWhere((g) => g['id'] == requestId);
    if (idx < 0) throw MockApiException('요청을 찾을 수 없습니다.', 404);

    final link = MockStore.guardianLinks[idx];
    if (link['status'] != 'pending') {
      throw MockApiException('이미 처리된 요청입니다.', 400);
    }
    // 학생 본인만 수락 가능
    if (link['user_id'] != userId) {
      throw MockApiException('수락 권한이 없습니다.', 403);
    }

    MockStore.guardianLinks[idx] = Map<String, dynamic>.from(link)
      ..['status'] = 'active'
      ..['accepted_at'] = DateTime.now().toIso8601String();

    return {
      'success': true,
      'data': {
        'request_id': requestId,
        'minor_user_id': link['user_id'],
        'guardian_user_id': link['guardian_user_id'],
        'relation': link['relation'],
        'status': 'active',
      },
      'message': '보호자 연결이 수락되었습니다.',
    };
  }

  // ── 2-3. 보호자 연결 거절 POST /guardians/link/:id/reject ─────
  static Map<String, dynamic> rejectLink(String accessToken, int requestId) {
    final userId = _getUserId(accessToken);
    final idx = MockStore.guardianLinks.indexWhere((g) => g['id'] == requestId);
    if (idx < 0) throw MockApiException('요청을 찾을 수 없습니다.', 404);

    final link = MockStore.guardianLinks[idx];
    if (link['status'] != 'pending') {
      throw MockApiException('이미 처리된 요청입니다.', 400);
    }
    if (link['user_id'] != userId) {
      throw MockApiException('거절 권한이 없습니다.', 403);
    }

    MockStore.guardianLinks[idx] = Map<String, dynamic>.from(link)
      ..['status'] = 'rejected';

    return {
      'success': true,
      'data': {'request_id': requestId, 'status': 'rejected'},
      'message': '보호자 연결 요청이 거절되었습니다.',
    };
  }

  // ── 2-4. 보호자/학생 목록 GET /guardians?role= ────────────────
  static Map<String, dynamic> getGuardians(String accessToken, String role) {
    final userId = _getUserId(accessToken);

    if (role == 'students') {
      // 보호자 입장: 내가 담당하는 학생 목록 (active only)
      final myStudentLinks = MockStore.guardianLinks.where((g) =>
        g['guardian_user_id'] == userId && g['status'] == 'active',
      ).toList();

      final data = myStudentLinks.map((g) {
        final student = MockStore.users.firstWhere(
          (u) => u['id'] == g['user_id'],
          orElse: () => {'id': g['user_id'], 'name': '알 수 없음', 'email': ''},
        );
        return {
          'id': g['id'],
          'relation': g['relation'],
          'status': g['status'],
          'accepted_at': g['accepted_at'],
          'student_id': student['id'],
          'student_name': student['name'],
          'student_email': student['email'],
          'user_type': 'MINOR',
          'birth_date': null,
          'avatar_url': student['avatar_url'],
        };
      }).toList();

      return {'success': true, 'data': data};
    } else {
      // 학생 입장: 내 보호자 목록 (active only)
      final myGuardianLinks = MockStore.guardianLinks.where((g) =>
        g['user_id'] == userId && g['status'] == 'active',
      ).toList();

      final data = myGuardianLinks.map((g) {
        final guardian = MockStore.users.firstWhere(
          (u) => u['id'] == g['guardian_user_id'],
          orElse: () => {'id': g['guardian_user_id'], 'name': '알 수 없음', 'email': ''},
        );
        return {
          'id': g['id'],
          'relation': g['relation'],
          'status': g['status'],
          'accepted_at': g['accepted_at'],
          'guardian_id': guardian['id'],
          'guardian_name': guardian['name'],
          'guardian_email': guardian['email'],
          'guardian_avatar': guardian['avatar_url'],
        };
      }).toList();

      return {'success': true, 'data': data};
    }
  }

  // ── 2-5. 대기 중인 연결 요청 GET /guardians/pending ──────────
  static Map<String, dynamic> getPendingLinks(String accessToken) {
    final userId = _getUserId(accessToken);

    // 학생 입장: 수락/거절해야 할 pending 요청 목록
    final pendingLinks = MockStore.guardianLinks.where((g) =>
      g['user_id'] == userId && g['status'] == 'pending',
    ).toList();

    final data = pendingLinks.map((g) {
      final guardian = MockStore.users.firstWhere(
        (u) => u['id'] == g['guardian_user_id'],
        orElse: () => {'id': g['guardian_user_id'], 'name': '알 수 없음', 'email': ''},
      );
      return {
        'request_id': g['id'],
        'relation': g['relation'],
        'status': g['status'],
        'invited_at': g['invited_at'],
        'guardian_id': guardian['id'],
        'guardian_name': guardian['name'],
        'guardian_email': guardian['email'],
        'guardian_avatar': guardian['avatar_url'],
      };
    }).toList();

    return {'success': true, 'data': data};
  }

  // ── 2-6. 보호자 연결 해제 DELETE /guardians/:guardianUserId ───
  static Map<String, dynamic> removeGuardian(
    String accessToken,
    int guardianUserId,
  ) {
    final userId = _getUserId(accessToken);

    // 학생→보호자 또는 보호자→학생 양방향 해제
    final idx = MockStore.guardianLinks.indexWhere((g) =>
      (g['user_id'] == userId && g['guardian_user_id'] == guardianUserId) ||
      (g['user_id'] == guardianUserId && g['guardian_user_id'] == userId),
    );

    if (idx < 0) throw MockApiException('연결된 보호자를 찾을 수 없습니다.', 404);
    MockStore.guardianLinks.removeAt(idx);

    return {
      'success': true,
      'data': null,
      'message': '보호자 연결이 해제되었습니다.',
    };
  }

  // ── 2-7. 내 학생들의 레슨 그룹 목록 GET /guardians/lesson-groups
  static Map<String, dynamic> getLessonGroups(String accessToken) {
    // Mock: 그룹 1(LESSON 타입)을 보호자가 접근 가능한 것으로 처리
    return {
      'success': true,
      'data': [
        {
          'group_id': 1,
          'group_name': 'METI 개발자 모임',
          'group_type': 'LESSON',
          'description': '레슨 그룹 예시',
          'student_count': 2,
        },
      ],
    };
  }
}
```

---

### 8-C. 신규 파일: `lib/core/api/mock/mock_schedules.dart`

```dart
// mock_schedules.dart — Lesson Schedule/Attendance API Mock 구현
import 'mock_data.dart';

class MockSchedules {
  MockSchedules._();

  static int _getUserId(String accessToken) {
    final parts = accessToken.split('-');
    if (parts.length >= 3) return int.tryParse(parts[2]) ?? 1;
    return 1;
  }

  // ── 3-1. 레슨 일정 목록 GET /lessons/:groupId/schedules ──────
  static Map<String, dynamic> getSchedules(
    String accessToken,
    int groupId, {
    String? status,
    int page = 1,
    int limit = 20,
  }) {
    final all = List<Map<String, dynamic>>.from(
      MockStore.lessonSchedules[groupId] ?? [],
    );

    final filtered = status != null
        ? all.where((s) => s['status'] == status).toList()
        : all;

    final start = (page - 1) * limit;
    final end   = (start + limit).clamp(0, filtered.length);
    final paged = filtered.sublist(
      start.clamp(0, filtered.length),
      end,
    );

    return {
      'success': true,
      'data': paged,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': filtered.length,
        'has_next': end < filtered.length,
      },
    };
  }

  // ── 3-2. 레슨 일정 생성 POST /lessons/:groupId/schedules ─────
  static Map<String, dynamic> createSchedule(
    String accessToken,
    int groupId,
    Map<String, dynamic> body,
  ) {
    final instructorId = _getUserId(accessToken);
    final instructor   = MockStore.users.firstWhere(
      (u) => u['id'] == instructorId,
      orElse: () => {'name': '알 수 없음'},
    );

    final id       = ++MockStore.scheduleIdSeq;
    final schedule = {
      'id': id,
      'group_id': groupId,
      'instructor_id': instructorId,
      'instructor_name': instructor['name'],
      'title': body['title'] ?? '새 레슨',
      'description': body['description'],
      'scheduled_at': body['scheduled_at'],
      'duration_minutes': body['duration_minutes'] ?? 60,
      'location': body['location'],
      'capacity': body['capacity'],
      'status': 'scheduled',
      'attendance_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    MockStore.lessonSchedules.putIfAbsent(groupId, () => []).add(schedule);

    return {
      'success': true,
      'data': schedule,
      'message': '레슨 일정이 생성되었습니다.',
    };
  }

  // ── 3-3. 레슨 일정 상세 + 출석 현황 ──────────────────────────
  static Map<String, dynamic> getScheduleDetail(
    String accessToken,
    int groupId,
    int scheduleId,
  ) {
    final schedules = MockStore.lessonSchedules[groupId] ?? [];
    final schedule  = schedules.firstWhere(
      (s) => s['id'] == scheduleId,
      orElse: () => throw MockApiException('일정을 찾을 수 없습니다.', 404),
    );

    final attendances = List<Map<String, dynamic>>.from(
      MockStore.lessonAttendances[scheduleId] ?? [],
    );

    final stats = {
      'total':   attendances.length,
      'present': attendances.where((a) => a['status'] == 'present').length,
      'absent':  attendances.where((a) => a['status'] == 'absent').length,
      'late':    attendances.where((a) => a['status'] == 'late').length,
      'excused': attendances.where((a) => a['status'] == 'excused').length,
    };

    return {
      'success': true,
      'data': {
        ...schedule,
        'attendances': attendances,
        'stats': stats,
      },
    };
  }

  // ── 3-4. 출석 배치 처리 POST /schedules/:id/attendance ────────
  static Map<String, dynamic> processAttendance(
    String accessToken,
    int groupId,
    int scheduleId,
    Map<String, dynamic> body,
  ) {
    final attendanceList =
        (body['attendances'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    // 기존 출석 전체 교체 (upsert)
    final now = DateTime.now().toIso8601String();
    final records = attendanceList.map((a) {
      final studentId = a['student_id'] as int;
      final student   = MockStore.users.firstWhere(
        (u) => u['id'] == studentId,
        orElse: () => {'id': studentId, 'name': '알 수 없음', 'avatar_url': null},
      );
      return {
        'student_id': studentId,
        'student_name': student['name'],
        'avatar_url': student['avatar_url'],
        'status': a['status'] ?? 'present',
        'note': a['note'],
        'recorded_at': now,
      };
    }).toList();

    MockStore.lessonAttendances[scheduleId] = records;

    // schedule의 attendance_count 업데이트
    final groupSchedules = MockStore.lessonSchedules[groupId] ?? [];
    final idx = groupSchedules.indexWhere((s) => s['id'] == scheduleId);
    if (idx >= 0) {
      groupSchedules[idx] = Map<String, dynamic>.from(groupSchedules[idx])
        ..['attendance_count'] = records.length
        ..['status'] = 'completed';
    }

    return {
      'success': true,
      'data': {
        'schedule_id': scheduleId,
        'processed': records.length,
      },
      'message': '출석이 처리되었습니다.',
    };
  }

  // ── 3-5. 학생 목록 + 보호자 정보 + 출석률 ───────────────────
  static Map<String, dynamic> getLessonStudents(
    String accessToken,
    int groupId,
  ) {
    // Mock: 그룹 멤버 중 일부를 학생으로 처리
    final mockStudents = MockStore.users.take(2).toList();
    final totalSchedules = (MockStore.lessonSchedules[groupId] ?? []).length;

    final data = mockStudents.map((student) {
      final attended = MockStore.lessonAttendances.values
          .expand((a) => a)
          .where((a) =>
            a['student_id'] == student['id'] &&
            a['status'] == 'present')
          .length;

      final rate = totalSchedules > 0
          ? (attended / totalSchedules * 100).roundToDouble()
          : 0.0;

      // 해당 학생의 보호자 목록
      final guardians = MockStore.guardianLinks
          .where((g) =>
            g['user_id'] == student['id'] &&
            g['status'] == 'active')
          .map((g) {
            final guardian = MockStore.users.firstWhere(
              (u) => u['id'] == g['guardian_user_id'],
              orElse: () => {'id': g['guardian_user_id'], 'name': '알 수 없음', 'email': ''},
            );
            return {
              'guardian_id':    guardian['id'],
              'guardian_name':  guardian['name'],
              'relation':       g['relation'],
              'guardian_email': guardian['email'],
            };
          }).toList();

      return {
        'student_id': student['id'],
        'student_name': student['name'],
        'student_email': student['email'],
        'avatar_url': student['avatar_url'],
        'attendance_rate': rate,
        'total_schedules': totalSchedules,
        'attended': attended,
        'guardians': guardians,
      };
    }).toList();

    return {'success': true, 'data': data};
  }
}
```

---

### 8-D. `mock_auth.dart` 보안 패치 (실서버 호환)

```diff
// lib/core/api/mock/mock_auth.dart — register() 응답 수정
return {
  'success': true,
  'data': {
    'user_id': userId,
    'email': email,
-   'verify_token': verifyToken,   // ← 제거 (보안 패치 v3.0)
  },
  'message': '회원가입이 완료되었습니다. 이메일을 확인해주세요.',
};
```

> 💡 `MockStore.verifyTokens[verifyToken] = email` 라인은 **유지**합니다.  
> 응답에서만 제거하면 됩니다. `verifyEmail()` Mock 호출은 그대로 동작합니다.

---

### 8-E. `api_client.dart` Guardian/Schedule 라우팅 추가

`_mockDispatch()` 내부에 추가 (기존 POST/GET/DELETE 블록 안에 삽입):

```dart
// ── POST 라우팅 (기존 블록 안에 추가) ──

// v3.0: 보호자 연결 요청
if (path == '/guardians/link') {
  return MockUsers.linkGuardian(accessToken!, body ?? {});
}
// v3.0: 보호자 연결 수락
if (path.startsWith('/guardians/link/') && path.endsWith('/accept')) {
  final parts = path.split('/');
  final requestId = int.tryParse(parts.length >= 4 ? parts[3] : '0') ?? 0;
  return MockUsers.acceptLink(accessToken!, requestId);
}
// v3.0: 보호자 연결 거절
if (path.startsWith('/guardians/link/') && path.endsWith('/reject')) {
  final parts = path.split('/');
  final requestId = int.tryParse(parts.length >= 4 ? parts[3] : '0') ?? 0;
  return MockUsers.rejectLink(accessToken!, requestId);
}
// v3.0: 레슨 일정 생성 POST /lessons/:groupId/schedules
if (path.startsWith('/lessons/') && path.endsWith('/schedules')) {
  final parts = path.split('/');
  final groupId = int.tryParse(parts.length >= 3 ? parts[2] : '0') ?? 0;
  return MockUsers.createSchedule(accessToken!, groupId, body ?? {});
}
// v3.0: 출석 배치 처리 POST /lessons/:groupId/schedules/:scheduleId/attendance
if (path.startsWith('/lessons/') && path.endsWith('/attendance')) {
  final parts = path.split('/');
  // 경로: /lessons/{groupId}/schedules/{scheduleId}/attendance
  final groupId    = int.tryParse(parts.length >= 3 ? parts[2] : '0') ?? 0;
  final scheduleId = int.tryParse(parts.length >= 5 ? parts[4] : '0') ?? 0;
  return MockUsers.processAttendance(accessToken!, groupId, scheduleId, body ?? {});
}
// v3.0: 채팅 파일 업로드 POST /chat/rooms/:roomId/upload
if (path.startsWith('/chat/rooms/') && path.endsWith('/upload')) {
  final parts = path.split('/');
  final roomId = int.tryParse(parts.length >= 4 ? parts[3] : '0') ?? 0;
  return {
    'success': true,
    'data': {
      'url': 'https://pub-9e92c640989d47f69f8e3f749c4de9c0.r2.dev/chat/room_${roomId}_mock.jpg',
      'file_type': 'image',
      'file_name': 'mock_upload.jpg',
      'file_size': 102400,
    },
  };
}

// ── GET 라우팅 (기존 블록 안에 추가) ──

// v3.0: 보호자/학생 목록 GET /guardians?role=mine|students
if (path == '/guardians') {
  final role = queryParams?['role'] as String? ?? 'mine';
  return MockUsers.getGuardians(accessToken!, role);
}
// v3.0: 대기 중인 연결 요청 GET /guardians/pending
if (path == '/guardians/pending') {
  return MockUsers.getPendingLinks(accessToken!);
}
// v3.0: 내 학생 레슨 그룹 GET /guardians/lesson-groups
if (path == '/guardians/lesson-groups') {
  return MockUsers.getLessonGroups(accessToken!);
}
// v3.0: 레슨 일정 목록 GET /lessons/:groupId/schedules
if (path.startsWith('/lessons/') && path.endsWith('/schedules')) {
  final parts   = path.split('/');
  final groupId = int.tryParse(parts.length >= 3 ? parts[2] : '0') ?? 0;
  final status  = queryParams?['status'] as String?;
  final page    = int.tryParse(queryParams?['page']?.toString() ?? '1') ?? 1;
  final limit   = int.tryParse(queryParams?['limit']?.toString() ?? '20') ?? 20;
  return MockUsers.getSchedules(accessToken!, groupId, status: status, page: page, limit: limit);
}
// v3.0: 레슨 일정 상세 GET /lessons/:groupId/schedules/:scheduleId
if (path.startsWith('/lessons/') && path.contains('/schedules/')) {
  final parts      = path.split('/');
  final groupId    = int.tryParse(parts.length >= 3 ? parts[2] : '0') ?? 0;
  final scheduleId = int.tryParse(parts.length >= 5 ? parts[4] : '0') ?? 0;
  return MockUsers.getScheduleDetail(accessToken!, groupId, scheduleId);
}
// v3.0: 학생 + 출석률 GET /lessons/:groupId/students
if (path.startsWith('/lessons/') && path.endsWith('/students')) {
  final parts   = path.split('/');
  final groupId = int.tryParse(parts.length >= 3 ? parts[2] : '0') ?? 0;
  return MockUsers.getLessonStudents(accessToken!, groupId);
}
// v3.0: 파트너 서비스 (webview_url 포함)
if (path == '/partner-services') {
  return {
    'success': true,
    'data': [
      {
        'id': 1,
        'name': '파트너 서비스 예시',
        'description': '파트너 서비스 설명',
        'logo_url': null,
        'webview_url': 'https://partner.example.com/app',
        'is_active': 1,
      },
    ],
  };
}

// ── DELETE 라우팅 (기존 블록 안에 추가) ──

// v3.0: 보호자 연결 해제 DELETE /guardians/:guardianUserId
if (path.startsWith('/guardians/') &&
    !path.endsWith('/link') &&
    !path.contains('/accept') &&
    !path.contains('/reject')) {
  final parts          = path.split('/');
  final guardianUserId = int.tryParse(parts.length >= 3 ? parts[2] : '0') ?? 0;
  return MockUsers.removeGuardian(accessToken!, guardianUserId);
}
```

---

### 8-F. `mock_api.dart` MockUsers 어댑터 추가

`MockUsers` 클래스 끝 (`verifyPaymentToken` 아래)에 추가:

```dart
// ── Guardian 위임 (v3.0 신규) ─────────────────────────────────
static Map<String, dynamic> linkGuardian(
        String accessToken, Map<String, dynamic> body) =>
    MockGuardians.linkGuardian(accessToken, body);

static Map<String, dynamic> acceptLink(String accessToken, int requestId) =>
    MockGuardians.acceptLink(accessToken, requestId);

static Map<String, dynamic> rejectLink(String accessToken, int requestId) =>
    MockGuardians.rejectLink(accessToken, requestId);

static Map<String, dynamic> getGuardians(String accessToken, String role) =>
    MockGuardians.getGuardians(accessToken, role);

static Map<String, dynamic> getPendingLinks(String accessToken) =>
    MockGuardians.getPendingLinks(accessToken);

static Map<String, dynamic> removeGuardian(
        String accessToken, int guardianUserId) =>
    MockGuardians.removeGuardian(accessToken, guardianUserId);

static Map<String, dynamic> getLessonGroups(String accessToken) =>
    MockGuardians.getLessonGroups(accessToken);

// ── Schedule 위임 (v3.0 신규) ────────────────────────────────
static Map<String, dynamic> getSchedules(
        String accessToken, int groupId,
        {String? status, int page = 1, int limit = 20}) =>
    MockSchedules.getSchedules(accessToken, groupId,
        status: status, page: page, limit: limit);

static Map<String, dynamic> createSchedule(
        String accessToken, int groupId, Map<String, dynamic> body) =>
    MockSchedules.createSchedule(accessToken, groupId, body);

static Map<String, dynamic> getScheduleDetail(
        String accessToken, int groupId, int scheduleId) =>
    MockSchedules.getScheduleDetail(accessToken, groupId, scheduleId);

static Map<String, dynamic> processAttendance(
        String accessToken, int groupId, int scheduleId,
        Map<String, dynamic> body) =>
    MockSchedules.processAttendance(accessToken, groupId, scheduleId, body);

static Map<String, dynamic> getLessonStudents(
        String accessToken, int groupId) =>
    MockSchedules.getLessonStudents(accessToken, groupId);
```

또한 `mock_api.dart` 상단 import/export에 추가:

```dart
export 'mock/mock_guardians.dart';  // MockGuardians (v3.0)
export 'mock/mock_schedules.dart';  // MockSchedules (v3.0)

import 'mock/mock_guardians.dart';
import 'mock/mock_schedules.dart';
```

---

## 9. 앱 화면-API 연결 표 (v3.0 추가분)

v2.9 표에 추가된 항목만 기재합니다.

| 화면 | 연결 API | 비고 |
|------|---------|------|
| 보호자 목록 (학생) | `GET /guardians?role=mine` | |
| 학생 목록 (보호자) | `GET /guardians?role=students` | |
| 대기 보호자 요청 | `GET /guardians/pending` | 로그인 시 자동 확인 |
| 보호자 연결 요청 | `POST /guardians/link` | minor_user_id 또는 minor_email |
| 연결 수락 | `POST /guardians/link/:id/accept` | |
| 연결 거절 | `POST /guardians/link/:id/reject` | |
| 보호자 해제 | `DELETE /guardians/:guardianUserId` | |
| 내 학생 레슨그룹 | `GET /guardians/lesson-groups` | 보호자 입장 |
| 레슨 일정 목록 | `GET /lessons/:groupId/schedules` | |
| 레슨 일정 생성 | `POST /lessons/:groupId/schedules` | 강사급 권한 |
| 레슨 일정 상세 | `GET /lessons/:groupId/schedules/:id` | 출석 현황 포함 |
| 출석 처리 | `POST /lessons/:groupId/schedules/:id/attendance` | 배치 처리 |
| 학생 + 출석률 | `GET /lessons/:groupId/students` | 보호자 정보 포함 |
| 채팅 파일 업로드 | `POST /chat/rooms/:roomId/upload` | image(5MB)/file(20MB) |
| 파트너 서비스 목록 | `GET /partner-services` | webview_url 추가 |

---

## 10. 백엔드 현황 (v3.0 기준)

| 항목 | v2.9 상태 | v3.0 상태 |
|------|----------|----------|
| 보호자 연결 요청 (`POST /guardians/link`) | ⏳ 미구현 | ✅ 완료 |
| 보호자 수락/거절 | ⏳ 미구현 | ✅ 완료 |
| 보호자/학생 목록 (`GET /guardians`) | ⏳ 미구현 | ✅ 완료 |
| 대기 요청 목록 (`GET /guardians/pending`) | ⏳ 미구현 | ✅ 완료 |
| 보호자 해제 (`DELETE /guardians/:id`) | ⏳ 미구현 | ✅ 완료 |
| 학생 레슨 그룹 (`GET /guardians/lesson-groups`) | ⏳ 미구현 | ✅ 완료 |
| 레슨 일정 목록/생성 (`/lessons/:id/schedules`) | ⏳ 미구현 | ✅ 완료 |
| 레슨 일정 상세 + 출석 현황 | ⏳ 미구현 | ✅ 완료 |
| 출석 배치 처리 (`/schedules/:id/attendance`) | ⏳ 미구현 | ✅ 완료 |
| 학생 목록 + 출석률 (`/lessons/:id/students`) | ⏳ 미구현 | ✅ 완료 |
| 채팅 메시지 보관 정책 | ⏳ 미구현 | ✅ 완료 |
| 채팅 파일 업로드 (`/chat/rooms/:id/upload`) | ⏳ 미구현 | ✅ 완료 |
| auth 보안 패치 (verify_token 제거) | ❌ 미적용 | ✅ 완료 |
| auth 보안 패치 (reset_token 제거) | ❌ 미적용 | ✅ 완료 |
| 파트너 WebView URL (`webview_url` 컬럼) | ❌ 없음 | ✅ 완료 |

---

## 11. 앱 개발 주의사항 (v3.0 추가분)

### ⚠️ 보호자 API — role 파라미터 필수

```dart
// 학생 입장: 내 보호자 목록
final response = await _api.get('/guardians', queryParams: {'role': 'mine'});

// 보호자 입장: 내 학생 목록
final response = await _api.get('/guardians', queryParams: {'role': 'students'});
```

---

### ⚠️ 출석 처리 — 배치 전송

출석은 partial update 없이 **전체 배치 전송**입니다.  
학생 목록 전체를 한 번에 `attendances[]` 배열로 전송하세요.

```dart
// ❌ 잘못된 방식: 학생 1명씩 개별 호출
for (final student in students) {
  await _api.post('/lessons/$groupId/schedules/$scheduleId/attendance',
    body: {'attendances': [student]});
}

// ✅ 올바른 방식: 전체 목록 한 번에 전송
await _api.post('/lessons/$groupId/schedules/$scheduleId/attendance',
  body: {
    'attendances': students.map((s) => {
      'student_id': s.id,
      'status': s.attendanceStatus,
      'note': s.note,
    }).toList()
  });
```

---

### ⚠️ auth 보안 패치 — 앱 verify_token 의존 제거

v1.7부터 회원가입 응답에 `verify_token`이 포함되지 않습니다.  
앱에서 `verify_token`을 활용하는 로직이 있다면 제거하세요.

```dart
// ❌ 기존 방식 (v1.6 이하)
final token = response['data']['verify_token'];
Navigator.pushNamed(context, AppRoutes.emailVerification,
  arguments: {'token': token});

// ✅ v3.0 방식
// verify_token 없이 "이메일을 확인하세요" 안내 화면으로 이동
Navigator.pushNamed(context, AppRoutes.emailVerification);
```

---

### ⚠️ 채팅 보관 정책 — UI 안내 표시

```dart
String _getRetentionLabel(String plan) {
  switch (plan) {
    case 'free':     return '메시지 보관 1일';
    case 'pro':      return '메시지 보관 90일';
    case 'business': return '메시지 무제한 보관';
    default:         return '';
  }
}
```

---

## 12. v3.0 구현 체크리스트

> 구현 코드 상세는 **섹션 8 (Mock API)** 및 **섹션 13 (Flutter 코드 스니펫)** 참조

### Phase 0: Mock 데이터 준비
- [ ] `mock_data.dart` — `guardianLinks[]`, `lessonSchedules{}`, `lessonAttendances{}` 추가 (섹션 8-A)
- [ ] `mock_guardians.dart` 신규 파일 생성 (7개 메서드 완전 구현, 섹션 8-B)
- [ ] `mock_schedules.dart` 신규 파일 생성 (5개 메서드 완전 구현, 섹션 8-C)
- [ ] `mock_auth.dart` — `register()` 응답에서 `verify_token` 제거 (섹션 8-D)
- [ ] `api_client.dart` — Guardian/Schedule/채팅업로드/파트너 라우팅 추가, forgot-password 패치 (섹션 8-E)
- [ ] `mock_api.dart` — export 2개 + MockUsers 어댑터 12개 추가 (섹션 8-F)

### Phase 1: 모델 / Provider
- [ ] `guardian_model.dart` — `GuardianModel` + `GuardianPendingModel` (섹션 13-A)
- [ ] `schedule_model.dart` — `ScheduleModel` + `ScheduleStats` (섹션 13-B)
- [ ] `attendance_model.dart` — `AttendanceModel` (섹션 13-B)
- [ ] `guardian_provider.dart` — 7개 API 연동 (섹션 13-C)
- [ ] `schedule_provider.dart` — 5개 API 연동 (섹션 13-D)
- [ ] `main.dart` / `app.dart` — `GuardianProvider`, `ScheduleProvider` MultiProvider 등록

### Phase 2: Guardian 화면
- [ ] `guardians_screen.dart` — 학생/보호자 역할에 따른 탭 구조
  - 학생 탭: 보호자 목록 + 대기 요청(수락/거절)
  - 보호자 탭: 학생 목록 + 출석률 + 레슨 그룹 이동
- [ ] 보호자 연결 요청 바텀시트 (이메일/ID 입력, `POST /guardians/link`)
- [ ] 연결 해제 확인 다이얼로그 (`DELETE /guardians/:guardianUserId`)
- [ ] `app_router.dart` — `/guardians` 라우트 추가 (섹션 13-E)

### Phase 3: 레슨 일정/출석 화면
- [ ] `lesson_schedules_screen.dart` — 일정 목록 (scheduled/completed 필터)
- [ ] `schedule_detail_screen.dart` — 일정 상세 + 출석 현황 + 통계
- [ ] `attendance_sheet.dart` — 출석 배치 처리 바텀시트 (드롭다운 + 메모)
- [ ] `lesson_students_screen.dart` — 학생 목록 + 출석률 + 보호자 정보
- [ ] `app_router.dart` — `/lesson-schedules`, `/schedule-detail` 라우트 추가

### Phase 4: 기존 화면 수정
- [ ] `register_screen.dart` — `verify_token` arguments 전달 제거 (섹션 1-C)
- [ ] `email_verification_screen.dart` — `_devToken` 관련 코드 전체 제거 (섹션 1-C)
- [ ] `chat_room_screen.dart` — 📎 파일 업로드 버튼 + `POST /chat/rooms/:roomId/upload` 연동
- [ ] `chat_list_screen.dart` — free 플랜 메시지 보관 1일 안내 배너
- [ ] 파트너 서비스 화면 — `webview_url` 있을 때 인앱 WebView로 표시

---

## 13. Flutter 코드 스니펫 (v3.0 신규 API)

### 13-A. GuardianModel

```dart
// lib/features/guardians/models/guardian_model.dart

class GuardianModel {
  final int id;
  final String relation;    // 'parent' | 'teacher'
  final String status;      // 'pending' | 'active' | 'rejected'
  final String? acceptedAt;
  final String? invitedAt;

  // role=students일 때 (보호자 입장)
  final int? studentId;
  final String? studentName;
  final String? studentEmail;
  final String? avatarUrl;

  // role=mine일 때 (학생 입장)
  final int? guardianId;
  final String? guardianName;
  final String? guardianEmail;
  final String? guardianAvatar;

  const GuardianModel({
    required this.id,
    required this.relation,
    required this.status,
    this.acceptedAt,
    this.invitedAt,
    this.studentId,
    this.studentName,
    this.studentEmail,
    this.avatarUrl,
    this.guardianId,
    this.guardianName,
    this.guardianEmail,
    this.guardianAvatar,
  });

  factory GuardianModel.fromJson(Map<String, dynamic> json) => GuardianModel(
    id:            json['id']            as int,
    relation:      json['relation']      as String,
    status:        json['status']        as String,
    acceptedAt:    json['accepted_at']   as String?,
    invitedAt:     json['invited_at']    as String?,
    studentId:     json['student_id']    as int?,
    studentName:   json['student_name']  as String?,
    studentEmail:  json['student_email'] as String?,
    avatarUrl:     json['avatar_url']    as String?,
    guardianId:    json['guardian_id']   as int?,
    guardianName:  json['guardian_name'] as String?,
    guardianEmail: json['guardian_email'] as String?,
    guardianAvatar: json['guardian_avatar'] as String?,
  );
}

// 대기 요청 전용 모델
class GuardianPendingModel {
  final int requestId;
  final String relation;
  final String status;
  final String invitedAt;
  final int guardianId;
  final String guardianName;
  final String guardianEmail;
  final String? guardianAvatar;

  const GuardianPendingModel({
    required this.requestId,
    required this.relation,
    required this.status,
    required this.invitedAt,
    required this.guardianId,
    required this.guardianName,
    required this.guardianEmail,
    this.guardianAvatar,
  });

  factory GuardianPendingModel.fromJson(Map<String, dynamic> json) =>
      GuardianPendingModel(
    requestId:      json['request_id']    as int,
    relation:       json['relation']      as String,
    status:         json['status']        as String,
    invitedAt:      json['invited_at']    as String,
    guardianId:     json['guardian_id']   as int,
    guardianName:   json['guardian_name'] as String,
    guardianEmail:  json['guardian_email'] as String,
    guardianAvatar: json['guardian_avatar'] as String?,
  );
}
```

---

### 13-B. ScheduleModel / AttendanceModel

```dart
// lib/features/lessons/models/schedule_model.dart

class ScheduleModel {
  final int id;
  final int groupId;
  final int instructorId;
  final String instructorName;
  final String title;
  final String? description;
  final String scheduledAt;
  final int durationMinutes;
  final String? location;
  final int? capacity;
  final String status;          // 'scheduled' | 'completed' | 'cancelled'
  final int attendanceCount;
  final String createdAt;

  const ScheduleModel({
    required this.id,
    required this.groupId,
    required this.instructorId,
    required this.instructorName,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.durationMinutes,
    this.location,
    this.capacity,
    required this.status,
    required this.attendanceCount,
    required this.createdAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => ScheduleModel(
    id:               json['id']               as int,
    groupId:          json['group_id']          as int,
    instructorId:     json['instructor_id']     as int,
    instructorName:   json['instructor_name']   as String? ?? '',
    title:            json['title']             as String,
    description:      json['description']       as String?,
    scheduledAt:      json['scheduled_at']      as String,
    durationMinutes:  json['duration_minutes']  as int,
    location:         json['location']          as String?,
    capacity:         json['capacity']          as int?,
    status:           json['status']            as String,
    attendanceCount:  json['attendance_count']  as int? ?? 0,
    createdAt:        json['created_at']        as String,
  );
}

// lib/features/lessons/models/attendance_model.dart

class AttendanceModel {
  final int studentId;
  final String studentName;
  final String? avatarUrl;
  final String status;    // 'present' | 'absent' | 'late' | 'excused'
  final String? note;
  final String? recordedAt;

  const AttendanceModel({
    required this.studentId,
    required this.studentName,
    this.avatarUrl,
    required this.status,
    this.note,
    this.recordedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
    studentId:   json['student_id']   as int,
    studentName: json['student_name'] as String? ?? '',
    avatarUrl:   json['avatar_url']   as String?,
    status:      json['status']       as String,
    note:        json['note']         as String?,
    recordedAt:  json['recorded_at']  as String?,
  );

  AttendanceModel copyWith({String? status, String? note}) => AttendanceModel(
    studentId:   studentId,
    studentName: studentName,
    avatarUrl:   avatarUrl,
    status:      status ?? this.status,
    note:        note ?? this.note,
    recordedAt:  recordedAt,
  );
}

class ScheduleStats {
  final int total;
  final int present;
  final int absent;
  final int late;
  final int excused;

  const ScheduleStats({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });

  factory ScheduleStats.fromJson(Map<String, dynamic> json) => ScheduleStats(
    total:   json['total']   as int? ?? 0,
    present: json['present'] as int? ?? 0,
    absent:  json['absent']  as int? ?? 0,
    late:    json['late']    as int? ?? 0,
    excused: json['excused'] as int? ?? 0,
  );
}
```

---

### 13-C. GuardianProvider

```dart
// lib/features/guardians/providers/guardian_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/guardian_model.dart';

class GuardianProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<GuardianModel> _guardians = [];
  List<GuardianPendingModel> _pendingRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GuardianModel> get guardians => _guardians;
  List<GuardianPendingModel> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── GET /guardians?role=mine|students
  Future<void> loadGuardians({String role = 'mine'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _api.get('/guardians', queryParams: {'role': role});
      final list = (res['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      _guardians = list.map(GuardianModel.fromJson).toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── GET /guardians/pending
  Future<void> loadPendingRequests() async {
    try {
      final res = await _api.get('/guardians/pending');
      final list = (res['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      _pendingRequests = list.map(GuardianPendingModel.fromJson).toList();
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  // ── POST /guardians/link
  Future<bool> linkGuardian({
    int? minorUserId,
    String? minorEmail,
    required String relation,
    int? groupId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final body = <String, dynamic>{'relation': relation};
      if (minorUserId != null) body['minor_user_id'] = minorUserId;
      if (minorEmail != null)  body['minor_email']   = minorEmail;
      if (groupId != null)     body['group_id']      = groupId;
      await _api.post('/guardians/link', body: body);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── POST /guardians/link/:id/accept
  Future<bool> acceptRequest(int requestId) async {
    try {
      await _api.post('/guardians/link/$requestId/accept');
      await loadPendingRequests();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ── POST /guardians/link/:id/reject
  Future<bool> rejectRequest(int requestId) async {
    try {
      await _api.post('/guardians/link/$requestId/reject');
      await loadPendingRequests();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  // ── DELETE /guardians/:guardianUserId
  Future<bool> removeGuardian(int guardianUserId) async {
    try {
      await _api.delete('/guardians/$guardianUserId');
      _guardians.removeWhere((g) =>
        g.guardianId == guardianUserId || g.studentId == guardianUserId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }
}
```

---

### 13-D. ScheduleProvider

```dart
// lib/features/lessons/providers/schedule_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../models/schedule_model.dart';
import '../models/attendance_model.dart';

class ScheduleProvider extends ChangeNotifier {
  final _api = ApiClient();

  List<ScheduleModel> _schedules = [];
  ScheduleModel? _currentSchedule;
  List<AttendanceModel> _attendances = [];
  ScheduleStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  List<ScheduleModel> get schedules => _schedules;
  ScheduleModel? get currentSchedule => _currentSchedule;
  List<AttendanceModel> get attendances => _attendances;
  ScheduleStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── GET /lessons/:groupId/schedules
  Future<void> loadSchedules(
    int groupId, {
    String? status,
    int page = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final params = <String, dynamic>{'page': page.toString()};
      if (status != null) params['status'] = status;
      final res = await _api.get(
        '/lessons/$groupId/schedules',
        queryParams: params,
      );
      final list = (res['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      _schedules = list.map(ScheduleModel.fromJson).toList();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── POST /lessons/:groupId/schedules
  Future<bool> createSchedule(
    int groupId,
    Map<String, dynamic> body,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.post('/lessons/$groupId/schedules', body: body);
      final newSchedule = ScheduleModel.fromJson(
        res['data'] as Map<String, dynamic>,
      );
      _schedules.insert(0, newSchedule);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // ── GET /lessons/:groupId/schedules/:id
  Future<void> loadScheduleDetail(int groupId, int scheduleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _api.get('/lessons/$groupId/schedules/$scheduleId');
      final data = res['data'] as Map<String, dynamic>;
      _currentSchedule = ScheduleModel.fromJson(data);
      _attendances = (data['attendances'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(AttendanceModel.fromJson)
          .toList();
      _stats = ScheduleStats.fromJson(
        data['stats'] as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── POST /lessons/:groupId/schedules/:id/attendance
  Future<bool> processAttendance(
    int groupId,
    int scheduleId,
    List<AttendanceModel> attendances,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.post(
        '/lessons/$groupId/schedules/$scheduleId/attendance',
        body: {
          'attendances': attendances.map((a) => {
            'student_id': a.studentId,
            'status': a.status,
            'note': a.note,
          }).toList(),
        },
      );
      // 로컬 상태 갱신
      await loadScheduleDetail(groupId, scheduleId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }
}
```

---

### 13-E. app_router.dart — 신규 라우트 추가

```dart
// lib/routes/app_router.dart

// 라우트 상수 추가
static const String guardians = '/guardians';
static const String lessonSchedules = '/lesson-schedules';
static const String scheduleDetail  = '/schedule-detail';

// generateRoute() switch 문에 추가
case AppRoutes.guardians:
  return MaterialPageRoute(
    builder: (_) => const GuardiansScreen(),
  );

case AppRoutes.lessonSchedules:
  final args = settings.arguments as Map<String, dynamic>?;
  final groupId = args?['group_id'] as int? ?? 0;
  return MaterialPageRoute(
    builder: (_) => LessonSchedulesScreen(groupId: groupId),
  );

case AppRoutes.scheduleDetail:
  final args = settings.arguments as Map<String, dynamic>?;
  final groupId    = args?['group_id']    as int? ?? 0;
  final scheduleId = args?['schedule_id'] as int? ?? 0;
  return MaterialPageRoute(
    builder: (_) => ScheduleDetailScreen(
      groupId: groupId,
      scheduleId: scheduleId,
    ),
  );
```

---

## 14. 파일 수정 원장 (v3.0 예정)

| 파일 경로 | 상태 | 주요 변경 내용 |
|-----------|------|--------------|
| `lib/core/api/mock/mock_data.dart` | **수정 예정** | `guardianLinks[]`, `lessonSchedules{}`, `lessonAttendances{}` 상태 추가 (섹션 8-A 참조) |
| `lib/core/api/mock/mock_auth.dart` | **수정 예정** | `register()` 응답에서 `verify_token` 제거 (섹션 8-D 참조) |
| `lib/core/api/mock/mock_guardians.dart` | **신규** | Guardian API 7개 메서드 전체 구현 (섹션 8-B 참조) |
| `lib/core/api/mock/mock_schedules.dart` | **신규** | Schedule/Attendance API 5개 메서드 전체 구현 (섹션 8-C 참조) |
| `lib/core/api/mock_api.dart` | **수정 예정** | export 2개 추가 + MockUsers Guardian/Schedule 어댑터 12개 추가 (섹션 8-F 참조) |
| `lib/core/api/api_client.dart` | **수정 예정** | Guardian/Schedule/파트너/채팅업로드 라우팅 추가, forgot-password 보안 패치 (섹션 8-E 참조) |
| `lib/features/guardians/models/guardian_model.dart` | **신규** | `GuardianModel`, `GuardianPendingModel` (섹션 13-A 참조) |
| `lib/features/guardians/providers/guardian_provider.dart` | **신규** | 7개 API 연동 (섹션 13-C 참조) |
| `lib/features/guardians/screens/guardians_screen.dart` | **신규** | 학생/보호자 탭 구조 (섹션 7 UI 참조) |
| `lib/features/lessons/models/schedule_model.dart` | **신규** | `ScheduleModel`, `ScheduleStats` (섹션 13-B 참조) |
| `lib/features/lessons/models/attendance_model.dart` | **신규** | `AttendanceModel` (섹션 13-B 참조) |
| `lib/features/lessons/providers/schedule_provider.dart` | **신규** | 5개 API 연동 (섹션 13-D 참조) |
| `lib/features/lessons/screens/lesson_schedules_screen.dart` | **신규** | 일정 목록 화면 |
| `lib/features/lessons/screens/schedule_detail_screen.dart` | **신규** | 일정 상세 + 출석 현황 화면 |
| `lib/features/auth/screens/register_screen.dart` | **수정 예정** | `verify_token` arguments 전달 제거 (섹션 1-C 참조) |
| `lib/features/auth/screens/email_verification_screen.dart` | **수정 예정** | `_devToken`/`verify_token` 의존 코드 전체 제거 (섹션 1-C 참조) |
| `lib/features/chat/screens/chat_room_screen.dart` | **수정 예정** | 📎 파일 업로드 버튼 + `POST /chat/rooms/:roomId/upload` API 연동 |
| `lib/features/chat/screens/chat_list_screen.dart` | **수정 예정** | free 플랜 사용자에게 메시지 보관 1일 안내 배너 표시 |
| `lib/routes/app_router.dart` | **수정 예정** | `/guardians`, `/lesson-schedules`, `/schedule-detail` 라우트 추가 (섹션 13-E 참조) |

---

## 15. Build/Test 상태 (v3.0 인계 시점)

- **Branch**: `main`
- **Last commit**: `c86443a` — feat: v2.9 T7~T9 구현 (프로필수정/명함생성2탭/명함상세 avatar+tags+sns)
- **flutter analyze**: No issues found ✅
- **Uncommitted changes**: `METI_NativeApp_Agent_Prompt_v3.0.md` (미 push)
- **Remote**: `smee96/meti-app` main 브랜치 동기화 완료 (커밋 `c86443a`까지)

### 세션 종료 전 필수 작업

```bash
# 1. v3.0 문서 커밋
cd /home/user/flutter_app
git add METI_NativeApp_Agent_Prompt_v3.0.md
git commit -m "docs: v3.0 에이전트 프롬프트 완성 (Guardian API / Lesson Schedule API / auth 보안패치 / Mock 구현코드 포함)"

# 2. GitHub push
git push origin main
```

---

*본 문서는 METI 백엔드 실제 구현 (https://github.com/smee96/THE-METI) 및 앱 코드 (https://github.com/smee96/meti-app) 기반으로 작성되었습니다.*  
*v3.0 작성일: 2026-05-29*  
*기준 백엔드 커밋: `0c65554`*  
*기준 앱 커밋: `c86443a`*
