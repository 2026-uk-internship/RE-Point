import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

// ------------------------------------------------------
// 0. 공통 API 설정 및 토큰 관리
// ------------------------------------------------------
class ApiConfig {
  static const String baseUrl = 'https://re-point.up.railway.app'; // 배포 URL
  static String? token;

  static void setToken(String newToken) => token = newToken;
  static void clearToken() => token = null;

  static Map<String, String> getHeaders({bool needsAuth = false}) {
    final headers = {'Content-Type': 'application/json'};
    if (needsAuth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}

// ------------------------------------------------------
// 1. 회원 (Auth)
// ------------------------------------------------------
class AuthService {
  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
    required String repassword,
    required String phone,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/signup'),
      headers: ApiConfig.getHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'repassword': repassword,
        'phone': phone,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: ApiConfig.getHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['token'] != null) {
      ApiConfig.setToken(data['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> deleteAccount(int userId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/auth/$userId'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 2. 카테고리 (Category)
// ------------------------------------------------------
class CategoryService {
  static Future<Map<String, dynamic>> getCategories() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/category'));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getGroups() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/category/groups'),
    );
    return jsonDecode(res.body);
  }

  // ⚠️ 서버 실제 라우트는 /products/groups/:id 로 확인됨.
  // 아래는 예전 경로라 404가 날 수 있음 — ProductService.getProductsByGroup() 사용 권장.
  static Future<Map<String, dynamic>> getProductsByGroup(int groupId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/category/groups/$groupId/products'),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getUserCategories(int userId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/category/users/$userId'),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> setUserCategories(
    int userId,
    List<int> categoryIds,
  ) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/category/users/$userId'),
      headers: ApiConfig.getHeaders(needsAuth: true),
      body: jsonEncode({'categoryIds': categoryIds}),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 3. 상품 (Product)
// ------------------------------------------------------
class ProductService {
  static Future<Map<String, dynamic>> getProductList(
    String type, {
    String sort = 'newest',
  }) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/$type?sort=$sort'),
    );
    return jsonDecode(res.body);
  }

  // 실제 서버 라우트: GET /products/groups/:id
  static Future<Map<String, dynamic>> getProductsByGroup(int groupId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/groups/$groupId'),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getProductDetail(int productId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/$productId'),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getRelatedByCategory(
    int productId,
  ) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/$productId/related-category'),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getRelatedBySeller(int productId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/$productId/related-seller'),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> toggleFavorite(int productId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/products/$productId/favorite'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createProduct({
    required String title,
    required String type, // general, point, auction
    required int categoryId,
    required String location,
    required double latitude,
    required double longitude,
    int? moneyPrice,
    int? pointPrice,
    int? startPoint,
    String? endDate,
    List<String>? imagePaths,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/products'),
    );
    if (ApiConfig.token != null)
      req.headers['Authorization'] = 'Bearer ${ApiConfig.token}';

    req.fields['title'] = title;
    req.fields['type'] = type;
    req.fields['category_id'] = categoryId.toString();
    req.fields['location'] = location;
    req.fields['latitude'] = latitude.toString();
    req.fields['longitude'] = longitude.toString();

    if (type == 'general' && moneyPrice != null)
      req.fields['money_price'] = moneyPrice.toString();
    if (type == 'point' && pointPrice != null)
      req.fields['point_price'] = pointPrice.toString();
    if (type == 'auction') {
      if (startPoint != null)
        req.fields['auction[start_point]'] = startPoint.toString();
      if (endDate != null) req.fields['auction[end_date]'] = endDate;
    }

    if (imagePaths != null) {
      for (var path in imagePaths) {
        req.files.add(await http.MultipartFile.fromPath('images', path));
      }
    }

    final streamedRes = await req.send();
    final res = await http.Response.fromStream(streamedRes);
    return jsonDecode(res.body);
  }

  // ---------------------------------------------------------
  // 마이페이지 - 판매 목록
  // GET /products/me/selling, /me/sold, /me/auctions/selling, /me/auctions/sold
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> getMySelling() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/selling'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMySold() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/sold'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMySellingAuctions() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/auctions/selling'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMySoldAuctions() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/auctions/sold'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  // ---------------------------------------------------------
  // 마이페이지 - 최근 본 목록
  // GET /products/me/recent/general, /me/recent/auctions
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> getRecentGeneral() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/recent/general'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getRecentAuctions() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/recent/auctions'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  // ---------------------------------------------------------
  // 마이페이지 - 좋아요 목록
  // GET /products/me/favorites/general, /me/favorites/auctions
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> getFavoritedGeneral() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/favorites/general'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getFavoritedAuctions() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/favorites/auctions'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  // ---------------------------------------------------------
  // 마이페이지 - 경매 참여 목록 (입찰중 / 낙찰성공 / 낙찰실패)
  // GET /products/me/bidding/ongoing, /won, /lost
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> getBiddingOngoing() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/bidding/ongoing'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getBiddingWon() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/bidding/won'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getBiddingLost() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/me/bidding/lost'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  // ---------------------------------------------------------
  // 경매 상세 / 참여자 목록
  // GET /products/auctions/:id, /products/auctions/:id/participants
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> getAuctionDetail(int auctionId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/products/auctions/$auctionId'),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getAuctionParticipants(
    int auctionId,
  ) async {
    final res = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/products/auctions/$auctionId/participants',
      ),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 4. 채팅방 (Rooms)
