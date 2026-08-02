# RE-Point API 문서

베이스 URL: `http://localhost:3000` (배포 시 실제 서버 주소로 교체)

## 공통 사항

- 로그인이 필요한 API는 **Header**에 아래처럼 JWT 토큰을 담아 보내야 해요.
  ```
  Authorization: Bearer {로그인 시 받은 token}
  ```
- 모든 요청/응답 Body는 `Content-Type: application/json`
- 에러 응답은 공통적으로 아래 형태예요.
  ```json
  { "message": "에러 설명" }
  ```

---

## 1. 회원 (Auth) O

### 1-1. 회원가입 O

`POST /auth/signup`

**요청**

```json
{
  "username": "test",
  "email": "test@test.com",
  "password": "1234",
  "repassword": "1234",
  "phone": "01012345678"
}
```

**응답 (201)**

```json
{
  "message": "Signup completed successfully.",
  "data": {
    "authId": 1,
    "locationId": 1,
    "user": { "insertId": 1 }
  }
}
```

**실패 케이스**
| 상태코드 | 상황 |
|---|---|
| 400 | 필수 항목 누락 / 비밀번호와 비밀번호 확인 불일치 |
| 409 | 이미 가입된 이메일 또는 전화번호 |

---

### 1-2. 로그인 O

`POST /auth/login`

**요청**

```json
{
  "email": "test@test.com",
  "password": "1234"
}
```

**응답 (200)**

```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "data": { "id": 1, "email": "test@test.com" }
}
```

> `token`은 로그인 후 필요한 모든 요청에 붙여서 보내야 하니, 앱 로컬(예: `flutter_secure_storage`)에 저장해두세요.

**실패 케이스**
| 상태코드 | 상황 |
|---|---|
| 404 | 존재하지 않는 회원 |
| 401 | 비밀번호 불일치 |

---

### 1-3. 회원 탈퇴 O

`DELETE /auth/:id`

예: `DELETE /auth/1`

**응답 (200)**

```json
{ "message": "Account deleted successfully." }
```

---

## 2. 카테고리 (Category)

### 2-1. 전체 카테고리 목록 조회 O

`GET /category`

**응답 (200)**

```json
{
  "data": [
    { "id": 1, "name": "Electronics", "point_rate": 0.02 },
    { "id": 2, "name": "Phones & Tablets", "point_rate": 0.02 }
  ]
}
```

> 회원가입/설정 화면의 관심 카테고리 선택, 상품 등록 화면의 카테고리 드롭다운에 공통으로 쓰면 돼요.

### 2-2. 특정 사용자의 관심 카테고리 조회 O

`GET /category/users/:id`

예: `GET /category/users/1`

**응답 (200)**

```json
{
  "data": [
    { "id": 1, "name": "Electronics", "point_rate": 0.02 },
    { "id": 3, "name": "Computers", "point_rate": 0.01 }
  ]
}
```

### 2-3. 사용자 관심 카테고리 저장 O

`PUT /category/users/:id`

**요청** — 선택한 카테고리 id를 배열로 (최대 5개, 기존 선택은 전부 교체됨)

```json
{
  "categoryIds": [1, 2, 3]
}
```

**응답 (200)**

```json
{ "message": "Categories updated successfully." }
```

**실패 케이스**
| 상태코드 | 상황 |
|---|---|
| 400 | `categoryIds`가 배열이 아님 / 6개 이상 선택 |

---

## 3. 상품 (Products)

### 3-1. 상품 등록 O

`POST /products`

`type`에 따라 필요한 필드가 달라요.

**일반거래 (`general`)** O

```json
{
  "title": "아이폰 13 팝니다",
  "description": "상태 좋아요",
  "type": "general",
  "money_price": 500000,
  "category_id": 1,
  "location": "서울시 강남구",
  "latitude": 37.4979,
  "longitude": 127.0276,
  "images": ["url1", "url2"]
}
```

**포인트거래 (`point`)** — `money_price` 대신 `point_price` 사용 O

```json
{
  "title": "무선 이어폰 팝니다",
  "type": "point",
  "point_price": 3000,
  "category_id": 2,
  "location": "서울시 마포구",
  "latitude": 37.5563,
  "longitude": 126.9236,
  "images": ["url1"]
}
```

**경매 (`auction`)** — `auction` 객체 추가 필요 O

```json
{
  "title": "빈티지 카메라 경매",
  "type": "auction",
  "category_id": 19,
  "location": "서울시 마포구",
  "latitude": 37.5563,
  "longitude": 126.9236,
  "auction": {
    "start_point": 1000,
    "end_date": "2026-08-10T23:59:59"
  }
}
```

**응답 (201) — 공통**

```json
{
  "message": "Product created successfully.",
  "data": { "id": 5 }
}
```

**실패 케이스**
| 상태코드 | 상황 |
|---|---|
| 400 | 공통 필수값 누락 / `type` 값이 잘못됨 / 타입별 필수값(가격, 경매정보) 누락 |

---

### 3-2. 메인 페이지 상품 목록 (일반/포인트거래) O

`GET /products/main`

**응답 (200)**

