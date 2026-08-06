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
class ChatService {
  static final ChatService instance = ChatService._internal();
  ChatService._internal();

  static const String _baseUrl = 'https://re-point.up.railway.app';

  String? get _token => ApiConfig.token;

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

  // 이 소켓이 지금까지 join한 방 id들을 계속 추적.
  // leave_room을 못 보내는 예외 상황(연결 끊김 등)이 생겨도
  // 최소한 클라이언트 필터링(messageStream 구독 쪽)의 근거로 쓸 수 있게 별도로 들고 있음.
  final Set<String> _joinedRoomIds = {};

  final _roomInfoController = StreamController<ChatRoomInfoModel>.broadcast();
  final _historyController = StreamController<List<MessageModel>>.broadcast();
  final _messageController = StreamController<MessageModel>.broadcast();
  final _typingController = StreamController<String>.broadcast(); // userId
  final _stopTypingController = StreamController<String>.broadcast(); // userId
  final _errorController = StreamController<String>.broadcast();

  Stream<ChatRoomInfoModel> get roomInfoStream => _roomInfoController.stream;
  Stream<List<MessageModel>> get historyStream => _historyController.stream;

  /// 실시간으로 도착하는 메시지 (내가 보낸 것 포함, 'receive_message' 이벤트).
  /// 주의: 이 스트림은 ChatService 전역에서 하나만 존재하는 broadcast stream입니다.
  /// 소켓이 여러 방에 join되어 있으면 그 방들 메시지가 전부 여기로 섞여 들어오므로,
  /// 반드시 구독하는 쪽(ChatRoomScreen)에서 msg.chatRoomId를 확인하고 필터링해야 합니다.
  Stream<MessageModel> get messageStream => _messageController.stream;

  Stream<String> get userTypingStream => _typingController.stream;
  Stream<String> get userStopTypingStream => _stopTypingController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// 소켓 연결. 앱 시작 시 또는 채팅 화면 진입 시 한 번 호출.
  void connect() {
    if (_socket != null) return; // 이미 연결(또는 연결 시도) 중

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': _token})
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
        // 서버가 roomId를 안 실어 보내는 경우를 대비한 fallback이지만,
        // 소켓이 여러 방에 join되어 있으면 이 fallback 자체가 오염원이 될 수 있음.
        // → 서버 쪽에서 receive_message에 roomId를 항상 포함해서 보내도록 확인 필요.
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

  /// 특정 채팅방에 입장.
  /// 이전에 다른 방에 join되어 있었다면 그 방은 먼저 leave 처리합니다.
  /// (서버 chatSocket.js의 join_room 핸들러도 socket.leave() 로직이 있는지 함께 확인 필요)
  void joinRoom(String roomId) {
    if (_currentRoomId != null && _currentRoomId != roomId) {
      _socket?.emit('leave_room', _currentRoomId);
      _joinedRoomIds.remove(_currentRoomId);
    }
    _currentRoomId = roomId;
    _joinedRoomIds.add(roomId);
    _socket?.emit('join_room', roomId);
  }

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

  /// 채팅방 나가기 (메뉴의 "Going out to the chat room" 또는 화면 dispose 시 호출).
  /// 서버에 leave_room을 실제로 emit해서 socket.io room 멤버십에서 빠지도록 합니다.
  /// TODO: 백엔드에 leave_room 소켓 핸들러가 없다면 추가 요청 필요.
  Future<void> leaveChatRoom(String roomId) async {
    _socket?.emit('leave_room', roomId);
    _joinedRoomIds.remove(roomId);
    if (_currentRoomId == roomId) _currentRoomId = null;
  }

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
  /// 반드시 로그아웃 플로우에서 호출해야 합니다. 이걸 안 부르면
  /// - 소켓이 이전 유저의 토큰(auth)으로 계속 붙어있고
  /// - 이전에 join했던 방 멤버십도 그대로 남아있어서
  /// 재로그인 후 엉뚱한 방 메시지가 섞여 들어오는 원인이 됩니다.
  void disconnect() {
    // 살아있던 방들 전부 leave 시도 (best-effort)
    for (final roomId in _joinedRoomIds) {
      _socket?.emit('leave_room', roomId);
    }
    _joinedRoomIds.clear();

    _socket?.offAny();
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

class ChatServiceException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  ChatServiceException(this.message, {required this.code, this.statusCode});

  @override
  String toString() => 'ChatServiceException($code): $message';
}
