import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ApiConfig, ProductService, ProductSocketService 등 import
import 'chat_room_screen.dart';
import '../services/chat_service.dart';

// 이 화면 전용 색상 상수.
// 배경 0A0B24 / 하단 고정 카드류 31324C / 하트·채팅 아이콘 흰색
// 카테고리·시간 텍스트 CCCDED / 나머지 텍스트 흰색
class _Design {
  static const bg = Color(0xFF0A0B24);
  static const card = Color(0xFF31324C);
  static const iconWhite = Colors.white;
  static const meta = Color(0xFFCCCDED); // 카테고리 / 시간
  static const text = Colors.white;
  static const danger = Color(0xFFE0577B);
  static const textSecondary = Color(0xFFB9BACD);
}

class ItemDetailPage extends StatefulWidget {
  final int productId; // 조회할 상품 ID

  const ItemDetailPage({super.key, required this.productId});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final ProductSocketService _productSocket = ProductSocketService();
  final PageController _imagePageController = PageController();

  bool _isLoading = true;
  Map<String, dynamic>? _productData;
  bool _isFavorite = false;
  int _likeCount = 0;
  int _chatCount = 0; // 이 게시물로 시작된 채팅방 수
  int _currentImageIndex = 0;
  bool _isStartingChat = false;

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
      final res = await ProductService.toggleFavorite(widget.productId);
      debugPrint('🔍 [Favorite] 응답: $res'); // 실제 성공 판정 조건 확인용

