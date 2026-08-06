import 'dart:async';

import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../theme/chat_theme.dart';
import '../widgets/chat_bubble.dart';
import 'chat_room_screen.dart';
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

/// 서버 응답을 기다리는 중인 낙관적(optimistic) 메시지 하나.
/// receive_message로 내가 보낸 메시지가 돌아왔을 때, text로 매칭해서
/// 화면에 미리 그려둔 임시 메시지를 실제 메시지로 교체하는 데 씁니다.
class _PendingOptimistic {
  final String tempId;
  final String text;
  _PendingOptimistic(this.tempId, this.text);
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasLoadError = false; // 메시지 조회 실패 시 재시도 UI를 보여주기 위한 플래그

  final List<_PendingOptimistic> _pending = [];
  StreamSubscription<MessageModel>? _messageSub;

  final GlobalKey _menuButtonKey = GlobalKey();
  OverlayEntry? _menuOverlay;

  @override
  void initState() {
    super.initState();
    _listenIncomingMessages();
    _loadMessages();
  }

  /// 실시간 메시지 수신. 내가 보낸 메시지의 서버 확정본이 오면 낙관적 메시지를
  /// 교체하고, 상대방이 보낸 메시지는 그대로 리스트에 추가합니다.
  void _listenIncomingMessages() {
    _messageSub = _chatService.messageStream.listen((msg) {
      if (!mounted) return;
      setState(() {
        if (msg.isMe && _pending.isNotEmpty) {
          final idx = _pending.indexWhere((p) => p.text == msg.text);
          if (idx != -1) {
            final pending = _pending.removeAt(idx);
            final msgIdx = _messages.indexWhere((m) => m.id == pending.tempId);
            if (msgIdx != -1) {
              _messages[msgIdx] = msg;
            } else {
              _messages.add(msg);
            }
            return;
          }
        }
        _messages.add(msg);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  /// 메시지 목록 조회. 실패(타임아웃/네트워크 오류 등) 시에도
  /// _isLoading이 반드시 해제되도록 try/catch/finally로 감쌈.
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final messages = await _chatService.fetchMessages(widget.roomId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      debugPrint('메시지 조회 실패: $e');
      if (mounted) {
        setState(() => _hasLoadError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

    // 낙관적 업데이트: 서버 응답 기다리지 않고 먼저 화면에 보여줌.
    // 실제 서버 확정본은 _listenIncomingMessages()가 받아서 이 임시 메시지를 교체합니다.
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = MessageModel(
      id: tempId,
      chatRoomId: widget.roomId,
      senderId: ChatService.currentUserId,
      text: text,
      createdAt: DateTime.now(),
      isMe: true,
    );
    _pending.add(_PendingOptimistic(tempId, text));
    setState(() => _messages.add(optimisticMessage));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      await _chatService.sendMessage(roomId: widget.roomId, text: text);
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
    final renderBox =
        _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
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
            child: _ChatOptionsMenu(onSelect: _handleMenuSelect),
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
        // TODO: 일정 관리 화면으로 이동
        break;
      case ChatMenuOption.search:
        // TODO: 채팅 내 검색 UI 열기
        break;
      case ChatMenuOption.mute:
        await _chatService.toggleNotification(widget.roomId, true);
        break;
      case ChatMenuOption.report:
        // TODO: 신고 화면/다이얼로그 열기
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
        title: const Text(
          'Leave chat room',
          style: TextStyle(color: Colors.white),
        ),
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
            child: const Text(
              'Leave',
              style: TextStyle(color: ChatColors.danger),
            ),
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
    _messageSub?.cancel();
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
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _hasLoadError
                    ? _buildLoadErrorView()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) =>
                            ChatBubble(message: _messages[index]),
                      ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// 메시지 조회 실패 시 보여주는 재시도 화면.
  Widget _buildLoadErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: ChatColors.textSecondary,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            '메시지를 불러오지 못했습니다.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadMessages, child: const Text('다시 시도')),
        ],
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
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.1),
            backgroundImage: widget.opponentAvatarUrl != null
                ? NetworkImage(widget.opponentAvatarUrl!)
                : null,
            child: widget.opponentAvatarUrl == null
                ? Text(
                    widget.opponentName.isNotEmpty
                        ? widget.opponentName[0]
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  )
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
                gradient: LinearGradient(
                  colors: [Color(0xFF8E6FE0), Color(0xFF4B3A78)],
                ),
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
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

          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16),
          ],
        ),

        padding: const EdgeInsets.symmetric(vertical: 6),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            _menuItem(
              Icons.event_note_rounded,

              'Doing schedule',

              ChatMenuOption.schedule,
            ),

            _menuItem(
              Icons.search_rounded,

              'Searching for Chat',

              ChatMenuOption.search,
            ),

            _menuItem(
              Icons.notifications_off_rounded,

              'Turn off notifications',

              ChatMenuOption.mute,
            ),

            _menuItem(
              Icons.error_outline_rounded,

              'Report',

              ChatMenuOption.report,
            ),

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

  Widget _menuItem(
    IconData icon,

    String label,

    ChatMenuOption option, {

    Color color = Colors.white,
  }) {
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
