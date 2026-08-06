/// 채팅 메시지 모델.
///
/// 두 가지 소켓 이벤트 페이로드를 모두 파싱할 수 있게 만들었습니다.
/// - 'chat_history' (입장 시 과거 내역): { id, user_id, user_name, message, date, timeDisplay }
/// - 'receive_message' (실시간 수신): { id, roomId, userId, message, date, timeDisplay }  ← user_name 없음
class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String
  senderName; // receive_message 이벤트나 낙관적(optimistic) 메시지에는 값이 없어 빈 문자열일 수 있음
  final String text;
  final DateTime createdAt;
  final String
  timeDisplay; // 백엔드가 "09:41 AM" 형태로 이미 포맷해서 내려줌. 없으면 createdAt으로 대체 계산.
  final bool isMe;

  /// ChatBubble 등 프론트 위젯이 이미 이 이름으로 사용 중이라 timeDisplay의 별칭으로 제공.
  /// timeDisplay가 비어 있으면(예: 낙관적 메시지) createdAt으로부터 직접 계산합니다.
  String get formattedTime {
    if (timeDisplay.isNotEmpty) return timeDisplay;
    final hour24 = createdAt.hour;
    final period = hour24 < 12 ? 'AM' : 'PM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    this.senderName = '',
    required this.text,
    required this.createdAt,
    this.timeDisplay = '',
    required this.isMe,
  });

  factory MessageModel.fromJson(
    Map<String, dynamic> json, {
    required String chatRoomId,
    required String currentUserId,
  }) {
    final senderId = (json['user_id'] ?? json['userId']).toString();
    final rawDate = json['date'];

    return MessageModel(
      id: json['id'].toString(),
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: json['user_name'] as String? ?? '',
      text: json['message'] as String? ?? '',
      createdAt: rawDate is String ? DateTime.parse(rawDate) : DateTime.now(),
      timeDisplay: json['timeDisplay'] as String? ?? '',
      isMe: senderId == currentUserId,
    );
  }
}
