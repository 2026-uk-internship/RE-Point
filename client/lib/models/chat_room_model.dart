/// 채팅 목록 화면(디자인의 "sub" 화면)에서 쓰이는 채팅방 요약 모델.
class ChatRoomModel {
  final String id;
  final String opponentId;
  final String opponentName;
  final String? opponentAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOpponentOnline;

  ChatRoomModel({
    required this.id,
    required this.opponentId,
    required this.opponentName,
    this.opponentAvatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOpponentOnline = false,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'].toString(),
      opponentId: json['opponentId'].toString(),
      opponentName: json['opponentName'] as String,
      opponentAvatarUrl: json['opponentAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isOpponentOnline: json['isOpponentOnline'] as bool? ?? false,
    );
  }

  /// 목록 화면에 "Just Now", "Two days ago" 처럼 상대 시간으로 보여주기 위한 헬퍼.
  String get relativeTime {
    final diff = DateTime.now().difference(lastMessageAt);
    if (diff.inMinutes < 1) return 'Just Now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return weeks == 1 ? 'A week ago' : '$weeks weeks ago';
    final months = (diff.inDays / 30).floor();
    return months <= 1 ? 'One month ago' : '$months months ago';
  }
}