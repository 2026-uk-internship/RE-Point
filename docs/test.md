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

### 3-2. 일반거래 상품 목록

`GET /products/general`

**정렬** — `sort` 쿼리 파라미터 (생략 시 `newest`)
| 값 | 설명 |
|---|---|
| `likes` | 좋아요(찜) 많은 순 |
| `newest` | 최근 등록순 (기본값) |
| `oldest` | 오래된 순 |
| `name` | 이름순 |

예: `GET /products/general?sort=likes`

**응답 (200)**

```json
{
  "data": [
    {
      "id": 5,
      "title": "아이폰 13 팝니다",
      "price": 500000,
      "location": "서울시 강남구",
      "favoriteCount": 3
    }
  ]
}
```

---

### 3-3. 포인트거래 상품 목록

`GET /products/point`

**정렬** — 3-2와 동일한 `sort` 파라미터 사용 (`likes` / `newest` / `oldest` / `name`)

**응답 (200)**

```json
{
  "data": [
    {
      "id": 6,
      "title": "무선 이어폰 팝니다",
      "price": 3000,
      "location": "서울시 마포구",
      "favoriteCount": 0
    }
  ]
}
```

> 3-2, 3-3 모두 `price` 하나만 내려줘요 (각각 `money_price` / `point_price`). 목록 화면이 나뉘어 있으니 프론트에서 굳이 `type`으로 구분 안 하셔도 돼요.

---

### 3-4. 경매 상품 목록

`GET /products/auctions`

**정렬** — 3-2와 동일한 `sort` 파라미터 사용 (`likes` / `newest` / `oldest` / `name`)

**응답 (200)**

```json
{
  "data": [
    {
      "id": 7,
      "title": "빈티지 카메라 경매",
      "isOngoing": true,
      "remaining": "05:23",
      "highestPoint": 1500,
      "favoriteCount": 2
    },
    {
      "id": 8,
      "title": "레고 세트 경매",
      "isOngoing": false,
      "remaining": "00:00",
      "highestPoint": 800,
      "favoriteCount": 0
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

### 3-6. 같은 카테고리의 다른 상품

`GET /products/:id/related-category`

예: `GET /products/5/related-category`

상품 상세 페이지에서 "같은 카테고리 상품" 섹션에 쓰면 돼요. 보고 있는 상품과 **같은 타입(general/point/auction)**, **같은 카테고리**인 상품만 나와요.

**응답 (200)**

```json
{
  "data": [
    { "id": 8, "title": "무선 이어폰 팝니다", "img": "url1" },
    { "id": 12, "title": "블루투스 스피커", "img": "url3" }
  ]
}
```

> 경매 상품처럼 카테고리가 없는 상품이면 빈 배열(`[]`)이 와요.

---

### 3-7. 같은 판매자의 다른 상품

`GET /products/:id/related-seller`

예: `GET /products/5/related-seller`

보고 있는 상품과 **같은 타입(general/point/auction)**이면서, 같은 판매자가 등록한 다른 상품만 나와요.

**응답 (200)**

```json
{
  "data": [{ "id": 9, "title": "노트북 팝니다", "img": "url2" }]
}
```

> 3-6, 3-7 모두 지금 보고 있는 상품 자체는 목록에서 빠지고, 판매중(`sale`)인 상품만 나와요.

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

**검색** — `keyword` 쿼리 파라미터 (생략 시 전체 목록). 상대방 이름에 포함된 텍스트로 검색해요.

예: `GET /rooms?keyword=철수`

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

**받는 이벤트 1**: `room_info` — 채팅방 상단 헤더용 정보예요.

```json
{
  "counterpartName": "seller01",
  "counterpartTemperature": 65,
  "counterpartTemperatureLevel": "warm",
  "productImg": "product_url.jpg"
}
```

**받는 이벤트 2**: `chat_history` — 이전 대화 내역을 배열로 받아요.

```json
[
  {
    "id": 1,
    "user_id": 2,
    "user_name": "seller01",
    "message": "안녕하세요",
    "date": "2026-08-01T10:00:00",
    "timeDisplay": "10:00 AM"
  }
]
```

- `timeDisplay`: 화면에 바로 표시할 수 있는 `hh:mm AM/PM` 형식이에요. 원본 `date`도 같이 오니, 날짜 구분(오늘/어제 등)이 필요하면 `date`를 활용하시면 돼요.

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
  "date": "2026-08-02T14:20:00",
  "timeDisplay": "02:20 PM"
}
```

### 6-4. 작성 중 표시

상대방이 입력 중일 때 "작성 중..." 같은 표시를 띄우기 위한 이벤트예요.

**보내는 이벤트**: `typing` — 입력을 시작했을 때

```json
{ "roomId": 5 }
```

**보내는 이벤트**: `stop_typing` — 입력을 멈췄을 때 (마지막 입력 후 2~3초 지나면 프론트에서 debounce로 보내는 걸 추천해요)

```json
{ "roomId": 5 }
```

**받는 이벤트**: `user_typing` — 상대방이 입력 중일 때 (본인은 못 받아요)

```json
{ "userId": 2 }
```

**받는 이벤트**: `user_stop_typing` — 상대방이 입력을 멈췄을 때

```json
{ "userId": 2 }
```

---

### 6-5. 플러터 연동 가이드

채팅 화면 하나를 통째로 구현할 때 참고할 수 있게, 전체 흐름을 순서대로 정리했어요.

**패키지 설치**

```yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

**1) 채팅방 목록 화면 (5-1 API로 조회)**

`GET /rooms`로 목록을 받아서 리스트로 뿌리고, 방 하나를 탭하면 채팅방 화면으로 이동하면서 `roomId`를 넘겨주면 돼요. 이때 소켓 연결은 하지 않아도 돼요 — 목록 조회는 REST라 소켓이 필요 없어요.

**2) 채팅방 화면 진입 시 — 소켓 연결 + 방 입장**

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatRoomController {
  late IO.Socket socket;
  final int roomId;
  final String jwtToken;

  ChatRoomController({required this.roomId, required this.jwtToken});

  void connect() {
    socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': jwtToken})
        .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      socket.emit('join_room', roomId);
    });

    // 채팅방 상단 헤더 (상대방 이름, 온도, 상품 이미지)
    socket.on('room_info', (data) {
      // setState로 헤더 UI 업데이트
      // data['counterpartName'], data['counterpartTemperatureLevel'], data['productImg']
    });

    // 이전 대화 내역 (화면 진입 시 한 번)
    socket.on('chat_history', (data) {
      // List<dynamic> data — 메시지 리스트로 렌더링
      // 각 항목: data[i]['message'], data[i]['timeDisplay']
    });

    // 실시간 새 메시지
    socket.on('receive_message', (data) {
      // 리스트 맨 아래에 새 메시지 추가
      // data['message'], data['timeDisplay'], data['userId']
    });

    // 상대방 작성 중 표시
    socket.on('user_typing', (data) {
      // "작성 중..." 표시 ON
    });

    socket.on('user_stop_typing', (data) {
      // "작성 중..." 표시 OFF
    });

    socket.onConnectError((err) {
      // 토큰 만료/무효 시 여기로 옴 — 로그인 화면으로 리다이렉트 처리 추천
    });
  }

  void sendMessage(String text) {
    socket.emit('send_message', {'roomId': roomId, 'message': text});
  }

  void notifyTyping() {
    socket.emit('typing', {'roomId': roomId});
  }

  void notifyStopTyping() {
    socket.emit('stop_typing', {'roomId': roomId});
  }

  void disconnect() {
    socket.disconnect();
  }
}
```

**3) 입력창에 타이핑 감지 붙이기 (debounce)**

매 글자마다 `typing`을 보내면 트래픽이 많아지니, 타이머로 묶어서 보내는 걸 추천해요.

```dart
Timer? _typingTimer;

void onTextChanged(String text) {
  controller.notifyTyping();

  _typingTimer?.cancel();
  _typingTimer = Timer(const Duration(seconds: 2), () {
    controller.notifyStopTyping();
  });
}
```

**4) 화면 나갈 때**

```dart
@override
void dispose() {
  controller.disconnect();
  super.dispose();
}
```

**전체 흐름 요약**

1. 채팅방 목록 화면: `GET /rooms` (REST)
2. "채팅하기" 버튼 or 목록에서 방 선택: `POST /rooms`로 roomId 획득 (신규 진입 시) 또는 목록의 roomId 그대로 사용
3. 채팅방 화면 진입: 소켓 연결 → `join_room` emit → `room_info`, `chat_history` 수신해서 화면 초기화
4. 메시지 입력 중: `typing`/`stop_typing` emit (debounce 적용)
5. 메시지 전송: `send_message` emit → 모든 참여자가 `receive_message`로 수신
6. 화면 나가기: 소켓 연결 해제

**주의할 점**

- 소켓은 채팅방 화면에 들어갈 때 연결하고, 나갈 때 반드시 `disconnect()` 해주세요. 여러 채팅방을 오갈 때 이전 연결을 안 끊으면 중복 연결/중복 수신 문제가 생겨요.
- JWT가 만료된 상태로 소켓 연결을 시도하면 `onConnectError`로 걸려요. REST API와 마찬가지로 401 처리(로그인 화면 이동)를 여기서도 해주셔야 해요.

---

## 7. 이메일 인증 (Email Verification)

가입 절차상 구현은 되어있고, **테스트 편의를 위해 지금은 회원가입 시 자동으로 인증된 상태(`is_verified = true`)로 처리** 중이에요. 실제 이메일 인증 플로우를 프론트에 붙이실 때 알려주시면 라우트 목록 정리해서 다시 공유해드릴게요.

---

## 8. 프로필 (Profile)

### 8-1. 내 프로필 조회

`GET /users/me`

**응답 (200)**

```json
{
  "data": {
    "name": "test",
    "img": "profile.jpg",
    "temperature": 65,
    "temperatureLevel": "warm",
    "point": 1200,
    "totalEarnedPoint": 3400,
    "boughtCount": 5,
    "soldCount": 8,
    "co2SavedKg": 412.5
  }
}
```

- `temperatureLevel`: 상품 상세와 동일하게 서버에서 단계 계산해서 내려줘요 (`"cold"` / `"normal"` / `"warm"` / `"hot"`)
- `totalEarnedPoint`: 지금까지 판매로 벌어들인 포인트 누적값
- `boughtCount` / `soldCount`: 완료된 거래(`trades.status = 'completed'`) 기준 구매/판매 건수
- `co2SavedKg`: 완료된 거래(구매+판매 합산)를 카테고리별 절감 가중치로 환산한 **추정치**예요. 실제 측정값이 아니라 대략적인 참고 수치라, 프론트에서 노출하실 때 "약 OOkg 절약" 정도로 표현해주시면 좋을 것 같아요.

---

## 아직 준비 중인 기능

- 경매 상세 페이지 API (디자인 확정 대기)

궁금한 거나 응답 형식 바꾸고 싶은 거 있으면 언제든 얘기해주세요!
