import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import 'alarm_page.dart';
import 'list_for_auction_page.dart';
import 'post_auction_page.dart';
import 'item_detail_page.dart';
import 'auction_detail_page.dart';
import '../services/api_service.dart';
import '../services/current_user.dart';

/// 홈 탭 화면 (디자인 시안의 "mainpage").
///
/// 주의: 이 위젯은 자체 Scaffold를 갖지 않습니다.
/// MainPage(IndexedStack)가 Scaffold + 하단 네비게이션을 담당하고,
/// 이 화면은 그 안의 "홈" 탭 콘텐츠(body)로만 쓰입니다.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// ---------------------------------------------------------------------------
// 더미 데이터 모델
// 실제 백엔드 연동 시 이 클래스들을 lib/models/ 로 옮기고
// fromJson 팩토리를 추가해서 서비스 레이어에서 채워주면 됩니다.
// ---------------------------------------------------------------------------

class _AuctionItem {
  final int id;
  final String title;
  final String price;
  final String timeAgo; // 예: "00:29 left"
  final String? imageUrl;

  const _AuctionItem({
    required this.id,
    required this.title,
    required this.price,
    required this.timeAgo,
    this.imageUrl,
  });
}

class _SecondhandItem {
  final int id;
  final String title;
  final String price;
  final String location;
  String? imageUrl; // 목록 API엔 이미지가 없어서, 상세 API로 나중에 채움

  _SecondhandItem({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    this.imageUrl,
  });
}

class _CommunityPost {
  final String title;
  final String tag;
  final String location;
  final int commentCount;

  const _CommunityPost({
    required this.title,
    required this.tag,
    required this.location,
    required this.commentCount,
  });
}

class _HomePageState extends State<HomePage> {
  // 로그인 사용자 정보 - CurrentUser 캐시가 있으면 그걸 쓰고, 없으면 불러올 때까지 기본값 표시
  String userName = CurrentUser.username ?? 'ANDY';
  String userLocation = CurrentUser.location ?? 'Camden, London';
  int userPoints = CurrentUser.points ?? 0;

  // Writing 버튼을 눌렀을 때 뜨는 "List for Auction / Post Auction" 메뉴 표시 여부.
  bool _isWriteMenuOpen = false;

  bool _isLoadingFeed = true;

