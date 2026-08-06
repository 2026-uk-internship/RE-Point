import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import '../services/api_service.dart';
import 'item_detail_page.dart';

/// 검색 실행 후 나오는 결과 화면.
///
/// 두 개의 탭으로 나뉩니다:
/// - Secondhand: 돈(£)으로 사는 일반 판매 게시물 (type: general / point)
/// - Auctions: 포인트로만 참여 가능한 경매 게시물 (type: auction)
///
/// ⚠️ TODO: SearchService.searchProducts()의 실제 응답 JSON 구조 문서가 없어서,
/// item_detail_page.dart / post_auction_page.dart에서 쓰인 필드명 패턴을 참고해
/// 최대한 추정해서 파싱했습니다. 실행해서 안 맞는 필드가 있으면
/// _SecondhandResult.fromJson / _AuctionResult.fromJson 안의 키 이름만
/// 실제 응답에 맞게 고치면 됩니다.
class SearchResultsPage extends StatefulWidget {
  final String initialQuery;

  const SearchResultsPage({super.key, required this.initialQuery});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SecondhandResult {
  final int id;
  final String title;
  final DateTime? createdAt;
  final int moneyPrice; // 돈(£)
  final int likeCount;
  final int chatCount;
  final String? imageUrl;

  const _SecondhandResult({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.moneyPrice,
    required this.likeCount,
    required this.chatCount,
    this.imageUrl,
  });

  factory _SecondhandResult.fromJson(Map<String, dynamic> e) {
    return _SecondhandResult(
      id: e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}') ?? 0,
      title: (e['title'] ?? '').toString(),
      createdAt: DateTime.tryParse('${e['createdAt'] ?? ''}'),
      moneyPrice: _asInt(e['moneyPrice'] ?? e['money_price'] ?? e['price']),
      likeCount: _asInt(e['likeCount']),
      chatCount: _asInt(e['chatCount'] ?? e['chatRoomCount']),
      imageUrl: _firstImage(e),
    );
  }
}

class _AuctionResult {
  final int id;
  final String title;
  final String location;
  final bool isLive;
  final DateTime? endDate;
  final int currentBid; // 포인트
  final String? imageUrl;

  const _AuctionResult({
    required this.id,
    required this.title,
    required this.location,
    required this.isLive,
    required this.endDate,
    required this.currentBid,
    this.imageUrl,
  });

  factory _AuctionResult.fromJson(Map<String, dynamic> e) {
    final auction = (e['auction'] is Map) ? e['auction'] as Map : const {};
    final endDate = DateTime.tryParse(
      '${auction['endDate'] ?? auction['end_date'] ?? e['endDate'] ?? ''}',
    );
    return _AuctionResult(
      id: e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}') ?? 0,
      title: (e['title'] ?? '').toString(),
      location: (e['location'] ?? '').toString(),
      isLive: (auction['isEnded'] ?? e['isEnded']) != true,
      endDate: endDate,
      currentBid: _asInt(auction['currentBid'] ?? auction['startPoint'] ??
          auction['start_point'] ?? e['pointPrice']),
      imageUrl: _firstImage(e),
    );
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse('$v') ?? 0;
}

String? _firstImage(Map<String, dynamic> e) {
  if (e['imgUrl'] != null) return e['imgUrl'].toString();
  if (e['images'] is List && (e['images'] as List).isNotEmpty) {
    return (e['images'] as List).first.toString();
  }
  return null;
}

String _formatTimeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 1) return '${diff.inDays} days ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'Just now';
}

String _formatTimeLeft(DateTime? end) {
  if (end == null) return '';
  final diff = end.difference(DateTime.now());
  if (diff.isNegative) return 'Ended';
  if (diff.inDays >= 1) return '${diff.inDays}d ${diff.inHours % 24}h left';
  if (diff.inHours >= 1) return '${diff.inHours}h ${diff.inMinutes % 60}m left';
  return '${diff.inMinutes}m left';
}

enum _SecondhandSort { newest, nearest, lowestPrice, highestPrice }

