/// 채팅방 목록 모델.
/// 백엔드 roomModel.js의 getRoomList (GET /rooms) 응답 필드에 맞춰 구성했습니다.
class ChatRoomModel {
  final String id; // roomId
  final String counterpartName;
  final String? counterpartImg;
  final String? productImg;
  final String lastMessage; // Text 위젯에 non-null로 바로 쓰여서 기본값 '' 처리
  final String? lastMessageHoursAgo; // 백엔드가 "N시간 전" 형태의 문자열로 내려줌

  // 아래 두 개는 현재 GET /rooms 응답(getRoomList)에 없는 값입니다.
  // TODO: 백엔드에 온라인 상태 / 안 읽은 메시지 수 필드 추가 요청 필요. 그 전까지는 기본값으로 둡니다.
  final bool isOpponentOnline;
  final int unreadCount;

  ChatRoomModel({
    required this.id,
    required this.counterpartName,
    this.counterpartImg,
    this.productImg,
    this.lastMessage = '',
    this.lastMessageHoursAgo,
    this.isOpponentOnline = false,
    this.unreadCount = 0,
  });

  // 프론트(ChatBubble 등)가 이미 이 이름들로 쓰고 있어서 실제 필드의 별칭으로 제공.
  String get opponentName => counterpartName;
  String? get opponentAvatarUrl => counterpartImg;
  String get relativeTime => lastMessageHoursAgo ?? '';

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['roomId'].toString(),
      counterpartName: json['counterpartName'] as String? ?? '',
      counterpartImg: json['counterpartImg'] as String?,
      productImg: json['productImg'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageHoursAgo: json['lastMessageHoursAgo'] as String?,
      // 백엔드가 나중에 필드를 추가하면 자동으로 반영되도록 optional로 읽어둠
      isOpponentOnline: json['isOpponentOnline'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 채팅방 상단(상대방 정보) 표시용 모델.
/// chatSocket.js의 'room_info' 이벤트 페이로드에 대응합니다.
/// (counterpartName, counterpartTemperature, counterpartTemperatureLevel, productImg)
class ChatRoomInfoModel {
  final String counterpartName;
  final num? counterpartTemperature;
  final String?
  counterpartTemperatureLevel; // getTemperatureLevel()의 반환값 - 정확한 값 종류(예: "hot"/"warm"/"cold")는 백엔드 utils/temperature.js 확인 필요
  final String? productImg;

  ChatRoomInfoModel({
    required this.counterpartName,
    this.counterpartTemperature,
    this.counterpartTemperatureLevel,
    this.productImg,
  });

  factory ChatRoomInfoModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomInfoModel(
      counterpartName: json['counterpartName'] as String? ?? '',
      counterpartTemperature: json['counterpartTemperature'] as num?,
      counterpartTemperatureLevel: json['counterpartTemperatureLevel']
          ?.toString(),
      productImg: json['productImg'] as String?,
    );
  }
}
