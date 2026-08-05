import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../theme/chat_theme.dart';

/// 채팅방 메뉴의 "Searching for Chat"을 누르면 뜨는 화면.
/// 현재 채팅방(roomId) 안의 메시지를 검색해서 리스트로 보여줍니다.
///
/// 검색 결과를 탭하면 Navigator.pop(context, message)로 선택한
/// MessageModel을 돌려주므로, 호출한 쪽(ChatRoomScreen)에서
/// 해당 메시지 위치로 스크롤하는 로직을 이어서 붙이면 됩니다.
class ChatSearchPage extends StatefulWidget {
  final String roomId;
  final String opponentName;
  final String? opponentAvatarUrl;

  const ChatSearchPage({
    super.key,
    required this.roomId,
    required this.opponentName,
    this.opponentAvatarUrl,
  });

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final ChatService _chatService = ChatService.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<MessageModel> _allMessages = [];
  List<MessageModel> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // 화면 진입 시 바로 검색창에 포커스 (design 상 바로 입력 가능한 상태)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final messages = await _chatService.fetchMessages(widget.roomId);
    setState(() {
      // 최신 메시지가 위로 오도록 정렬
      _allMessages = messages.reversed.toList();
      _results = _allMessages;
      _isLoading = false;
    });
  }

  void _onQueryChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _results = _allMessages;
      } else {
        _results = _allMessages
            .where((m) => m.text.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectMessage(MessageModel message) {
    Navigator.pop(context, message);
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60)
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24)
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 30)
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: ChatColors.screenBackground(),
            child: SafeArea(
              child: Column(
                children: [
                  _buildSearchBar(),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _results.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 18),
                            itemBuilder: (context, index) =>
                                _resultTile(_results[index]),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // 우측 상단에 겹쳐서 떠 있는 상대방 아바타 버튼.
          // TODO: 탭하면 상대방 프로필 화면으로 이동하도록 연결
          Positioned(
            top: MediaQuery.of(context).padding.top + 46,
            right: 16,
            child: _buildFloatingAvatar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onQueryChanged,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'I want',
                  hintStyle: TextStyle(color: ChatColors.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  suffixIcon: Icon(
                    Icons.search,
                    color: ChatColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultTile(MessageModel message) {
    return GestureDetector(
      onTap: () => _selectMessage(message),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _relativeTime(message.createdAt),
            style: const TextStyle(
              color: ChatColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No matching messages',
        style: TextStyle(color: ChatColors.textSecondary),
      ),
    );
  }

  Widget _buildFloatingAvatar() {
    return GestureDetector(
      onTap: () {
        // TODO: 상대방 프로필 화면 연결
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.blueAccent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: widget.opponentAvatarUrl != null
              ? Image.network(widget.opponentAvatarUrl!, fit: BoxFit.cover)
              : const Icon(Icons.person, color: Colors.blueAccent, size: 22),
        ),
      ),
    );
  }
}