      if (res['success'] != true && res['message'] == null) {
        setState(() {
          _isFavorite = previousState;
          _likeCount += _isFavorite ? 1 : -1;
        });
      }
    } catch (e) {
      setState(() {
        _isFavorite = previousState;
        _likeCount += _isFavorite ? 1 : -1;
      });
      debugPrint('찜하기 요청 실패: $e');
    }
  }

  // 4. 채팅 시작하기: 서버에 방 생성/조회 요청 → 진짜 roomId로 이동
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
          builder: (_) =>
              ChatRoomScreen(roomId: roomId, opponentName: sellerName),
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
    _imagePageController.dispose();
    super.dispose();
  }

  // 이미지 목록 추출: 여러 장('images')이 오면 전부, 아니면 단일 'imgUrl' 하나.
  List<String> get _imageUrls {
    if (_productData?['images'] is List &&
        (_productData!['images'] as List).isNotEmpty) {
      return (_productData!['images'] as List)
          .map((e) => e.toString())
          .toList();
    }
    if (_productData?['imgUrl'] != null) {
      return [_productData!['imgUrl'].toString()];
    }
    return [];
  }

  String _resolveImageUrl(String url) =>
      url.startsWith('http') ? url : '${ApiConfig.baseUrl}/$url';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Design.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _productData == null
            ? const Center(
                child: Text(
                  '상품 정보를 불러올 수 없습니다.',
                  style: TextStyle(color: Colors.white),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 30),
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
                    _buildCategoryAndTimeRow(),
                    const SizedBox(height: 12),
                    _buildItemDetails(),
                    const SizedBox(height: 20),
                    _buildPriceChatCard(),
                    const SizedBox(height: 30),
                    _buildRelatedProductsSection(),
                    const SizedBox(height: 30),
                    _buildSellerItemsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  // ----- 이미지 상단 영역 (캐러셀 + 인디케이터 + 뒤로가기 + 찜 버튼) -----
  Widget _buildHeaderImage(BuildContext context) {
    final images = _imageUrls;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: SizedBox(
            height: 320,
            width: double.infinity,
            child: images.isEmpty
                ? Container(
                    color: Colors.white.withOpacity(0.08),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 80,
                      color: Colors.white24,
                    ),
                  )
                : PageView.builder(
                    controller: _imagePageController,
                    itemCount: images.length,
                    onPageChanged: (index) =>
                        setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      return Container(
                        color: Colors.white.withOpacity(0.08),
                        child: Image.network(
                          _resolveImageUrl(images[index]),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.white24,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // 뒤로가기 버튼
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

        // 찜(하트) 토글 버튼
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black38,
            child: IconButton(
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite ? _Design.danger : Colors.white,
                size: 20,
              ),
              onPressed: _toggleLike,
            ),
          ),
        ),

        // 이미지 여러 장일 때 하단 점 인디케이터
        if (images.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
                final isActive = index == _currentImageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
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
        'Unknown';
    final location = _productData?['location'] ?? '';
    // TODO: 실제 판매자 프로필 이미지 필드명 확인 후 교체
    final avatarUrl =
        _productData?['seller']?['img'] ??
        _productData?['seller']?['profileImage'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.15),
            backgroundImage:
                (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                ? NetworkImage(_resolveImageUrl(avatarUrl.toString()))
                : null,
            child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                ? Text(
                    sellerName.toString().isNotEmpty
                        ? sellerName.toString()[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: _Design.text,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName.toString(),
                  style: const TextStyle(
                    color: _Design.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location.toString(),
                  style: const TextStyle(
                    color: _Design.textSecondary,
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

  // 하트(찜) 수 + 채팅 수 (읽기 전용 통계)
  Widget _buildHeartChatCounts() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite_rounded, color: _Design.danger, size: 16),
        const SizedBox(width: 4),
        Text(
          '$_likeCount',
          style: const TextStyle(
            color: _Design.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        const Icon(
          Icons.chat_bubble_rounded,
          color: _Design.textSecondary,
          size: 15,
        ),
        const SizedBox(width: 4),
        Text(
          '$_chatCount',
          style: const TextStyle(
            color: _Design.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ----- 카테고리 태그 + 작성 시각 (한 줄) -----
  Widget _buildCategoryAndTimeRow() {
    // TODO: 실제 카테고리 필드명 확정되면 교체
    final category =
        _productData?['category']?.toString() ??
        _productData?['categoryName']?.toString();
    final timeAgo = _productData?['createdAt']?.toString() ?? '방금 전';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (category != null && category.isNotEmpty) ...[
            const Icon(Icons.eco_rounded, size: 15, color: _Design.meta),
            const SizedBox(width: 6),
            Text(
              category,
              style: const TextStyle(color: _Design.meta, fontSize: 13),
            ),
          ],
          const Spacer(),
          Text(
            timeAgo,
            style: const TextStyle(color: _Design.meta, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ----- 게시글 내용 (제목 + 설명) -----
  Widget _buildItemDetails() {
    final title = _productData?['title']?.toString() ?? '제목 없음';
    // TODO: 실제 설명 필드명(content/description/contents 등) 확정되면 정리
    final description =
        _productData?['content']?.toString() ??
        _productData?['description']?.toString() ??
        _productData?['contents']?.toString() ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _Design.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                color: _Design.text,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ----- 가격 + 채팅 카드 (스크롤 콘텐츠 안, 플로팅 아님) -----
  Widget _buildPriceChatCard() {
    final price = _productData?['price']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _Design.card,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(color: _Design.text, fontSize: 11),
                  ),
                  Text(
                    '£ $price',
                    style: const TextStyle(
                      color: _Design.text,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _Design.bg,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _isStartingChat ? null : _startChat,
              icon: _isStartingChat
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text(
                'Chatting',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- 연관 상품 섹션 (자리만, 데이터 연동은 다음 단계) -----
  Widget _buildRelatedProductsSection() {
    // TODO: ProductService.getRelatedByCategory(widget.productId) 연동 필요
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Related products',
                style: TextStyle(
                  color: _Design.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _Design.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildPlaceholderCardRow(),
      ],
    );
  }

  // ----- 판매자의 다른 상품 섹션 (자리만, 데이터 연동은 다음 단계) -----
  Widget _buildSellerItemsSection() {
    // TODO: 판매자 다른 상품 조회 API 연동 필요
    final sellerName =
        _productData?['userName'] ?? _productData?['seller']?['username'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$sellerName's items for sale",
                style: const TextStyle(
                  color: _Design.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _Design.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildPlaceholderCardRow(),
      ],
    );
  }

  Widget _buildPlaceholderCardRow() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 110,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, color: Colors.white24, size: 32),
          ),
        ),
      ),
    );
  }
}
