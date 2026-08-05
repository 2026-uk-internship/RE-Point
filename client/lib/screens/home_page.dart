import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import 'alarm_page.dart';
import 'list_for_auction_page.dart';
import 'post_auction_page.dart';
import 'item_detail_page.dart';

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
  final String? imageUrl;

  const _SecondhandItem({
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
  // TODO: 실제 로그인 사용자 정보로 교체
  final String userName = 'ANDY';
  final String userLocation = 'Camden, London';
  final int userPoints = 50;

  // Writing 버튼을 눌렀을 때 뜨는 "List for Auction / Post Auction" 메뉴 표시 여부.
  bool _isWriteMenuOpen = false;

  // TODO: HomeService.fetchTrendingAuctions() 등으로 교체
  final List<_AuctionItem> trendingAuctions = const [
    _AuctionItem(id: 1, title: 'Animal book', price: 'P 10', timeAgo: '00:29 left'),
    _AuctionItem(id: 2, title: 'CRAFFAS', price: 'P 25', timeAgo: '01:23 left'),
    _AuctionItem(id: 3, title: 'fine paint', price: 'P 100', timeAgo: '02:40 left'),
    _AuctionItem(id: 4, title: 'shirts', price: 'P 50', timeAgo: '04:32 left'),
  ];

  final List<_SecondhandItem> nearbySecondhand = const [
    _SecondhandItem(id: 10, title: 'Art marker', price: '£10', location: 'London Camden'),
    _SecondhandItem(id: 11, title: 'uniform shirt', price: '£3', location: 'London Camden'),
    _SecondhandItem(id: 12, title: 'Bike', price: '£0', location: 'London Camden'),
  ];

  final List<_CommunityPost> communityPosts = const [
    _CommunityPost(
      title: 'Discipline for using profanity',
      tag: 'RULE',
      location: 'Head office',
      commentCount: 28,
    ),
    _CommunityPost(
      title: 'Tips for earning points',
      tag: 'TIP',
      location: 'London',
      commentCount: 9,
    ),
    _CommunityPost(
      title: "This month's event schedule",
      tag: 'EVENT',
      location: 'Head office',
      commentCount: 4,
    ),
  ];

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
      onTap: () => _navigateToDetail(item.id),
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
      height: 150,
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
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? const Icon(Icons.image_outlined, color: Colors.white30, size: 28)
          : null,
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