  // TODO: 실제 응답 필드명이 다르면 _loadHomeData()의 파싱 부분만 조정
  List<_AuctionItem> trendingAuctions = [];
  List<_SecondhandItem> nearbySecondhand = [];
  List<_CommunityPost> communityPosts = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoadingFeed = true);

    // 프로필 정보가 아직 캐싱 안 되어 있으면 먼저 채워둠
    if (!CurrentUser.isLoaded) {
      await CurrentUser.refresh();
    }
    if (CurrentUser.isLoaded && mounted) {
      setState(() {
        userName = CurrentUser.username ?? userName;
        userLocation = CurrentUser.location ?? userLocation;
        userPoints = CurrentUser.points ?? userPoints;
      });
    }

    // Trending Auctions / Nearby Secondhand / Community를 병렬로 조회
    final results = await Future.wait([
      ProductService.getProductList('auction', sort: 'newest'),
      ProductService.getProductList('general', sort: 'newest'),
      BoardService.getPosts(),
    ], eagerError: false);

    // 실제 서버 응답 구조를 콘솔에서 확인하기 위한 디버그 로그.
    // 필드명이 예상과 다르면 이 로그로 실제 키 이름을 확인해서
    // _parseAuctions / _parseSecondhand 안의 키 이름만 맞춰주면 됩니다.
    debugPrint('🔍 [Home] auction 응답: ${results[0]}');
    debugPrint('🔍 [Home] secondhand 응답: ${results[1]}');

    if (!mounted) return;

    setState(() {
      trendingAuctions = _parseAuctions(results[0]);
      nearbySecondhand = _parseSecondhand(results[1]);
      communityPosts = _parseCommunityPosts(results[2]);
      _isLoadingFeed = false;
    });

    // 목록은 먼저 보여주고, 사진은 상세 API로 백그라운드에서 채워넣음
    // (await 안 함 - 사진 늦게 팝인되는 건 괜찮으니 로딩을 막지 않음)
    _enrichSecondhandImages();
  }

  // 상대경로 이미지에 baseUrl을 붙여주는 헬퍼
  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${ApiConfig.baseUrl}/$raw';
  }

  // 서버 응답 필드명이 정확히 뭔지 몰라서, 흔히 쓰이는 이미지 키를 다 확인.
  // (imgUrl 단일 문자열 / images 리스트(문자열 또는 {url:...} 객체) / thumbnail 등)
  String? _extractRawImage(Map<String, dynamic> e) {
    for (final key in [
      'imgUrl',
      'img_url',
      'image',
      'image_url',
      'thumbnail',
      'thumbnailUrl',
      'thumbnail_url',
      'mainImage',
      'main_image',
      'coverImage',
      'cover_image',
    ]) {
      final v = e[key];
      if (v is String && v.isNotEmpty) return v;
    }
    final images = e['images'] ?? e['product_images'] ?? e['productImages'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map) {
        final url = first['url'] ??
            first['imageUrl'] ??
            first['image_url'] ??
            first['image'] ??
            first['path'];
        if (url is String && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  List<_AuctionItem> _parseAuctions(Map<String, dynamic> res) {
    final rawList = (res['data'] is List) ? res['data'] as List : <dynamic>[];
    final parsed = rawList.map((e) {
      final id = e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}') ?? 0;
      final auction = e['auction'] as Map<String, dynamic>?;
      return _AuctionItem(
        id: id,
        title: e['title']?.toString() ?? '',
        price: 'P ${auction?['start_point'] ?? e['point_price'] ?? 0}',
        timeAgo: auction?['end_date']?.toString() ?? '',
        imageUrl: _resolveImageUrl(_extractRawImage(e)),
      );
    }).toList();

    // 실제 경매 데이터가 아직 없으면(DB 비어있음) 발표용으로 빈 섹션 대신
    // 보여주기용 더미를 채워둠. 실제 데이터가 생기면 이 분기는 자연히 안 탐.
    if (parsed.isEmpty) return _demoAuctions;
    return parsed;
  }

  static const List<_AuctionItem> _demoAuctions = [
    _AuctionItem(id: -1, title: 'Vintage Camera', price: 'P 320', timeAgo: '2h left'),
    _AuctionItem(id: -2, title: 'Leather Jacket', price: 'P 180', timeAgo: '5h left'),
    _AuctionItem(id: -3, title: 'Bluetooth Speaker', price: 'P 95', timeAgo: '1d left'),
  ];

  List<_SecondhandItem> _parseSecondhand(Map<String, dynamic> res) {
    final rawList = (res['data'] is List) ? res['data'] as List : <dynamic>[];
    return rawList.map((e) {
      final id = e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}') ?? 0;
      return _SecondhandItem(
        id: id,
        title: e['title']?.toString() ?? '',
        price: '£${e['price'] ?? 0}', // 실제 목록 API 필드명은 'price' (money_price 아님)
        location: e['location']?.toString() ?? '',
        imageUrl: _resolveImageUrl(_extractRawImage(e)), // 목록 응답엔 보통 없음, 상세 조회로 나중에 채워짐
      );
    }).toList();
  }

  // 목록 API 응답엔 이미지 필드가 없어서, 상품 상세 API를 각각 호출해서
  // 진짜 사진을 채워넣음. (상세 페이지에서는 사진이 잘 뜨는 걸 확인했으므로
  // 같은 파싱 로직을 재사용)
  Future<void> _enrichSecondhandImages() async {
    await Future.wait(
      nearbySecondhand.map((item) async {
        try {
          final res = await ProductService.getProductDetail(item.id);
          final data = (res['data'] is Map<String, dynamic>)
              ? res['data'] as Map<String, dynamic>
              : res;
          final resolved = _resolveImageUrl(_extractRawImage(data));
          if (resolved != null && mounted) {
            setState(() => item.imageUrl = resolved);
          }
        } catch (_) {
          // 개별 상품 이미지 조회 실패는 무시 (그 카드만 아이콘 placeholder로 남음)
        }
      }),
    );
  }

  List<_CommunityPost> _parseCommunityPosts(Map<String, dynamic> res) {
    final rawList = (res['data'] is List) ? res['data'] as List : <dynamic>[];
    return rawList.take(3).map((e) {
      return _CommunityPost(
        title: e['title']?.toString() ?? '',
        tag: e['tag']?.toString() ?? '',
        location: e['location']?.toString() ?? '',
        commentCount: e['commentCount'] is int ? e['commentCount'] as int : 0,
      );
    }).toList();
  }

  void _toggleWriteMenu() {
    setState(() => _isWriteMenuOpen = !_isWriteMenuOpen);
  }

  void _closeWriteMenu() {
    if (_isWriteMenuOpen) setState(() => _isWriteMenuOpen = false);
  }

  // 게시물(경매/중고) 카드를 탭하면 상세 페이지로 이동
  void _navigateToDetail(int productId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailPage(productId: productId),
      ),
    );
  }

  // 경매 상품 카드를 탭하면 경매 전용 상세 페이지로 이동
  void _navigateToAuctionDetail(int auctionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuctionDetailPage(auctionId: auctionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // CustomBottomNav의 실제 배치 방식(bottomInset + 12 여백 + 64 높이)과
    // 맞춰서, 기기의 하단 안전영역(S23 제스처 내비게이션 등)이 커도
    // Writing 버튼이 메뉴바 위쪽에 오도록 동적으로 계산.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBarClearance = bottomInset + 12 + 64; // 메뉴바가 차지하는 하단 높이
    final writeButtonBottom = navBarClearance + 16; // 메뉴바 위 여백
    final writeMenuBottom = writeButtonBottom + 60; // Writing 버튼 위 여백

    return Container(
      decoration: ChatColors.screenBackground(),
      // Stack으로 감싸서 Writing 버튼(및 그 메뉴)이 스크롤되는 리스트와 별개로
      // 화면상 항상 같은 위치에 떠 있도록 함.
      child: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 140), // 하단 네비 + Writing 버튼과 안 겹치도록 여유 공간 확보
              children: [
                _buildTopBar(context),
                const SizedBox(height: 24),
                _buildSectionHeader('Trending Auctions'),
                const SizedBox(height: 12),
                _buildAuctionsList(),
                const SizedBox(height: 24),
                _buildSectionHeader('Nearby Secondhand ($userLocation)'),
                const SizedBox(height: 12),
                _buildSecondhandList(),
                const SizedBox(height: 28),
                // 여기서부터는 스크롤을 해야 보이는 영역 (Community)
                _buildSectionHeader('Community'),
                const SizedBox(height: 12),
                _buildCommunityList(),
              ],
            ),
          ),
          // 스크롤 위치와 무관하게 항상 같은 화면 위치에 떠 있는 Writing 버튼
          Positioned(
            right: 20,
            bottom: writeButtonBottom,
            child: _buildWriteButton(),
          ),
          // Writing 버튼을 눌렀을 때: 배경이 어두워지고 그 위에 선택 메뉴가 뜸
          if (_isWriteMenuOpen) _buildWriteMenuOverlay(writeMenuBottom),
        ],
      ),
    );
  }

  // ----- 상단 인사말 + 포인트 + 알림 -----
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person, color: Colors.white70),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on, color: ChatColors.textSecondary, size: 13),
                  const SizedBox(width: 2),
                  Text(
                    userLocation,
                    style: const TextStyle(color: ChatColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.star_rounded, color: ChatColors.accentYellow, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '$userPoints',
                    style: const TextStyle(
                      color: ChatColors.accentYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildNotificationButton(context),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    // TODO: 안 읽은 알림 개수는 서버/상태관리에서 받아와 뱃지로 표시
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlarmPage()),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: ChatColors.textSecondary, size: 20),
      ],
    );
  }

  // ----- Trending Auctions -----
  Widget _buildAuctionsList() {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: trendingAuctions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _auctionCard(trendingAuctions[index]),
      ),
    );
  }

  Widget _auctionCard(_AuctionItem item) {
    return GestureDetector(
      onTap: item.id >= 0 ? () => _navigateToAuctionDetail(item.id) : null,
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _thumbnail(item.imageUrl, size: 110),
                const Positioned(
                  right: 6,
                  top: 6,
                  child: Icon(Icons.favorite_border, color: Colors.white, size: 16),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.timeAgo,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              item.price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Nearby Secondhand -----
  Widget _buildSecondhandList() {
    return SizedBox(
      height: 180, // 150이었던 걸 늘림 (썸네일130+제목+가격/위치 줄이 150을 넘어서 오버플로우 났었음)
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nearbySecondhand.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _secondhandCard(nearbySecondhand[index]),
      ),
    );
  }

  Widget _secondhandCard(_SecondhandItem item) {
    return GestureDetector(
      onTap: () => _navigateToDetail(item.id),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumbnail(item.imageUrl, size: 130),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  item.price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    item.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: ChatColors.textSecondary, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(String? imageUrl, {required double size}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: imageUrl == null
          ? const Icon(Icons.image_outlined, color: Colors.white30, size: 28)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: size,
              height: size,
              // 이미지 로드 실패해도 빈 박스로 방치하지 않고 아이콘으로 대체
              // (예전엔 DecorationImage라 실패 시 그냥 안 보이기만 했음)
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_outlined,
                color: Colors.white30,
                size: 28,
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white30,
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ----- Writing 버튼 (화면에 고정으로 떠 있음) -----
  // 메뉴가 닫혀있을 땐 노란색 "Writing" 버튼, 열려있을 땐 흰색 X(닫기) 버튼으로 바뀝니다.
  Widget _buildWriteButton() {
    return GestureDetector(
      onTap: _toggleWriteMenu,
      child: _isWriteMenuOpen ? _buildCloseButton() : _buildOpenButton(),
    );
  }

  Widget _buildOpenButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ChatColors.accentYellow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, size: 16, color: Color(0xFF241A3D)),
          SizedBox(width: 6),
          Text(
            'Writing',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF241A3D)),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.close_rounded, color: Color(0xFF241A3D), size: 22),
    );
  }

  // Writing 버튼을 눌렀을 때 화면 전체를 어둡게 덮는 딤 배경 + 그 위에 뜨는 선택 메뉴.
  // 탭하면 각각 Sell Item / Start Auction 화면(현재는 placeholder)으로 이동합니다.
  // 실제 디자인이 나오면 list_for_auction_page.dart / post_auction_page.dart
  // 내용만 교체하면 됩니다.
  Widget _buildWriteMenuOverlay(double menuBottom) {
    return Positioned.fill(
      child: Stack(
        children: [
          // 바깥 영역을 탭하면 닫히는 딤 레이어
          GestureDetector(
            onTap: _closeWriteMenu,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          // Writing 버튼 바로 위에 뜨는 선택 메뉴
          Positioned(
            right: 20,
            bottom: menuBottom,
            // 카드 자체를 탭했을 때는 바깥 딤 레이어로 이벤트가 전달되어 닫히지 않도록 함
            child: GestureDetector(
              onTap: () {},
              child: _writeMenuCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _writeMenuCard() {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xA5A7CBF2), // 요청한 색상 (연한 블루톤, 반투명)
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _writeMenuItem(
            icon: Icons.sell_rounded,
            label: 'Sell Item',
            onTap: () {
              _closeWriteMenu();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostAuctionPage()),
              );
            },
          ),
          const SizedBox(height: 4),
          _writeMenuItem(
            icon: Icons.campaign_rounded,
            label: 'Start Auction',
            onTap: () {
              _closeWriteMenu();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListForAuctionPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _writeMenuItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF6B3F82)),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF3E1F4D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Community -----
  Widget _buildCommunityList() {
    return Column(
      children: communityPosts
          .map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _communityTile(post),
              ))
          .toList(),
    );
  }

  Widget _communityTile(_CommunityPost post) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.forum_rounded, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.mode_comment_outlined, color: ChatColors.textSecondary, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '${post.commentCount}',
                      style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.location,
                      style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}