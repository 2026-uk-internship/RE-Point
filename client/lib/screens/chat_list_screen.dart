import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../services/chat_service.dart';
import '../theme/chat_theme.dart';
import 'chat_room_screen.dart';

/// 채팅 목록 화면 (디자인의 "sub" 화면).
///
/// 주의: 이 위젯은 더 이상 자체 Scaffold/BottomNavigationBar를 갖지 않습니다.
/// MainPage가 전체 Scaffold + 하단 네비게이션을 담당하고,
/// 이 화면은 그 안의 "채팅" 탭 콘텐츠(body)로만 쓰입니다.
/// 채팅방을 눌러서 들어가는 ChatRoomScreen은 별도 페이지라서 자체 Scaffold를 유지합니다.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<ChatRoomModel> _allRooms = [];
  List<ChatRoomModel> _filteredRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    final rooms = await _chatService.fetchChatRooms();
    setState(() {
      _allRooms = rooms;
      _filteredRooms = rooms;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredRooms = _allRooms
          .where((r) => r.opponentName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 없이 배경 + 내용만 반환. 바깥의 MainPage가 Scaffold 역할을 함.
    return Container(
      decoration: ChatColors.screenBackground(),
      child: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : RefreshIndicator(
                      onRefresh: _loadRooms,
                      child: _filteredRooms.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'No conversations yet',
                                    style: TextStyle(color: ChatColors.textSecondary),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredRooms.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 4),
                              itemBuilder: (context, index) => _buildRoomTile(_filteredRooms[index]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: ChatColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: ChatColors.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTile(ChatRoomModel room) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(
                roomId: room.id,
                opponentName: room.opponentName,
                opponentAvatarUrl: room.opponentAvatarUrl,
                isOpponentOnline: room.isOpponentOnline,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _buildAvatar(room),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.opponentName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      room.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: ChatColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    room.relativeTime,
                    style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                  ),
                  if (room.unreadCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: ChatColors.accentYellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${room.unreadCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF241A3D),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildAvatar(ChatRoomModel room) {
    // 💡 참고: room.itemImageUrl (상품/게시물 이미지 URL) 속성이 ChatRoomModel에 있어야 합니다.
    // 만약 모델에 해당 값이 없다면 임시로 room.opponentAvatarUrl 등을 넣거나 모델을 확장해주세요!
    final String? itemImageUrl = room.itemImageUrl; // 예시 (필요시 모델 속성명에 맞게 변경)
    final String? profileImageUrl = room.opponentAvatarUrl;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 뒤쪽에 배치되는 게시물/상품 메인 사진 (둥근 사각형)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // 첨부 이미지와 같은 둥근 모서리
                color: Colors.white.withOpacity(0.1),
                image: itemImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(itemImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: itemImageUrl == null
                  ? const Icon(Icons.image, color: Colors.white38, size: 24)
                  : null,
            ),
          ),

          // 2. 우측 하단에 겹쳐서 올라가는 상대방 프로필 사진 (작은 동그라미)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // 메인 사진 및 배경과 구분되는 테두리 효과
                border: Border.all(color: const Color(0xFF14091F), width: 2), 
              ),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 15, // 프로필 사진 크기
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl == null
                        ? Text(
                            room.opponentName.isNotEmpty ? room.opponentName[0] : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          )
                        : null,
                  ),

                  // 3. 온라인 표시 (초록색 점 / 빨간 세모 등)
                  if (room.isOpponentOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: ChatColors.onlineDot,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}