// ------------------------------------------------------
class ChatRoomService {
  static Future<Map<String, dynamic>> getRooms({String keyword = ''}) async {
    final encoded = Uri.encodeComponent(keyword);
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/rooms?keyword=$encoded'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> createOrJoinRoom(int productId) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/rooms'),
      headers: ApiConfig.getHeaders(needsAuth: true),
      body: jsonEncode({'productId': productId}),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 5. 채팅 실시간 소켓 (Socket.IO)
// ------------------------------------------------------
class ChatSocketService {
  late io.Socket socket;

  void connect({
    required Function(dynamic) onRoomInfo,
    required Function(dynamic) onChatHistory,
    required Function(dynamic) onReceiveMessage,
    required Function(dynamic) onUserTyping,
    required Function(dynamic) onUserStopTyping,
  }) {
    socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': ApiConfig.token})
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.on('room_info', onRoomInfo);
    socket.on('chat_history', onChatHistory);
    socket.on('receive_message', onReceiveMessage);
    socket.on('user_typing', onUserTyping);
    socket.on('user_stop_typing', onUserStopTyping);
  }

  void joinRoom(int roomId) => socket.emit('join_room', roomId);
  void sendMessage(int roomId, String message) =>
      socket.emit('send_message', {'roomId': roomId, 'message': message});
  void startTyping(int roomId) => socket.emit('typing', {'roomId': roomId});
  void stopTyping(int roomId) => socket.emit('stop_typing', {'roomId': roomId});
  void disconnect() => socket.disconnect();
}

// ------------------------------------------------------
// 6. 신고 (Report)
// ------------------------------------------------------
class ReportService {
  static Future<Map<String, dynamic>> createReport({
    required String type, // user, chat, product, review
    required String contents,
    required int relatedId,
  }) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/report'),
      headers: ApiConfig.getHeaders(needsAuth: true),
      body: jsonEncode({
        'type': type,
        'contents': contents,
        'related_id': relatedId,
      }),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 7. 검색 (Search)
// ------------------------------------------------------
class SearchService {
  static Future<Map<String, dynamic>> searchProducts(String keyword) async {
    final encoded = Uri.encodeComponent(keyword);
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/search?keyword=$encoded'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getPopularKeywords() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/search/popular'),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getRecentSearches() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/search/recent'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteRecentSearch(int searchId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/search/recent/$searchId'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 8. 프로필 (Profile)
// ------------------------------------------------------
class ProfileService {
  static Future<Map<String, dynamic>> getMyProfile() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateProfileImage(
    String imagePath,
  ) async {
    final req = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiConfig.baseUrl}/users/me/profile-image'),
    );
    if (ApiConfig.token != null)
      req.headers['Authorization'] = 'Bearer ${ApiConfig.token}';

    req.files.add(await http.MultipartFile.fromPath('image', imagePath));
    final streamedRes = await req.send();
    final res = await http.Response.fromStream(streamedRes);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/$userId/profile'),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 9. 지역 (Location)
// ------------------------------------------------------
class LocationService {
  static Future<Map<String, dynamic>> getLocations() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/locations'));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> setMyLocation(int locationId) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/users/me/location'),
      headers: ApiConfig.getHeaders(needsAuth: true),
      body: jsonEncode({'locationId': locationId}),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 10. 게시판 / 동네생활 (Board)
// ------------------------------------------------------
class BoardService {
  static Future<Map<String, dynamic>> createPost(
    String title,
    String content,
    String location,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts'),
      headers: ApiConfig.getHeaders(needsAuth: true),
      body: jsonEncode({
        'title': title,
        'content': content,
        'location': location,
      }),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getPosts({String? location}) async {
    final uri = location != null
        ? Uri.parse(
            '${ApiConfig.baseUrl}/posts?location=${Uri.encodeComponent(location)}',
          )
        : Uri.parse('${ApiConfig.baseUrl}/posts');
    final res = await http.get(uri);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getPostDetail(int postId) async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/posts/$postId'));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updatePost(
    int postId,
    String title,
    String content,
  ) async {
    final res = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId'),
      headers: ApiConfig.getHeaders(needsAuth: true),
      body: jsonEncode({'title': title, 'content': content}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deletePost(int postId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addComment(
    int postId,
    String comment,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
      headers: ApiConfig.getHeaders(needsAuth: true),
      body: jsonEncode({'comment': comment}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteComment(int commentId) async {
    final res = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/posts/comments/$commentId'),
      headers: ApiConfig.getHeaders(needsAuth: true),
    );
    return jsonDecode(res.body);
  }
}

// ------------------------------------------------------
// 11. 실시간 상품 시청자 전용 소켓 서비스
// ------------------------------------------------------
class ProductSocketService {
  late io.Socket socket;

  // 소켓 연결
  void connect() {
    socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': ApiConfig.token})
          .disableAutoConnect()
          .build(),
    );

    socket.connect();
  }

  // 상품 상세 진입 이벤트 전송
  void joinProduct({
    required int productId,
    int? userId,
    String? userName,
    String? userImg, // 프로필 이미지 URL 추가
  }) {
    socket.emit('join_product', {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userImg': userImg,
    });
  }

  // 상품 상세 이탈 이벤트 전송
  void leaveProduct(int productId) {
    socket.emit('leave_product', {'productId': productId});
  }

  // 실시간 시청자 수/목록 수신 리스너 등록
  void onProductViewersUpdated(Function(dynamic) callback) {
    socket.on('product_viewers_updated', callback);
  }

  // 실시간 시청자 리스너 해제
  void offProductViewersUpdated() {
    socket.off('product_viewers_updated');
  }

  // 소켓 연결 끊기
  void disconnect() => socket.disconnect();
}
