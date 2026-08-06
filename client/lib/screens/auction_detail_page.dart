import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import '../widgets/top_toast.dart';
import '../services/api_service.dart';
import '../services/current_user.dart';

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

  // ----- 실제 데이터로 채워짐 (초기값은 로딩 중 표시용 placeholder) -----
  List<String?> _images = [null];
  String _sellerName = 'James';
  String _sellerBadge = 'Leaf';
  String _location = 'Camden, London';
  String _title = 'picture marker';
  String _category = 'Toys & Hobbies';
  String _description =
      'Used only a few times. Most markers work perfectly.\nA few colors may be running low.\nFeel free to ask any questions!';
  bool _isLive = true;
  String _timeLeft = '10h 5m left';

  int _currentBid = 0;
  static const int _bidIncrement = 10;
  int _bidCount = 0;
  int _availablePoints = 0;

  List<_BidEntry> _bidHistory = [];

  List<_SimilarAuction> _similarAuctions = [];

  @override
  void initState() {
    super.initState();
    _loadAuctionDetail();
  }

  // TODO(백엔드 확인 필요): 아래 필드명들은 서버 실제 응답을 보고 확정된 게 아니라
  // 그럴듯한 이름들로 defensive하게 추측한 것입니다. 실제 응답과 다르면
  // 이 함수 안의 키 이름만 맞춰주면 됩니다.
  Future<void> _loadAuctionDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await ProductService.getAuctionDetail(widget.auctionId);
      final data = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : res;

      final images = _extractImages(data);
      final currentBid = data['currentBid'] ??
          data['current_point'] ??
          data['currentPoint'] ??
          data['startPoint'] ??
          data['start_point'] ??
          0;
      final bidCount = data['bidCount'] ?? data['bid_count'] ?? 0;

      // 참여자 목록을 입찰 내역으로 사용 (전용 bid-history API가 아직 없음)
      List<_BidEntry> bidHistory = [];
      try {
        final participantsRes =
            await ProductService.getAuctionParticipants(widget.auctionId);
        final participantsData = participantsRes['data'] ?? participantsRes;
        if (participantsData is List) {
          bidHistory = participantsData
              .map((p) => _bidEntryFromJson(p as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('입찰 참여자 조회 실패: $e');
      }

      if (!mounted) return;
      setState(() {
        _images = images.isNotEmpty ? images : [null];
        _sellerName = (data['userName'] ?? data['seller']?['username'] ?? 'Seller').toString();
        _sellerBadge = (data['sellerBadge'] ?? 'Leaf').toString();
        _location = (data['location'] ?? '').toString();
        _title = (data['title'] ?? '제목 없음').toString();
        _category = (data['category'] ?? data['categoryName'] ?? '').toString();
        _description = (data['content'] ?? data['description'] ?? data['contents'] ?? '').toString();
        _isFavorite = data['isLiked'] == true;
        _timeLeft = _formatTimeLeft(data['endDate'] ?? data['end_date']);
        _isLive = _timeLeft != 'Ended';
        _currentBid = currentBid is int ? currentBid : int.tryParse('$currentBid') ?? 0;
        _bidCount = bidCount is int ? bidCount : int.tryParse('$bidCount') ?? 0;
        _availablePoints = CurrentUser.points ?? 0;
        _bidHistory = bidHistory;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('경매 상세 조회 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String?> _extractImages(Map<String, dynamic> data) {
    if (data['images'] is List && (data['images'] as List).isNotEmpty) {
      return (data['images'] as List).map((e) => e.toString()).toList();
    }
    if (data['imgUrl'] != null) {
      return [data['imgUrl'].toString()];
    }
    return [];
  }

  _BidEntry _bidEntryFromJson(Map<String, dynamic> json) {
    final rawTime = (json['createdAt'] ?? json['timeAgo'] ?? '').toString();
    final parsedTime = DateTime.tryParse(rawTime);
    return _BidEntry(
      bidderName: (json['userName'] ?? json['username'] ?? 'Bidder').toString(),
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse('${json['amount'] ?? json['bidAmount'] ?? 0}') ?? 0,
      timeAgo: parsedTime != null ? _relativeTime(parsedTime) : rawTime,
    );
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  // endDate 문자열을 "10h 5m left" 같은 형태로 변환.
  String _formatTimeLeft(dynamic endDateRaw) {
    if (endDateRaw == null) return '';
    final endDate = DateTime.tryParse(endDateRaw.toString());
    if (endDate == null) return '';
    final remaining = endDate.difference(DateTime.now());
    if (remaining.isNegative) return 'Ended';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return '${hours}h ${minutes}m left';
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      final res = await ProductService.toggleFavorite(widget.auctionId);
      final data = res['data'];
      if (data is Map && data['favorited'] != null) {
        setState(() => _isFavorite = data['favorited'] as bool);
      }
    } catch (e) {
      setState(() => _isFavorite = previousState);
      debugPrint('찜하기 요청 실패: $e');
    }
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
  // TODO(백엔드 요청 필요): 입찰을 "제출"하는 API/소켓 이벤트가 아직 없습니다.
  // (getAuctionDetail, getAuctionParticipants는 조회용일 뿐 입찰 제출용이 아님)
  // 지금은 화면에서만 낙관적으로 반영하고 서버에는 아무것도 보내지 않습니다.
  // 백엔드팀에 "입찰 제출" 엔드포인트(예: POST /products/auctions/:id/bids
  // 또는 소켓 place_bid 이벤트)가 추가되면 여기서 실제로 호출해야 합니다.
  void _placeBid(int amount) {
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