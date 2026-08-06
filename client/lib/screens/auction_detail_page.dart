import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import '../widgets/top_toast.dart';

/// 경매 게시물 상세 화면 ("Live" 뱃지, Place Bid, Bid history, Similar Auctions).
///
/// TODO(백엔드 연동):
/// - initState에서 AuctionService.getAuctionDetail(auctionId) 호출로
///   더미 데이터(_loadDummyData) 대체
/// - Place Bid 성공/실패를 실제 입찰 API 응답으로 처리
/// - 남은 시간(_timeLeft)은 서버의 auctionEndsAt 기준으로 실시간 갱신
class AuctionDetailPage extends StatefulWidget {
  final int auctionId;

  const AuctionDetailPage({super.key, required this.auctionId});

  @override
  State<AuctionDetailPage> createState() => _AuctionDetailPageState();
}

class _BidEntry {
  final String bidderName;
  final int amount;
  final String timeAgo;

  const _BidEntry({
    required this.bidderName,
    required this.amount,
    required this.timeAgo,
  });
}

class _SimilarAuction {
  final int id;
  final String title;
  final int pricePoints;
  final String? imageUrl;

  const _SimilarAuction({
    required this.id,
    required this.title,
    required this.pricePoints,
    this.imageUrl,
  });
}

class _AuctionDetailPageState extends State<AuctionDetailPage> {
  final PageController _imageController = PageController();
  int _imageIndex = 0;

  bool _isLoading = true;
  bool _isFavorite = false;

  // ----- 더미 데이터 (추후 API 응답으로 교체) -----
  List<String?> _images = [null, null, null];
  String _sellerName = 'James';
  String _sellerBadge = 'Leaf';
  String _location = 'Camden, London';
  String _title = 'picture marker';
  String _category = 'Toys & Hobbies';
  String _description =
      'Used only a few times. Most markers work perfectly.\nA few colors may be running low.\nFeel free to ask any questions!';
  bool _isLive = true;
  String _timeLeft = '10h 5m left';

  int _currentBid = 420;
  static const int _bidIncrement = 10;
  int _bidCount = 18;
  int _availablePoints = 460;

  final List<_BidEntry> _bidHistory = const [
    _BidEntry(bidderName: 'Oliver', amount: 420, timeAgo: '5 minutes ago'),
    _BidEntry(bidderName: 'Grace', amount: 410, timeAgo: '22 minutes ago'),
    _BidEntry(bidderName: 'Noah', amount: 390, timeAgo: '1 hour ago'),
    _BidEntry(bidderName: 'James', amount: 370, timeAgo: '3 hours ago'),
  ];

