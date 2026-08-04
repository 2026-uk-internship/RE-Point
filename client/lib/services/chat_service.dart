import '../models/chat_room_model.dart';
import '../models/message_model.dart';

/// 채팅 관련 데이터를 가져오는 서비스 레이어.
///
/// 지금은 더미 데이터를 반환하지만, 실제 백엔드가 준비되면 아래 TODO 부분만
/// http(REST) 또는 web_socket_channel(실시간) 호출로 교체하면 됩니다.
/// UI(Screen) 코드는 이 클래스의 메서드 시그니처만 그대로 사용하면 되므로
/// 백엔드 연동 시 화면 코드를 거의 건드리지 않아도 됩니다.
class ChatService {
  // 싱글턴으로 사용해도 되고, Provider/Riverpod 등 DI로 주입해도 됩니다.
  static final ChatService instance = ChatService._internal();
  ChatService._internal();

  // TODO: 실제 로그인 사용자 id로 교체 (로그인 모듈에서 가져오기)
  static const String currentUserId = 'me';

  static const String _baseUrl = 'https://api.your-domain.com'; // TODO: 실제 API 주소

  /// 채팅방 목록 조회
  /// TODO: GET $_baseUrl/chat-rooms 로 교체
  Future<List<ChatRoomModel>> fetchChatRooms() async {
    await Future.delayed(const Duration(milliseconds: 300)); // 네트워크 지연 흉내

    return [
      ChatRoomModel(
        id: 'room_1',
        opponentId: 'oliver',
        opponentName: 'Oliver :B',
        lastMessage: 'Hello :P',
        lastMessageAt: DateTime.now().subtract(const Duration(minutes: 1)),
        isOpponentOnline: true,
      ),
      ChatRoomModel(
        id: 'room_2',
        opponentId: 'pp',
        opponentName: ':PP',
        lastMessage: 'I would like to purchase.',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ChatRoomModel(
        id: 'room_3',
        opponentId: 'james',
        opponentName: 'James',
        lastMessage: 'Did you sell it?',
        lastMessageAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      ChatRoomModel(
        id: 'room_4',
        opponentId: 'andrew',
        opponentName: 'AndreW',
        lastMessage: "I'm sorry. Someone else...",
        lastMessageAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }

  /// 특정 채팅방의 메시지 목록 조회
  /// TODO: GET $_baseUrl/chat-rooms/$roomId/messages 로 교체
  Future<List<MessageModel>> fetchMessages(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final raw = <Map<String, dynamic>>[
      {'senderId': 'me', 'text': 'I want to buy it!', 'minutesAgo': 30},
      {'senderId': 'oliver', 'text': 'Oh, I like it!', 'minutesAgo': 28},
      {'senderId': 'oliver', 'text': 'How about around what time? Are you free?', 'minutesAgo': 27},
      {'senderId': 'me', 'text': "I'm all fine", 'minutesAgo': 26},
      {'senderId': 'me', 'text': 'I think Saturday morning is a good time', 'minutesAgo': 20},
      {'senderId': 'me', 'text': "Sounds good! Then let's meet around 10 a.m. on Saturday.", 'minutesAgo': 19},
      {'senderId': 'me', 'text': 'Where should we meet?', 'minutesAgo': 18},
    ];

    return raw.map((m) {
      final createdAt = now.subtract(Duration(minutes: m['minutesAgo'] as int));
      return MessageModel(
        id: '${roomId}_${m['minutesAgo']}',
        chatRoomId: roomId,
        senderId: m['senderId'] as String,
        text: m['text'] as String,
        createdAt: createdAt,
        isMe: m['senderId'] == currentUserId,
      );
    }).toList();
  }

  /// 메시지 전송
  /// TODO: POST $_baseUrl/chat-rooms/$roomId/messages 로 교체
  /// 실시간 수신은 WebSocket(web_socket_channel) 또는 Firebase 등으로 별도 스트림 구현 권장
  Future<MessageModel> sendMessage({
    required String roomId,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

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
  /// TODO: DELETE $_baseUrl/chat-rooms/$roomId/leave 로 교체
  Future<void> leaveChatRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// 알림 끄기 토글
  /// TODO: PATCH $_baseUrl/chat-rooms/$roomId/notifications 로 교체
  Future<void> toggleNotification(String roomId, bool mute) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}