enum _AuctionSort { endingSoon, newest, highestBid, lowestBid }

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final TextEditingController _searchController;

  int _tabIndex = 0; // 0: Secondhand, 1: Auctions
  bool _isLoading = true;
  String? _errorMessage;

  _SecondhandSort _secondhandSort = _SecondhandSort.newest;
  _AuctionSort _auctionSort = _AuctionSort.endingSoon;

  List<_SecondhandResult> _secondhandItems = [];
  List<_AuctionResult> _auctionItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _search(widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await SearchService.searchProducts(trimmed);
      final list = (res['data'] is List) ? res['data'] as List : <dynamic>[];
      final items = list.whereType<Map<String, dynamic>>().toList();

      // type이 'auction'이면 경매, 그 외(general/point 등)는 중고 판매로 분류
      // TODO: 실제 백엔드의 type 값이 다르면 여기 조건만 바꾸면 됨
      final secondhand = items
          .where((e) => e['type'] != 'auction')
          .map(_SecondhandResult.fromJson)
          .toList();
      final auctions = items
          .where((e) => e['type'] == 'auction')
          .map(_AuctionResult.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _secondhandItems = secondhand;
        _auctionItems = auctions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '검색 중 오류가 발생했어요: $e';
        _isLoading = false;
      });
    }
  }

  List<_SecondhandResult> get _sortedSecondhand {
    final list = [..._secondhandItems];
    switch (_secondhandSort) {
      case _SecondhandSort.newest:
        list.sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
        break;
      case _SecondhandSort.lowestPrice:
        list.sort((a, b) => a.moneyPrice.compareTo(b.moneyPrice));
        break;
      case _SecondhandSort.highestPrice:
        list.sort((a, b) => b.moneyPrice.compareTo(a.moneyPrice));
        break;
      case _SecondhandSort.nearest:
        // TODO: 거리순 정렬은 위치 좌표가 필요해서 아직 미구현 (등록순 유지)
        break;
    }
    return list;
  }

  List<_AuctionResult> get _sortedAuctions {
    final list = [..._auctionItems];
    switch (_auctionSort) {
      case _AuctionSort.endingSoon:
        list.sort((a, b) =>
            (a.endDate ?? DateTime(9999)).compareTo(b.endDate ?? DateTime(9999)));
        break;
      case _AuctionSort.newest:
        // TODO: 경매 등록일 필드가 응답에 없으면 id 역순으로 대체
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case _AuctionSort.highestBid:
        list.sort((a, b) => b.currentBid.compareTo(a.currentBid));
        break;
      case _AuctionSort.lowestBid:
        list.sort((a, b) => a.currentBid.compareTo(b.currentBid));
        break;
    }
    return list;
  }

  void _navigateToDetail(int productId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailPage(productId: productId)),
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.white70)),
      );
    }
    return _tabIndex == 0 ? _buildSecondhandList() : _buildAuctionList();
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
                      onSubmitted: (value) => _search(value),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _search(_searchController.text),
                    child: const Icon(Icons.search, color: ChatColors.textSecondary, size: 20),
                  ),
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
    final items = _sortedSecondhand;
    if (items.isEmpty) {
      return const Center(
        child: Text('No results', style: TextStyle(color: ChatColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _secondhandTile(items[index]),
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
                  ? DecorationImage(
                      image: NetworkImage(
                        item.imageUrl!.startsWith('http')
                            ? item.imageUrl!
                            : '${ApiConfig.baseUrl}/${item.imageUrl}',
                      ),
                      fit: BoxFit.cover,
                    )
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
                  _formatTimeAgo(item.createdAt),
                  style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  '£ ${item.moneyPrice}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
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
                '${item.chatCount}',
                style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.chat_bubble_rounded, color: ChatColors.textSecondary, size: 12),
            ],
          ),
        ],
      ),
    );
  }

  // ----- Auctions 리스트 (포인트 P) -----
  Widget _buildAuctionList() {
    final items = _sortedAuctions;
    if (items.isEmpty) {
      return const Center(
        child: Text('No results', style: TextStyle(color: ChatColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _auctionTile(items[index]),
    );
  }

  Widget _auctionTile(_AuctionResult item) {
    return GestureDetector(
      onTap: () => _navigateToDetail(item.id),
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
                      ? DecorationImage(
                          image: NetworkImage(
                            item.imageUrl!.startsWith('http')
                                ? item.imageUrl!
                                : '${ApiConfig.baseUrl}/${item.imageUrl}',
                          ),
                          fit: BoxFit.cover,
                        )
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
                _formatTimeLeft(item.endDate),
                style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'P ${item.currentBid}',
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