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

> 알파벳 순으로 정렬돼서 와요. 회원가입/설정 화면의 관심 카테고리 선택, 상품 등록 화면의 카테고리 드롭다운에 공통으로 쓰면 돼요.

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

### 3-2. 일반거래 상품 목록 O

`GET /products/general`

**응답 (200)**

```json
{
  "data": [
    {
      "id": 5,
      "title": "아이폰 13 팝니다",
      "price": 500000,
      "location": "서울시 강남구"
    }
  ]
}
```

---

### 3-3. 포인트거래 상품 목록 O

`GET /products/point`

**응답 (200)**

```json
{
  "data": [
    {
      "id": 6,
      "title": "무선 이어폰 팝니다",
      "price": 3000,
      "location": "서울시 마포구"
    }
  ]
}
```

> 3-2, 3-3 모두 `price` 하나만 내려줘요 (각각 `money_price` / `point_price`). 목록 화면이 나뉘어 있으니 프론트에서 굳이 `type`으로 구분 안 하셔도 돼요.

---

### 3-4. 경매 상품 목록 O

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

### 3-5. 상품 상세 조회 (일반/포인트거래) O

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

### 4-1. 신고 등록 O

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

## 5. 채팅방 (Rooms)

채팅방 생성/조회는 REST로 처리하고, 실제 메시지 주고받기는 아래 6번(Socket.IO)에서 처리해요.

### 5-1. 채팅방 목록 조회

`GET /rooms`

**응답 (200)**

```json
{
  "data": [
    {
      "roomId": 5,
      "counterpartName": "seller01",
      "counterpartImg": "profile_url.jpg",
      "productImg": "product_url.jpg",
      "lastMessage": "네고 가능할까요?",
      "lastMessageHoursAgo": "2시간 전"
    }
  ]
}
```

- 내가 판매자든 구매자든 참여 중인 모든 방이 나와요. `counterpartName`/`counterpartImg`는 상대방 기준으로 자동 계산돼서 와요.
- 아직 대화가 없는 새 방은 `lastMessage`, `lastMessageHoursAgo`가 `null`로 와요 — 이 경우 "대화를 시작해보세요" 같은 문구로 처리해주세요.
- 최근 메시지가 온 순서(최신순)로 정렬돼서 와요.

### 5-2. 채팅방 생성/입장

`POST /rooms`

상품 상세 페이지의 "채팅하기" 버튼을 누르면 호출해요. 이미 방이 있으면 새로 안 만들고 기존 방 id를 그대로 돌려줘요.

**요청** — 판매자 id는 안 보내도 돼요. 서버가 상품 정보로 자동 조회해요.

```json
{ "productId": 5 }
```

**응답 (200)**

```json
{ "data": { "roomId": 5 } }
```

**실패 케이스**
| 상태코드 | 상황 |
|---|---|
| 400 | `productId` 누락 / 본인이 등록한 상품에 본인이 채팅 시도 |
| 404 | 존재하지 않는 상품 |

이후 받은 `roomId`로 아래 6번의 소켓 `join_room`에 접속하면 실시간 채팅이 시작돼요.

---

## 6. 채팅 (Socket.IO) 🔒

REST가 아니라 **WebSocket(Socket.IO)** 로 동작해요. 연결 시 인증 방식이 달라서 따로 정리했어요.

### 6-1. 연결 & 인증

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

### 6-2. 채팅방 입장

**보내는 이벤트**: `join_room`

```json
5
```

(방(room) id 하나만 숫자로 전송 — 5번 채팅방 API로 받은 `roomId`)

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

### 6-3. 메시지 보내기

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

---

## 7. 이메일 인증 (Email Verification)

가입 절차상 구현은 되어있고, **테스트 편의를 위해 지금은 회원가입 시 자동으로 인증된 상태(`is_verified = true`)로 처리** 

---

## 아직 준비 중인 기능

- 경매 상세 페이지 API (디자인 확정 대기)
