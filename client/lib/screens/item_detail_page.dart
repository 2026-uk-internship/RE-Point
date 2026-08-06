import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import '../services/api_service.dart'; // ApiConfig, ProductService, ProductSocketService 등 import
import 'chat_room_screen.dart';
import '../services/chat_service.dart';

class ItemDetailPage extends StatefulWidget {
  final int productId; // 조회할 상품 ID

  const ItemDetailPage({super.key, required this.productId});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final ProductSocketService _productSocket = ProductSocketService();

  bool _isLoading = true;
  Map<String, dynamic>? _productData;
  bool _isFavorite = false;
  int _likeCount = 0;
  int _chatCount = 0; // 이 게시물로 시작된 채팅방 수 (하트 옆에 함께 표시)

  @override
  void initState() {
    super.initState();
    _fetchProductDetail();
    _connectSocket();
  }

  // 1. 상품 상세 정보 불러오기 API 연동
  Future<void> _fetchProductDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await ProductService.getProductDetail(widget.productId);
      if (res != null) {
        final data = (res['data'] is Map<String, dynamic>)
            ? res['data'] as Map<String, dynamic>
            : res;

        setState(() {
          _productData = data;
          _isFavorite = data['isLiked'] ?? false;
          _likeCount = data['likeCount'] ?? 0;
          // TODO: 백엔드에 채팅방 개수 필드가 확정되면 키 이름 맞춰서 교체
          _chatCount = data['chatCount'] ?? data['chatRoomCount'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('상품 상세 조회 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  // 2. 실시간 상품 시청 소켓 연결 (상세화면 진입/이탈)
  void _connectSocket() {
    try {
      _productSocket.connect();
      _productSocket.joinProduct(productId: widget.productId);
    } catch (e) {
      debugPrint('소켓 연결 실패: $e');
    }
  }

  // 3. 좋아요(찜) 버튼 탭 API 연동
  Future<void> _toggleLike() async {
    final previousState = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
      _likeCount += _isFavorite ? 1 : -1;
    });

    try {
      // 💡 api_service.dart에 실제 존재하는 toggleFavorite 호출!
      final res = await ProductService.toggleFavorite(widget.productId);

      if (res['success'] != true && res['message'] == null) {
        // 실패 시 원래대로 복구
        setState(() {
          _isFavorite = previousState;
          _likeCount += _isFavorite ? 1 : -1;
        });
      }
    } catch (e) {
      // 에러 발생 시 원래대로 복구
      setState(() {
        _isFavorite = previousState;
        _likeCount += _isFavorite ? 1 : -1;
      });
      debugPrint('찜하기 요청 실패: $e');
    }
  }

  // 4. 채팅 시작하기: 서버에 방 생성/조회 요청 → 진짜 roomId로 이동
  bool _isStartingChat = false;

  Future<void> _startChat() async {
    if (_productData == null || _isStartingChat) return;

    final sellerName =
        _productData!['userName'] ??
        _productData!['seller']?['username'] ??
        'Seller';

    setState(() => _isStartingChat = true);

    try {
      final roomId = await ChatService.instance.createOrEnterRoom(
        widget.productId.toString(),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: roomId, // 이미 String
            opponentName: sellerName,
          ),
        ),
      );
    } on ChatServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      debugPrint('채팅방 생성/입장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네트워크 오류로 채팅방을 열 수 없습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  @override
  void dispose() {
    _productSocket.leaveProduct(widget.productId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ChatColors.screenBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: ChatColors.accentYellow,
                ),
              )
            : _productData == null
            ? const Center(
                child: Text(
                  '상품 정보를 불러올 수 없습니다.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : Stack(
                children: [
                  // 1. 스크롤 가능한 본문 영역
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderImage(context),
                        const SizedBox(height: 16),
                        _buildSellerProfile(),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Divider(color: Colors.white12, height: 1),
                        ),
                        _buildItemDetails(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),

                  // 2. 고정 하단 액션 바
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: _buildFixedBottomBar(context),
                  ),
                ],
              ),
      ),
    );
  }

  // ----- 이미지 상단 영역 -----
  Widget _buildHeaderImage(BuildContext context) {
    String? imageUrl;

    if (_productData?['imgUrl'] != null) {
      imageUrl = _productData!['imgUrl'].toString();
    } else if (_productData?['images'] is List &&
        (_productData!['images'] as List).isNotEmpty) {
      imageUrl = _productData!['images'][0].toString();
    }

    return Stack(
      children: [
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl.startsWith('http')
                      ? imageUrl
                      : '${ApiConfig.baseUrl}/$imageUrl',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 60,
                    color: Colors.white24,
                  ),
                )
              : const Icon(
                  Icons.image_outlined,
                  size: 80,
                  color: Colors.white24,
                ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }

  // ----- 판매자 프로필 -----
  Widget _buildSellerProfile() {
    final sellerName =
        _productData?['userName'] ??
        _productData?['seller']?['username'] ??
        'Oliver';
    final location = _productData?['location'] ?? 'London';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Text(
              sellerName.toString().isNotEmpty
                  ? sellerName.toString()[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location.toString(),
                  style: const TextStyle(
                    color: ChatColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildHeartChatCounts(),
        ],
      ),
    );
  }

  // 별점 대신 표시하는 하트(찜) 수 + 채팅 수
  Widget _buildHeartChatCounts() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite_rounded, color: ChatColors.danger, size: 16),
        const SizedBox(width: 4),
        Text(
          '$_likeCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        const Icon(
          Icons.chat_bubble_rounded,
          color: ChatColors.textSecondary,
          size: 15,
        ),
        const SizedBox(width: 4),
        Text(
          '$_chatCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ----- 게시글 내용 -----
  Widget _buildItemDetails() {
    final title = _productData?['title']?.toString() ?? '제목 없음';
    final description =
        _productData?['content']?.toString() ??
        _productData?['description']?.toString() ??
        '';
    final timeAgo = _productData?['createdAt']?.toString() ?? '방금 전';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeAgo,
            style: const TextStyle(
              color: ChatColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ----- 고정 하단 바 -----
  Widget _buildFixedBottomBar(BuildContext context) {
    final price = _productData?['price']?.toString() ?? '0';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ChatColors.cardBackground,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite ? ChatColors.danger : Colors.white70,
              size: 24,
            ),
            onPressed: _toggleLike,
          ),
          const VerticalDivider(
            color: Colors.white24,
            indent: 16,
            endIndent: 16,
            width: 16,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(
                    color: ChatColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '£ $price',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ChatColors.accentYellow,
              foregroundColor: const Color(0xFF241A3D),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: _startChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text(
              'Chatting',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
