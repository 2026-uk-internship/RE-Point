/// 채팅방 안의 개별 메시지 모델.
/// 백엔드 API(REST or WebSocket)에서 내려주는 JSON 스펙에 맞춰
/// fromJson의 key 이름만 바꿔주면 바로 연동 가능합니다.
class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  /// 현재 로그인한 사용자가 보낸 메시지인지 여부.
  /// 서버에서 내려주기보다 클라이언트에서 senderId와 내 userId를 비교해 계산하는 걸 추천합니다.
  final bool isMe;

  MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isMe,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {required String myUserId}) {
    return MessageModel(
      id: json['id'].toString(),
      chatRoomId: json['chatRoomId'].toString(),
      senderId: json['senderId'].toString(),
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isMe: json['senderId'].toString() == myUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get formattedTime {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}