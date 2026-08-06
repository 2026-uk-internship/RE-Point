import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import 'api_service.dart';
import 'current_user.dart';

/// 채팅 관련 데이터를 실제 백엔드(api_service.dart)와 연동하는 서비스 레이어.
///
/// - 채팅방 목록: REST (ChatRoomService.getRooms)
/// - 메시지 내역/실시간 송수신: Socket.IO (ChatSocketService)
///
/// ⚠️ TODO: chat_room_model.dart / message_model.dart 파일을 직접 못 봐서,
/// 필드 이름은 화면(chat_list_screen.dart, chat_room_screen.dart)에서 쓰는
/// 걸 보고 추정했습니다. 컴파일 에러 나면 그 두 모델 파일 내용 보여주세요.
///
/// ⚠️ TODO: 서버가 실제로 내려주는 JSON 키 이름(예: opponentName인지
/// partner.username인지 등)도 문서가 없어서 흔한 패턴으로 추정했습니다.
/// 실행 후 콘솔에 실제 응답을 print해서 확인하고, 필요하면 _parseRoom /
/// _parseSingleMessage 안의 키 이름만 바꿔주면 됩니다.
class ChatService {
  static final ChatService instance = ChatService._internal();
  ChatService._internal();

  // 로그인 시 CurrentUser에 캐싱된 내 사용자 id를 그대로 사용
  static String get currentUserId => CurrentUser.id?.toString() ?? '';

  final ChatSocketService _socket = ChatSocketService();
  bool _isSocketConnected = false;
  int? _joinedRoomId;
  Completer<List<MessageModel>>? _pendingHistoryCompleter;

  // 실시간으로 들어오는 메시지를 ChatRoomScreen에 전달하는 스트림
  final StreamController<MessageModel> _incomingMessageController =
      StreamController<MessageModel>.broadcast();
  Stream<MessageModel> get onMessageReceived => _incomingMessageController.stream;

  void _ensureSocketConnected() {
    if (_isSocketConnected) return;
    _socket.connect(
      onRoomInfo: (data) {
        // TODO: 방 참여자 정보 등이 필요하면 여기서 처리
      },
      onChatHistory: (data) {
        // joinRoom 이후 서버가 내려주는 이전 메시지 목록
        final list = _parseMessageList(data);
        if (_pendingHistoryCompleter != null &&
            !_pendingHistoryCompleter!.isCompleted) {
          _pendingHistoryCompleter!.complete(list);
        }
      },
      onReceiveMessage: (data) {
        final message = _parseSingleMessage(data);
        if (message != null) {
          _incomingMessageController.add(message);
        }
      },
      onUserTyping: (data) {
        // TODO: 타이핑 인디케이터가 필요하면 여기서 스트림/콜백 추가
      },
      onUserStopTyping: (data) {},
    );
    _isSocketConnected = true;
  }

  /// 채팅방 목록 조회 (REST)
  Future<List<ChatRoomModel>> fetchChatRooms({String keyword = ''}) async {
    try {
      final res = await ChatRoomService.getRooms(keyword: keyword);
      // 실제 서버 응답을 콘솔에서 확인하기 위한 디버그 로그.
      // 빈 배열이면 그냥 DB에 채팅방이 없는 것이고, 응답 자체가 에러/이상하면
      // 여기서 확인 가능합니다.
      debugPrint('🔍 [Chat] 채팅방 목록 응답: $res');
      final list = (res['data'] is List) ? res['data'] as List : <dynamic>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(_parseRoom)
          .toList();
    } catch (e) {
      debugPrint('🔍 [Chat] 채팅방 목록 조회 실패: $e');
      return [];
    }
  }

  ChatRoomModel _parseRoom(Map<String, dynamic> e) {
    final opponent =
        (e['opponent'] ?? e['partner'] ?? e['otherUser']) as Map<String, dynamic>?;

    return ChatRoomModel(
      id: '${e['id']}',
      opponentId: '${opponent?['id'] ?? e['opponentId'] ?? ''}',
      opponentName:
          (opponent?['username'] ?? e['opponentName'] ?? 'User').toString(),
      lastMessage: (e['lastMessage'] ?? '').toString(),
      lastMessageAt:
          DateTime.tryParse('${e['lastMessageAt'] ?? e['updatedAt'] ?? ''}') ??
              DateTime.now(),
      isOpponentOnline: e['isOpponentOnline'] == true,
    );
  }

  /// 특정 채팅방의 메시지 목록 조회.
  /// REST가 아니라, 소켓으로 방에 join하면 서버가 'chat_history'로 내려줌.
  Future<List<MessageModel>> fetchMessages(String roomId) async {
    _ensureSocketConnected();
    final id = int.tryParse(roomId) ?? 0;
    _joinedRoomId = id;

    _pendingHistoryCompleter = Completer<List<MessageModel>>();
    _socket.joinRoom(id);

    // 서버 응답이 안 올 경우를 대비한 타임아웃
    return _pendingHistoryCompleter!.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => <MessageModel>[],
    );
  }

  List<MessageModel> _parseMessageList(dynamic data) {
    final list = (data is List)
        ? data
        : ((data is Map && data['messages'] is List)
            ? data['messages'] as List
            : <dynamic>[]);
    return list
        .map(_parseSingleMessage)
        .whereType<MessageModel>()
        .toList();
  }

  MessageModel? _parseSingleMessage(dynamic e) {
    if (e is! Map) return null;
    final senderId = '${e['senderId'] ?? e['userId'] ?? ''}';
    return MessageModel(
      id: '${e['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: '${e['roomId'] ?? _joinedRoomId ?? ''}',
      senderId: senderId,
      text: (e['message'] ?? e['text'] ?? '').toString(),
      createdAt: DateTime.tryParse('${e['createdAt'] ?? ''}') ?? DateTime.now(),
      isMe: senderId == currentUserId,
    );
  }

  /// 메시지 전송 (소켓)
  Future<MessageModel> sendMessage({
    required String roomId,
    required String text,
  }) async {
    _ensureSocketConnected();
    final id = int.tryParse(roomId) ?? _joinedRoomId ?? 0;
    _socket.sendMessage(id, text);

    // 화면(chat_room_screen.dart)에서 이미 낙관적으로 표시하고 있으므로
    // 여기서는 서버 ack을 기다리지 않고 바로 반환.
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatRoomId: roomId,
      senderId: currentUserId,
      text: text,
      createdAt: DateTime.now(),
      isMe: true,
    );
  }

  /// 채팅방 나가기
  /// TODO: api_service.dart에 "나가기" 전용 REST가 아직 없어서, 방이 생기면
  /// 여기에 실제 엔드포인트를 연결하면 됩니다. 지금은 소켓 룸 상태만 정리.
  Future<void> leaveChatRoom(String roomId) async {
    if (_joinedRoomId == int.tryParse(roomId)) {
      _joinedRoomId = null;
    }
  }

  /// 알림 끄기 토글
  /// TODO: api_service.dart에 알림 on/off 전용 API가 아직 없어서 연결 대기 중.
  Future<void> toggleNotification(String roomId, bool mute) async {}

  void dispose() {
    _socket.disconnect();
    _isSocketConnected = false;
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

/// 로그인 토큰/유저 정보 접근용 자리표시자.
/// TODO: 프로젝트에 이미 있는 실제 인증 서비스로 교체하세요.
class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  String? token;
  String? userId;
}