  final List<_SimilarAuction> _similarAuctions = const [
    _SimilarAuction(id: 201, title: 'Marker set', pricePoints: 20),
    _SimilarAuction(id: 202, title: 'Bicycle helmet', pricePoints: 50),
  ];

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  Future<void> _loadDummyData() async {
    // TODO: AuctionService.getAuctionDetail(widget.auctionId)로 교체
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    // TODO: 찜하기 API 연동
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ChatColors.screenBackground(),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageGallery(),
                            const SizedBox(height: 10),
                            _buildImageDots(),
                            const SizedBox(height: 16),
                            _buildSellerRow(),
                            const SizedBox(height: 16),
                            _buildTitleSection(),
                            const SizedBox(height: 16),
                            _buildDescription(),
                            const SizedBox(height: 24),
                            _buildCurrentBidCard(),
                            const SizedBox(height: 20),
                            _buildBidHistoryRow(),
                            _buildDivider(),
                            _buildSimilarAuctionsRow(),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ----- 사진 갤러리 -----
  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleFavorite,
                child: Icon(
                  _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFavorite ? ChatColors.danger : Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _imageController,
            itemCount: _images.length,
            padEnds: false,
            onPageChanged: (index) => setState(() => _imageIndex = index),
            itemBuilder: (context, index) {
              final imageUrl = _images[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 20 : 8,
                  right: index == _images.length - 1 ? 20 : 0,
                ),
                child: Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.72,
                      height: 190,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(18),
                        image: imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl == null
                          ? const Icon(
                              Icons.image_outlined,
                              color: Colors.white30,
                              size: 36,
                            )
                          : null,
                    ),
                    if (index == 0) ...[
                      if (_isLive) _buildLiveBadge(),
                      _buildTimeLeftBadge(),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBadge() {
    return Positioned(
      left: 10,
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
    );
  }

  Widget _buildTimeLeftBadge() {
    return Positioned(
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
          children: [
            const Icon(Icons.access_time_rounded, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(_timeLeft, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_images.length, (index) {
        final isActive = index == _imageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ----- 판매자 정보 -----
  Widget _buildSellerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: Text(
              _sellerName.isNotEmpty ? _sellerName[0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sellerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.eco_rounded, color: ChatColors.accentYellow, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      _sellerBadge,
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

  // ----- 제목 + 위치/카테고리 -----
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: ChatColors.textSecondary, size: 13),
              const SizedBox(width: 3),
              Text(
                _location,
                style: const TextStyle(color: ChatColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.local_offer_outlined, color: ChatColors.textSecondary, size: 13),
              const SizedBox(width: 3),
              Text(
                _category,
                style: const TextStyle(color: ChatColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _description,
        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
      ),
    );
  }

  // ----- 현재 입찰가 카드 + Place Bid 버튼 -----
  Widget _buildCurrentBidCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ChatColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Bid',
                      style: TextStyle(color: ChatColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'P $_currentBid',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: ChatColors.textSecondary, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      '$_bidCount Bids',
                      style: const TextStyle(color: ChatColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChatColors.accentYellow,
                  foregroundColor: const Color(0xFF241A3D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  elevation: 0,
                ),
                onPressed: _openPlaceBidSheet,
                child: const Text('Place Bid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Bid history 진입 행 -----
  Widget _buildBidHistoryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: _openBidHistorySheet,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Bid history',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Icon(Icons.chevron_right_rounded, color: ChatColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Divider(color: Colors.white12, height: 1),
    );
  }

  // ----- Similar Auctions -----
  Widget _buildSimilarAuctionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Similar Auctions',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Icon(Icons.chevron_right_rounded, color: ChatColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _similarAuctions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _similarAuctionTile(_similarAuctions[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _similarAuctionTile(_SimilarAuction item) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AuctionDetailPage(auctionId: item.id)),
        );
      },
      child: SizedBox(
        width: 84,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                image: item.imageUrl != null
                    ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: item.imageUrl == null
                  ? const Icon(Icons.image_outlined, color: Colors.white24, size: 22)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              'P ${item.pricePoints}',
              style: const TextStyle(
                color: ChatColors.accentYellow,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- Bid history 바텀시트 -----
  void _openBidHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bid history',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ..._bidHistory.map(
                  (bid) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bid.bidderName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'P ${bid.amount}',
                          style: const TextStyle(color: ChatColors.accentYellow, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          bid.timeAgo,
                          style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----- Place Bid 바텀시트 -----
  void _openPlaceBidSheet() {
    final minimumBid = _currentBid + _bidIncrement;
    final bidController = TextEditingController(text: '$minimumBid');
    String? errorText;

    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Place Your Bid',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _bidInfoRow('Current Bid', 'P $_currentBid'),
                  const SizedBox(height: 8),
                  _bidInfoRow('Minimum Bid', 'P $minimumBid'),
                  const SizedBox(height: 20),
                  const Text(
                    'Your Bid',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bidController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      prefixText: 'P  ',
                      prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      errorText: errorText,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.white, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _bidInfoRow('Available Points', 'P $_availablePoints'),
                  const SizedBox(height: 12),
                  const Text(
                    'Please review your bid before submitting.\nBids cannot be changed once placed.',
                    style: TextStyle(color: ChatColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ChatColors.accentYellow,
                            foregroundColor: const Color(0xFF241A3D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final entered = int.tryParse(bidController.text.trim());
                            if (entered == null || entered < minimumBid) {
                              setSheetState(() => errorText = 'Bid must be at least P $minimumBid');
                              return;
                            }
                            if (entered > _availablePoints) {
                              setSheetState(() => errorText = 'Not enough points available');
                              return;
                            }
                            Navigator.pop(sheetContext);
                            _placeBid(entered);
                          },
                          child: const Text('Place Bid', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bidInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: ChatColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ----- 입찰 반영 + 상단 성공 토스트 -----
  void _placeBid(int amount) {
    // TODO: 실제 입찰 API 호출로 교체. 실패 시 아래 setState를 롤백하고
    // showTopToast로 실패 메시지를 보여주면 됨.
    setState(() {
      _currentBid = amount;
      _bidCount += 1;
      _availablePoints -= amount;
    });

    showTopToast(
      context,
      title: 'Bid placed successfully!',
      subtitle: "You're currently the highest bidder",
      icon: Icons.check_circle_rounded,
    );
  }
}