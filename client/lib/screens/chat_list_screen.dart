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

  bool _hasLoadError = false;

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final rooms = await _chatService.fetchChatRooms();
      if (!mounted) return;
      setState(() {
        _allRooms = rooms;
        _filteredRooms = rooms;
      });
    } catch (e) {
      debugPrint('채팅방 목록 조회 실패: $e');
      if (mounted) setState(() => _hasLoadError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredRooms = _allRooms
          .where(
            (r) => r.opponentName.toLowerCase().contains(query.toLowerCase()),
          )
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
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _hasLoadError
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '채팅 목록을 불러오지 못했습니다.',
                            style: TextStyle(color: ChatColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loadRooms,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRooms,
                      child: _filteredRooms.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'No conversations yet',
                                    style: TextStyle(
                                      color: ChatColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredRooms.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) =>
                                  _buildRoomTile(_filteredRooms[index]),
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
                      style: const TextStyle(
                        color: ChatColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    room.relativeTime,
                    style: const TextStyle(
                      color: ChatColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (room.unreadCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
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
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.white.withOpacity(0.1),
          backgroundImage: room.opponentAvatarUrl != null
              ? NetworkImage(room.opponentAvatarUrl!)
              : null,
          child: room.opponentAvatarUrl == null
              ? Text(
                  room.opponentName.isNotEmpty ? room.opponentName[0] : '?',
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        if (room.isOpponentOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: ChatColors.onlineDot,
                shape: BoxShape.circle,
                border: Border.all(
                  color: ChatColors.topBarBackground,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
