import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../theme/chat_theme.dart';
import '../widgets/chat_bubble.dart';
import 'schedule_page.dart';
import 'chat_search_page.dart';
import 'report_listing_dialog.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final String opponentName;
  final String? opponentAvatarUrl;
  final bool isOpponentOnline;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.opponentName,
    this.opponentAvatarUrl,
    this.isOpponentOnline = false,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  final GlobalKey _menuButtonKey = GlobalKey();
  OverlayEntry? _menuOverlay;
  StreamSubscription<MessageModel>? _incomingSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // 실시간으로 도착하는 메시지를 화면에 반영 (내가 보낸 건 이미 낙관적으로
    // 추가되어 있으므로 상대방이 보낸 것만 추가)
    _incomingSub = _chatService.onMessageReceived.listen((message) {
      if (!mounted) return;
      if (message.chatRoomId != widget.roomId) return;
      if (message.isMe) return;
      setState(() => _messages.add(message));
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final messages = await _chatService.fetchMessages(widget.roomId);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // 낙관적 업데이트: 서버 응답 기다리지 않고 먼저 화면에 보여줌
    final optimisticMessage = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      chatRoomId: widget.roomId,
      senderId: ChatService.currentUserId,
      text: text,
      createdAt: DateTime.now(),
      isMe: true,
    );
    setState(() => _messages.add(optimisticMessage));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      await _chatService.sendMessage(roomId: widget.roomId, text: text);
      // TODO: 실제 서버 응답의 message id로 optimisticMessage 교체
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _toggleMenu() {
    if (_menuOverlay != null) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final renderBox = _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = renderBox.localToGlobal(Offset.zero);

    _menuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 바깥 영역 탭하면 닫히도록 하는 투명 레이어
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: buttonPosition.dy + renderBox.size.height + 6,
            right: 16,
            child: _ChatOptionsMenu(
              onSelect: _handleMenuSelect,
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_menuOverlay!);
  }

  void _closeMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  void _handleMenuSelect(ChatMenuOption option) async {
    _closeMenu();
    switch (option) {
      case ChatMenuOption.schedule:
        final picked = await Navigator.push<DateTime>(
          context,
          MaterialPageRoute(builder: (_) => const SchedulePage()),
        );
        if (picked != null && mounted) {
          // TODO: 선택된 날짜(picked)로 실제 일정 등록 API 연결
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pickup scheduled for ${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
              ),
            ),
          );
        }
        break;
      case ChatMenuOption.search:
        final selectedMessage = await Navigator.push<MessageModel>(
          context,
          MaterialPageRoute(
            builder: (_) => ChatSearchPage(
              roomId: widget.roomId,
              opponentName: widget.opponentName,
              opponentAvatarUrl: widget.opponentAvatarUrl,
            ),
          ),
        );
        if (selectedMessage != null && mounted) {
          // TODO: 선택된 메시지 위치로 스크롤 이동 (메시지 id 기반으로 찾아서 scrollTo)
        }
        break;
      case ChatMenuOption.mute:
        await _chatService.toggleNotification(widget.roomId, true);
        break;
      case ChatMenuOption.report:
        final reasons = await showReportListingDialog(context);
        if (reasons != null && mounted) {
          // TODO: 선택된 reasons로 실제 신고 API 호출
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted')),
          );
        }
        break;
      case ChatMenuOption.leave:
        await _showLeaveConfirmDialog();
        break;
    }
  }

  Future<void> _showLeaveConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChatColors.cardBackground,
        title: const Text('Leave chat room', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to leave this chat room?',
          style: TextStyle(color: ChatColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: ChatColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatService.leaveChatRoom(widget.roomId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _incomingSub?.cancel();
    _closeMenu();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ChatColors.screenBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => ChatBubble(message: _messages[index]),
                      ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(color: ChatColors.topBarBackground),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.maybePop(context),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage:
                widget.opponentAvatarUrl != null ? NetworkImage(widget.opponentAvatarUrl!) : null,
            child: widget.opponentAvatarUrl == null
                ? Text(widget.opponentName.isNotEmpty ? widget.opponentName[0] : '?',
                    style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.opponentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (widget.isOpponentOnline)
                  const Text(
                    'Online',
                    style: TextStyle(color: ChatColors.onlineDot, fontSize: 11),
                  ),
              ],
            ),
          ),
          IconButton(
            key: _menuButtonKey,
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: _toggleMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: const InputDecoration(
                  hintText: 'Your Message...',
                  hintStyle: TextStyle(color: ChatColors.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF8E6FE0), Color(0xFF4B3A78)]),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

enum ChatMenuOption { schedule, search, mute, report, leave }

/// 우측 상단 햄버거 아이콘을 눌렀을 때 뜨는 드롭다운 메뉴.
/// 디자인 시안의 "doing schedule / Searching for Chat / Turn off notifications / Report / Going out to the chat room" 항목 구성.
class _ChatOptionsMenu extends StatelessWidget {
  final ValueChanged<ChatMenuOption> onSelect;

  const _ChatOptionsMenu({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: ChatColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16)],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(Icons.event_note_rounded, 'Doing schedule', ChatMenuOption.schedule),
            _menuItem(Icons.search_rounded, 'Searching for Chat', ChatMenuOption.search),
            _menuItem(Icons.notifications_off_rounded, 'Turn off notifications', ChatMenuOption.mute),
            _menuItem(Icons.error_outline_rounded, 'Report', ChatMenuOption.report),
            _menuItem(
              Icons.logout_rounded,
              'Going out to the chat room',
              ChatMenuOption.leave,
              color: ChatColors.danger,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, ChatMenuOption option, {Color color = Colors.white}) {
    return InkWell(
      onTap: () => onSelect(option),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: color, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}