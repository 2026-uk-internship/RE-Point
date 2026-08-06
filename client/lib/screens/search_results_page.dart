import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import 'item_detail_page.dart';
import 'auction_detail_page.dart';
import '../services/api_service.dart';

/// 검색 실행 후 나오는 결과 화면.
///
/// 두 개의 탭으로 나뉩니다:
/// - Secondhand: 일반 중고 판매 게시물. 돈(£)으로 구매.
/// - Auctions: 경매 게시물. 포인트(P)로만 참여 가능.
///
/// TODO(백엔드 연동): SearchService.search(query, tab, sort) 같은 API로
/// 교체하고, _secondhandItems / _auctionItems를 실제 응답으로 채우면 됩니다.
class SearchResultsPage extends StatefulWidget {
  final String initialQuery;

  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

// ---------------------------------------------------------------------------
// 더미 데이터 모델
// ---------------------------------------------------------------------------

class _SecondhandResult {
  final int id;
  final String title;
  final String timeAgo;
  final String price; // 예: "£ 5" (돈)
  final int likeCount;
  final int commentCount;
  final String? imageUrl;

  const _SecondhandResult({
    required this.id,
    required this.title,
    required this.timeAgo,
    required this.price,
    required this.likeCount,
    required this.commentCount,
    this.imageUrl,
  });
}

class _AuctionResult {
  final int id;
  final String title;
  final String location;
  final bool isLive;
  final String timeLeft;
  final int pricePoints; // 포인트로만 참여 가능
  final String? imageUrl;

  const _AuctionResult({
    required this.id,
    required this.title,
    required this.location,
    required this.isLive,
    required this.timeLeft,
    required this.pricePoints,
    this.imageUrl,
  });
}

enum _SecondhandSort { newest, nearest, lowestPrice, highestPrice }

enum _AuctionSort { endingSoon, newest, highestBid, lowestBid }

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final TextEditingController _searchController;

  // 0: Secondhand, 1: Auctions
  int _tabIndex = 0;

  _SecondhandSort _secondhandSort = _SecondhandSort.newest;
  _AuctionSort _auctionSort = _AuctionSort.endingSoon;

  bool _isLoading = true;