```json
{
  "data": [
    {
      "id": 5,
      "title": "아이폰 13 팝니다",
      "price": 500000,
      "type": "general",
      "location": "서울시 강남구"
    },
    {
      "id": 6,
      "title": "무선 이어폰 팝니다",
      "price": 3000,
      "type": "point",
      "location": "서울시 마포구"
    }
  ]
}
```

> `price`는 `general`이면 `money_price`, `point`면 `point_price`가 자동으로 들어가요. 프론트에서 `type` 보고 "원"/"포인트" 단위만 붙여주면 됩니다.

---

### 3-3. 경매 목록

`GET /products/auctions`

**응답 (200)**

```json
{
  "data": [
    {
      "id": 7,
      "title": "빈티지 카메라 경매",
      "isOngoing": true,
      "remaining": "05:23",
      "highestPoint": 1500
    },
    {
      "id": 8,
      "title": "레고 세트 경매",
      "isOngoing": false,
      "remaining": "00:00",
      "highestPoint": 800
    }
  ]
}
```

- `remaining`: 종료까지 남은 시간, `시:분` 형식 (예: `"05:23"` = 5시간 23분 남음)
- `isOngoing`: 경매가 아직 진행 중인지 여부

> ⚠️ 경매 **상세** 페이지는 디자인이 확정되지 않아 아직 API가 없어요 (서버 코드에 주석 처리만 되어있음). 디자인 나오면 바로 만들 예정이에요.

---

### 3-4. 상품 상세 조회 (일반/포인트거래)

`GET /products/:id`

예: `GET /products/5`

**응답 (200)**

```json
{
  "data": {
    "id": 5,
    "title": "아이폰 13 팝니다",
    "description": "상태 좋아요",
    "price": 500000,
    "userName": "test",
    "temperature": 65,
    "temperatureLevel": "warm",
    "location": "강남구 역삼동",
    "createdDaysAgo": "3일",
    "category": "Electronics",
    "images": ["url1", "url2"]
  }
}
```

- `temperature`: 판매자의 실제 온도 수치
- `temperatureLevel`: 색상 표시용으로 이미 단계 계산까지 해서 내려줘요 (`"cold"` / `"normal"` / `"warm"` / `"hot"`) → 프론트는 이 값만 보고 이미지/색상 매핑하면 돼요. 기준 수치는 나중에 바뀔 수 있어요.
- `createdDaysAgo`: 등록된 지 며칠 됐는지, `"n일"` 형식 문자열로 내려줘요.

---

## 4. 신고 (Report)

### 4-1. 신고 등록

`POST /report`

**요청** — 신고 대상 종류에 상관없이 하나의 API로 처리

```json
{
  "type": "product",
  "contents": "허위 매물입니다.",
  "related_id": 5
}
```

- `type`: `"user"` / `"chat"` / `"product"` / `"review"` 중 하나
- `related_id`: 신고 대상의 id (신고 대상이 상품이면 product id, 유저면 user id 등)

**응답 (201)**

```json
{
  "message": "Report submitted successfully.",
  "reportId": 3
}
```

**실패 케이스**
| 상태코드 | 상황 |
|---|---|
| 400 | 필수 항목 누락 / `type` 값이 4종 중 하나가 아님 |

---

## 5. 채팅 (Socket.IO)

REST가 아니라 **WebSocket(Socket.IO)** 로 동작해요. 연결 시 인증 방식이 달라서 따로 정리했어요.

### 5-1. 연결 & 인증

```dart
IO.Socket socket = IO.io(
  'http://localhost:3000',
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .setAuth({'token': jwtToken}) // 로그인 시 받은 토큰
    .build(),
);
socket.connect();
```

토큰이 없거나 유효하지 않으면 연결 자체가 거부돼요.

### 5-2. 채팅방 입장

**보내는 이벤트**: `join_room`

```json
5
```

(방(room) id 하나만 숫자로 전송)

**받는 이벤트**: `chat_history` — 입장하면 이전 대화 내역을 배열로 받아요.

```json
[
  {
    "id": 1,
    "user_id": 2,
    "user_name": "seller01",
    "message": "안녕하세요",
    "date": "2026-08-01T10:00:00"
  }
]
```

### 5-3. 메시지 보내기

**보내는 이벤트**: `send_message`

```json
{ "roomId": 5, "message": "네고 가능할까요?" }
```

**받는 이벤트**: `receive_message` — 같은 방에 있는 모두에게(나 포함) 실시간으로 전달돼요.

```json
{
  "id": 10,
  "roomId": 5,
  "userId": 3,
  "message": "네고 가능할까요?",
  "date": "2026-08-02T14:20:00"
}
```

### 5-4. 채팅방 생성/입장 (REST)

상품 상세 페이지에서 "채팅하기" 버튼 누르면, 채팅방을 먼저 REST로 만들거나 찾은 다음 그 `roomId`로 소켓에 접속하는 흐름이에요.

`POST /rooms` _(예정 — 아직 라우터 등록 전)_

```json
{ "productId": 5, "sellerId": 2 }
```

```json
{ "data": { "roomId": 5 } }
```

---

## 아직 준비 중인 기능

- 경매 상세 페이지 API (디자인 확정 대기)
- 채팅방 목록 조회 API (내가 참여 중인 방 리스트)
- 이메일 인증 (가입 시 코드 발송/확인)
- 채팅방 생성 라우터 정식 등록
