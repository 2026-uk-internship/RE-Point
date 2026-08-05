# RE-Point API 문서

베이스 URL: `http://localhost:3000` (배포 서버 주소는 별도 공유)

## 공통 사항

- 인증 필요 API: `Authorization: Bearer {token}`
- Body는 `Content-Type: application/json` (이미지 업로드는 `multipart/form-data`)
- 에러 응답: `{ "message": "에러 설명" }`

## 테스트 도구

`api-tester.html` 파일을 브라우저로 열면 아래 모든 API를 버튼 클릭만으로 테스트해볼 수 있어요.

1. 상단 Base URL을 서버 주소로 맞추기
2. 회원가입 → 로그인 (로그인하면 토큰이 자동 저장되고, 이후 인증 필요 기능에 자동으로 붙음)
3. 각 카드 버튼 클릭 → 실제 요청/응답을 그대로 확인 가능

플러터에서 각 기능 붙이기 전에, 이 도구로 먼저 요청/응답 모양을 직접 눌러보면서 확인하는 걸 추천해요.

---

## 1. 회원 (Auth)

### 회원가입

`POST /auth/signup`

```json
{
  "username": "test",
  "email": "test@test.com",
  "password": "1234",
  "repassword": "1234",
  "phone": "01012345678"
}
```

400: 필수값 누락/비밀번호 불일치 · 409: 이메일·전화번호 중복

### 로그인

`POST /auth/login`

```json
{ "email": "test@test.com", "password": "1234" }
```

응답: `{ "token": "...", "data": { "id": 1, "email": "..." } }`
404: 존재하지 않는 회원 · 401: 비밀번호 불일치

### 회원 탈퇴

`DELETE /auth/:id`

### 이메일 인증

구현되어 있으나 테스트 편의상 회원가입 시 자동 인증(`is_verified = true`) 처리 중.

---

## 2. 카테고리

### 전체 목록

`GET /category` — 알파벳순 정렬. `point_rate`, `co2_saved` 포함.

### 카테고리 그룹 목록 조회 (신규)

`GET /category/groups`

```json
{
  "data": [
    { "id": 1, "name": "Shopping" },
    { "id": 2, "name": "Clothing" },
    { "id": 3, "name": "School" },
    { "id": 4, "name": "Devices" }
  ]
}
```

### 특정 그룹의 상품 목록 조회 (신규)

`GET /category/groups/:id/products`

```json
{
  "data": [
    {
      "id": 5,
      "title": "아이폰 13 팝니다",
      "money_price": 500000,
      "point_price": null,
      "type": "general",
      "img": "url1"
    }
  ]
}
```

### 관심 카테고리 조회

`GET /category/users/:id`

### 관심 카테고리 저장

`PUT /category/users/:id` (최대 5개, 기존 선택 전체 교체)

```json
{ "categoryIds": [1, 2, 3] }
```

400: 배열 아님 / 6개 이상

---

## 3. 상품

### 등록

`POST /products` (multipart/form-data, 인증 필요)

이미지는 `images` 필드로 파일 첨부 (최대 10장, Cloudinary 업로드 후 URL을 DB에 저장).

**공통 필드**: `title`, `type`(general/point/auction), `category_id`, `location`, `latitude`, `longitude`
**general**: `money_price` · **point**: `point_price` · **auction**: `auction[start_point]`, `auction[end_date]`

응답: `{ "data": { "id": 5 } }`

### 목록 조회 (일반/포인트/경매 각각 분리)

`GET /products/general` · `GET /products/point` · `GET /products/auctions`

정렬: `?sort=likes|newest|oldest|name` (기본 newest)

일반/포인트 응답: `id, title, price, location, favoriteCount`
경매 응답: `id, title, isOngoing, remaining(시:분), highestPoint, favoriteCount`

> 경매 상세 페이지 API는 디자인 대기 중 (미구현)

### 상세 조회

`GET /products/:id`

```json
{
  "id": 5,
  "title": "...",
  "description": "...",
  "price": 500000,
  "userName": "...",
  "temperature": 65,
  "temperatureLevel": "warm",
  "location": "...",
  "createdDaysAgo": "3일",
  "category": "...",
  "images": ["url1"],
  "favoriteCount": 5,
  "chatCount": 2
}
```

### 같은 카테고리 / 같은 판매자 상품

`GET /products/:id/related-category` · `GET /products/:id/related-seller`

같은 타입(general/point/auction)만, 대표 이미지+제목만 반환. 카테고리 없는 상품은 빈 배열.

### 관심(찜) 토글

`POST /products/:id/favorite`
응답: `{ "data": { "favorited": true, "favoriteCount": 5 } }` — 최신 찜 개수까지 같이 와서 프론트에서 바로 반영 가능

---

## 4. 채팅방 (Rooms)

### 목록 조회

`GET /rooms?keyword=` — 상대 이름 검색 가능

```json
{
  "roomId": 5,
  "counterpartName": "...",
  "counterpartImg": "...",
  "productImg": "...",
  "lastMessage": "...",
  "lastMessageHoursAgo": "2시간 전"
}
```