  // TODO: 실제 응답 필드명이 다르면 _runSearch()의 파싱 부분만 조정
  List<_SecondhandResult> _secondhandItems = [];
  List<_AuctionResult> _auctionItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _runSearch(widget.initialQuery);
  }

  Future<void> _runSearch(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final res = await SearchService.searchProducts(trimmed);
      final rawList = (res['data'] is List) ? res['data'] as List : <dynamic>[];

      final secondhand = <_SecondhandResult>[];
      final auctions = <_AuctionResult>[];

      for (final e in rawList) {
        final id = e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}') ?? 0;
        final images = e['images'];
        final imageUrl = (images is List && images.isNotEmpty) ? images[0]?.toString() : null;
        final type = e['type']?.toString();

        if (type == 'auction') {
          final auction = e['auction'] as Map<String, dynamic>?;
          auctions.add(_AuctionResult(
            id: id,
            title: e['title']?.toString() ?? '',
            location: e['location']?.toString() ?? '',
            isLive: true,
            timeLeft: auction?['end_date']?.toString() ?? '',
            pricePoints: auction?['start_point'] is int ? auction!['start_point'] as int : 0,
            imageUrl: imageUrl,
          ));
        } else {
          secondhand.add(_SecondhandResult(
            id: id,
            title: e['title']?.toString() ?? '',
            timeAgo: e['createdAt']?.toString() ?? '',
            price: '£ ${e['money_price'] ?? e['point_price'] ?? 0}',
            likeCount: e['likeCount'] is int ? e['likeCount'] as int : 0,
            commentCount: e['commentCount'] is int ? e['commentCount'] as int : 0,
            imageUrl: imageUrl,
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _secondhandItems = secondhand;
        _auctionItems = auctions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToDetail(int productId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailPage(productId: productId)),
    );
  }

  // 경매 게시물은 입찰(Place Bid) UI가 있는 전용 화면으로 이동
  void _navigateToAuctionDetail(int auctionId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuctionDetailPage(auctionId: auctionId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ChatColors.screenBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 6),
              _buildTabs(),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : (_tabIndex == 0 ? _buildSecondhandList() : _buildAuctionList()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- 상단 검색창 -----
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: ChatColors.textSecondary),
                      ),
                      onSubmitted: (value) => _runSearch(value),
                    ),
                  ),
                  const Icon(Icons.search, color: ChatColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----- Secondhand / Auctions 탭 -----
  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tabLabel('Secondhand', 0),
        const SizedBox(width: 36),
        _tabLabel('Auctions', 1),
      ],
    );
  }

  Widget _tabLabel(String label, int index) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : ChatColors.textSecondary,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 28,
            height: 2,
            color: selected ? ChatColors.accentYellow : Colors.transparent,
          ),
        ],
      ),
    );
  }

  // ----- 정렬/필터 칩 -----
  Widget _buildFilterChips() {
    if (_tabIndex == 0) {
      final options = <_SecondhandSort, String>{
        _SecondhandSort.newest: 'Newest',
        _SecondhandSort.nearest: 'Nearest',
        _SecondhandSort.lowestPrice: 'Lowest Price',
        _SecondhandSort.highestPrice: 'Highest Price',
      };
      return _chipRow(
        children: options.entries
            .map((entry) => _filterChip(
                  label: entry.value,
                  selected: _secondhandSort == entry.key,
                  onTap: () => setState(() => _secondhandSort = entry.key),
                ))
            .toList(),
      );
    } else {
      final options = <_AuctionSort, String>{
        _AuctionSort.endingSoon: 'Ending Soon',
        _AuctionSort.newest: 'Newest',
        _AuctionSort.highestBid: 'Highest Bid',
        _AuctionSort.lowestBid: 'Lowest Bid',
      };
      return _chipRow(
        children: options.entries
            .map((entry) => _filterChip(
                  label: entry.value,
                  selected: _auctionSort == entry.key,
                  onTap: () => setState(() => _auctionSort = entry.key),
                ))
            .toList(),
      );
    }
  }

  Widget _chipRow({required List<Widget> children}) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF241A3D) : Colors.white70,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ----- Secondhand 리스트 (돈 £) -----
  Widget _buildSecondhandList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _secondhandItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _secondhandTile(_secondhandItems[index]),
    );
  }

  Widget _secondhandTile(_SecondhandResult item) {
    return GestureDetector(
      onTap: () => _navigateToDetail(item.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
              image: item.imageUrl != null
                  ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: item.imageUrl == null
                ? const Icon(Icons.image_outlined, color: Colors.white30, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.timeAgo,
                  style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${item.likeCount}',
                    style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.favorite, color: ChatColors.danger, size: 12),
                  const SizedBox(width: 8),
                  Text(
                    '${item.commentCount}',
                    style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.mode_comment_outlined, color: ChatColors.textSecondary, size: 12),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----- Auctions 리스트 (포인트 P) -----
  Widget _buildAuctionList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _auctionItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _auctionTile(_auctionItems[index]),
    );
  }

  Widget _auctionTile(_AuctionResult item) {
    return GestureDetector(
      onTap: () => _navigateToAuctionDetail(item.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(18),
                  image: item.imageUrl != null
                      ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: item.imageUrl == null
                    ? const Icon(Icons.image_outlined, color: Colors.white30, size: 36)
                    : null,
              ),
              if (item.isLive)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.circle, color: ChatColors.danger, size: 8),
                        SizedBox(width: 4),
                        Text('Live', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, color: ChatColors.textSecondary, size: 12),
              const SizedBox(width: 2),
              Text(
                item.location,
                style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
              ),
              const Spacer(),
              const Icon(Icons.access_time_rounded, color: ChatColors.textSecondary, size: 12),
              const SizedBox(width: 2),
              Text(
                item.timeLeft,
                style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'P ${item.pricePoints}',
            // 경매는 돈이 아니라 포인트로만 참여 가능하다는 걸 색으로도 구분
            style: const TextStyle(
              color: ChatColors.accentYellow,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}