import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import 'api_service.dart'; // ApiConfig
import 'current_user.dart'; // CurrentUser

/// 채팅 관련 데이터를 다루는 서비스 레이어.
///
/// - 채팅방 목록 조회 / 생성-입장 : REST (roomRouter.js)
/// - 채팅방 입장, 메시지 내역, 실시간 메시지, 타이핑 표시 : Socket.IO (chatSocket.js)
///
/// pubspec.yaml에 아래 패키지가 필요합니다.
///   http: ^1.2.0
///   socket_io_client: ^2.0.3+1
class ChatService {
  static final ChatService instance = ChatService._internal();
  ChatService._internal();

  static const String _baseUrl = 'https://re-point.up.railway.app';

  // 로그인 시 AuthService.login()이 저장해두는 진짜 토큰을 그대로 참조.
  String? get _token => ApiConfig.token;

  /// 프론트가 ChatService.currentUserId처럼 클래스 레벨에서 바로 접근하고 있어서 static으로 제공.
  static String get currentUserId => CurrentUser.id?.toString() ?? '';

  Map<String, String> get _authHeaders {
    if (_token == null) {
      throw ChatServiceException('로그인이 필요합니다.', code: 'NO_TOKEN');
    }
    return {
      'Authorization': 'Bearer $_token',
      'Content-Type': 'application/json',
    };
  }

  // ---------------------------------------------------------------------
  // REST: 채팅방 목록 / 생성
  // ---------------------------------------------------------------------

  /// 채팅방 목록 조회
  /// GET /rooms  (keyword 지정 시 상대방 이름으로 필터링)
  Future<List<ChatRoomModel>> fetchChatRooms({String? keyword}) async {
    final uri = Uri.parse('$_baseUrl/rooms').replace(
      queryParameters: keyword != null && keyword.isNotEmpty
          ? {'keyword': keyword}
          : null,
    );

    final res = await http.get(uri, headers: _authHeaders);
    final body = _decode(res);

    final list = (body['data'] ?? body) as List<dynamic>;
    return list
        .map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 상품 기준으로 채팅방 생성 또는 기존 방 입장
  /// POST /rooms  { productId }
  /// 실패 시 PRODUCT_NOT_FOUND / CANNOT_CHAT_WITH_SELF 코드가 던져질 수 있습니다.
  Future<String> createOrEnterRoom(String productId) async {
    final uri = Uri.parse('$_baseUrl/rooms');
    final res = await http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode({'productId': int.parse(productId)}),
    );
    final body = _decode(res);
    final roomId = body['data']?['roomId'] ?? body['roomId'];
    return roomId.toString();
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isNotEmpty
        ? jsonDecode(res.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final code =
          body['message'] as String? ??
          body['error'] as String? ??
          'UNKNOWN_ERROR';
      throw ChatServiceException(code, code: code, statusCode: res.statusCode);
    }
    return body;
  }

  // ---------------------------------------------------------------------
  // Socket.IO: 채팅방 입장 / 메시지 실시간 처리
  // ---------------------------------------------------------------------

  IO.Socket? _socket;
  String? _currentRoomId;

  final _roomInfoController = StreamController<ChatRoomInfoModel>.broadcast();
  final _historyController = StreamController<List<MessageModel>>.broadcast();
  final _messageController = StreamController<MessageModel>.broadcast();
  final _typingController = StreamController<String>.broadcast(); // userId
  final _stopTypingController = StreamController<String>.broadcast(); // userId
  final _errorController = StreamController<String>.broadcast();

  /// 채팅방 상단 상대방 정보 ('room_info' 이벤트)
  Stream<ChatRoomInfoModel> get roomInfoStream => _roomInfoController.stream;

  /// 방 입장 시 받는 과거 메시지 목록 ('chat_history' 이벤트)
  Stream<List<MessageModel>> get historyStream => _historyController.stream;

  /// 실시간으로 도착하는 메시지 (내가 보낸 것 포함, 'receive_message' 이벤트)
  Stream<MessageModel> get messageStream => _messageController.stream;

  /// 상대방이 입력 중일 때 상대방 userId가 흘러옴
  Stream<String> get userTypingStream => _typingController.stream;

  /// 상대방이 입력을 멈췄을 때 상대방 userId가 흘러옴
  Stream<String> get userStopTypingStream => _stopTypingController.stream;

  /// 소켓 연결/인증 에러 메시지
  Stream<String> get errorStream => _errorController.stream;

  /// 소켓 연결. 앱 시작 시 또는 채팅 화면 진입 시 한 번 호출.
  /// 채팅방 입장은 [joinRoom]으로 별도 수행합니다.
  void connect() {
    if (_socket != null) return; // 이미 연결(또는 연결 시도) 중

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({
            'token': _token,
          }) // chatSocket.js: socket.handshake.auth.token
          .build(),
    );