최근 메시지는 최신순 정렬로.

### 생성/입장

`POST /rooms`

```json
{ "productId": 5 }
```

이미 있으면 기존 roomId 반환. 400: productId 누락 / 본인 상품에 채팅 시도 · 404: 상품 없음

---

## 5. 채팅 (Socket.IO)

연결 시 `auth: { token }`로 인증.

| 이벤트                             | 방향 | 내용                                                   |
| ---------------------------------- | ---- | ------------------------------------------------------ |
| `join_room`                        | 보냄 | roomId (숫자)                                          |
| `room_info`                        | 받음 | 상대 이름/온도/온도단계, 상품 이미지                   |
| `chat_history`                     | 받음 | 이전 메시지 배열, 각 항목에 `timeDisplay`(hh:mm AM/PM) |
| `send_message`                     | 보냄 | `{ roomId, message }`                                  |
| `receive_message`                  | 받음 | 메시지 + `timeDisplay`                                 |
| `typing` / `stop_typing`           | 보냄 | `{ roomId }` — 입력 중/중단                            |
| `user_typing` / `user_stop_typing` | 받음 | `{ userId }`                                           |

플러터: `socket_io_client` 패키지, 화면 진입 시 connect + join_room, 화면 종료 시 disconnect. typing은 2~3초 debounce 권장.

---

## 6. 신고

`POST /report`

```json
{ "type": "product", "contents": "...", "related_id": 5 }
```

`type`: user/chat/product/review. 400: 필수값 누락 / type 오류

---

## 7. 검색

### 상품 검색

`GET /search?keyword=` (인증 필요, 검색 로그 자동 기록)

```json
{
  "data": {
    "generalAndPoint": [
      {
        "id": 5,
        "title": "...",
        "img": "...",
        "price": 500000,
        "createdDaysAgo": "3일",
        "favoriteCount": 4,
        "chatCount": 2
      }
    ],
    "auction": [
      {
        "id": 9,
        "title": "...",
        "img": "...",
        "price": null,
        "createdDaysAgo": "1일",
        "favoriteCount": 1,
        "chatCount": 0
      }
    ]
  }
}
```

### 이번 달 인기 검색어 TOP 5

`GET /search/popular` (인증 불필요)

### 최근 검색어 조회 / 삭제

`GET /search/recent` · `DELETE /search/recent/:searchId` (내 기록만 삭제, 인기 검색어엔 영향 없음)

---

## 8. 프로필

### 내 프로필

`GET /users/me`

```json
{
  "name": "...",
  "img": "...",
  "temperature": 65,
  "temperatureLevel": "warm",
  "point": 1200,
  "totalEarnedPoint": 3400,
  "boughtCount": 5,
  "soldCount": 8,
  "co2SavedKg": 412.5
}
```

`co2SavedKg`: 완료 거래(구매+판매 합산) 기준 추정치.

### 프로필 이미지 변경

`PUT /users/me/profile-image` (multipart/form-data, 필드명 `image`)

### 다른 사용자 프로필 조회

`GET /users/:id/profile` (인증 불필요)

```json
{
  "name": "...",
  "img": "...",
  "temperature": 72,
  "temperatureLevel": "warm",
  "lastActiveHoursAgo": "3시간 전",
  "categories": ["Electronics", "Books & Stationery"],
  "sellingProducts": [
    { "id": 5, "title": "...", "price": 500000, "img": "url1" }
  ],
  "auctionProducts": [
    { "id": 9, "title": "...", "highestPoint": 1500, "img": "url3" }
  ]
}
```

판매중(`sale`)인 일반/포인트 상품, 종료 안 된 경매만 포함. `categories`는 관심 카테고리. `lastActiveHoursAgo`는 인증 요청 시마다(5분 간격) 자동 갱신.

---

## 9. 지역

### 지역 목록

`GET /locations` — 영국 자치구 단위(Camden, Westminster 등). 응답의 `id`를 그대로 아래 설정 API에 사용 (id가 1부터 시작하지 않을 수 있음 — 항상 이 목록 조회 결과 기준으로 사용)

### 내 지역 설정

`PUT /users/me/location`

```json
{ "locationId": 3 }
```

---

## 10. 게시판 (동네생활)

| API                                 | 설명                                |
| ----------------------------------- | ----------------------------------- |
| `POST /posts`                       | 글 작성 (인증)                      |
| `GET /posts?location=`              | 목록 (지역 필터, commentCount 포함) |
| `GET /posts/:id`                    | 상세 (댓글 포함)                    |
| `PUT /posts/:id`                    | 수정 (작성자만)                     |
| `DELETE /posts/:id`                 | 삭제 (작성자만)                     |
| `POST /posts/:id/comments`          | 댓글 작성 (인증)                    |
| `DELETE /posts/comments/:commentId` | 댓글 삭제 (작성자만)                |

---

## 아직 준비 중

- 경매 상세 페이지 API (디자인 확정 대기)