    _socket!
      ..onConnectError((err) => _errorController.add('연결 실패: $err'))
      ..onError((err) => _errorController.add('소켓 오류: $err'))
      ..on('room_info', (data) {
        _roomInfoController.add(
          ChatRoomInfoModel.fromJson(Map<String, dynamic>.from(data)),
        );
      })
      ..on('chat_history', (data) {
        final roomId = _currentRoomId;
        if (roomId == null) return;
        final list = (data as List)
            .map(
              (e) => MessageModel.fromJson(
                Map<String, dynamic>.from(e as Map),
                chatRoomId: roomId,
                currentUserId: currentUserId,
              ),
            )
            .toList();
        _historyController.add(list);
      })
      ..on('receive_message', (data) {
        final map = Map<String, dynamic>.from(data as Map);
        final roomId = (map['roomId'] ?? _currentRoomId).toString();
        _messageController.add(
          MessageModel.fromJson(
            map,
            chatRoomId: roomId,
            currentUserId: currentUserId,
          ),
        );
      })
      ..on('user_typing', (data) {
        final map = Map<String, dynamic>.from(data as Map);
        _typingController.add(map['userId'].toString());
      })
      ..on('user_stop_typing', (data) {
        final map = Map<String, dynamic>.from(data as Map);
        _stopTypingController.add(map['userId'].toString());
      });

    _socket!.connect();
  }

  /// 소켓이 실제로 연결될 때까지 대기 (join_room을 연결 전에 보내는 걸 방지).
  Future<void> _ensureConnected() {
    if (_socket != null && _socket!.connected) return Future.value();

    connect();
    final completer = Completer<void>();
    _socket!.onConnect((_) {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw ChatServiceException(
        '서버에 연결하지 못했습니다.',
        code: 'CONNECT_TIMEOUT',
      ),
    );
  }

  /// 특정 채팅방에 입장. 입장하면 서버가 'room_info'와 'chat_history'를 보내줍니다.
  void joinRoom(String roomId) {
    _currentRoomId = roomId;
    _socket?.emit('join_room', roomId);
  }

  /// [ChatRoomScreen], [ChatSearchPage] 등 화면이 기존 REST 스타일(await로 한 번에
  /// 리스트 받기)로 짜여 있어서, socket 기반이지만 겉으로는 Future로 감싸주는 호환 메서드입니다.
  /// 내부적으로 join_room을 보내고 첫 chat_history 응답을 기다렸다가 반환합니다.
  /// 실시간으로 이어지는 메시지가 필요하면 [messageStream]을 직접 구독하세요.
  Future<List<MessageModel>> fetchMessages(String roomId) async {
    await _ensureConnected();

    final completer = Completer<List<MessageModel>>();
    late StreamSubscription<List<MessageModel>> sub;
    sub = historyStream.listen((list) {
      if (!completer.isCompleted) completer.complete(list);
      sub.cancel();
    });

    joinRoom(roomId);

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        sub.cancel();
        throw ChatServiceException('메시지를 불러오지 못했습니다.', code: 'HISTORY_TIMEOUT');
      },
    );
  }

  /// 메시지 전송. 서버가 같은 방의 전원(보낸 사람 포함)에게 브로드캐스트하므로,
  /// 실제 도착 확인은 [messageStream]으로 받으세요. 여기서는 emit만 하고 즉시 반환합니다.
  Future<void> sendMessage({
    required String roomId,
    required String text,
  }) async {
    await _ensureConnected();
    _socket?.emit('send_message', {'roomId': roomId, 'message': text});
  }

  void startTyping(String roomId) {
    _socket?.emit('typing', {'roomId': roomId});
  }

  void stopTyping(String roomId) {
    _socket?.emit('stop_typing', {'roomId': roomId});
  }

  /// 채팅방 나가기 (메뉴의 "Going out to the chat room").
  /// TODO: 백엔드에 명시적인 나가기 REST/소켓 이벤트가 없어 현재는 클라이언트 상태만 정리합니다.
  /// 백엔드팀에 DELETE /rooms/:roomId 또는 'leave_room' 소켓 이벤트 추가를 요청하는 걸 추천해요.
  Future<void> leaveChatRoom(String roomId) async {
    if (_currentRoomId == roomId) _currentRoomId = null;
  }

  /// 알림 끄기 토글.
  /// TODO: 지금까지 보여주신 roomRouter.js / chatSocket.js에는 이 라우트가 없었습니다.
  /// 백엔드에 PATCH /rooms/:roomId/notifications (또는 다른 경로) 존재 여부 확인 필요.
  Future<void> toggleNotification(String roomId, bool mute) async {
    final uri = Uri.parse('$_baseUrl/rooms/$roomId/notifications');
    final res = await http.patch(
      uri,
      headers: _authHeaders,
      body: jsonEncode({'mute': mute}),
    );
    _decode(res);
  }

  /// 앱 종료/로그아웃 등 완전히 연결을 끊을 때.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentRoomId = null;
  }

  void dispose() {
    _roomInfoController.close();
    _historyController.close();
    _messageController.close();
    _typingController.close();
    _stopTypingController.close();
    _errorController.close();
    disconnect();
  }
}

/// 채팅 API 호출 실패 시 던지는 예외.
/// 백엔드가 던지는 PRODUCT_NOT_FOUND, CANNOT_CHAT_WITH_SELF 같은 코드를 그대로 담아
/// UI 단에서 code로 분기해 적절한 메시지를 보여줄 수 있게 합니다.
class ChatServiceException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  ChatServiceException(this.message, {required this.code, this.statusCode});

  @override
  String toString() => 'ChatServiceException($code): $message';
}
