import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import 'search_results_page.dart';
import 'item_detail_page.dart';
import '../services/api_service.dart';

// 최근 검색어 한 건 (삭제 API 호출에 필요한 id를 함께 들고 있음).
class _RecentSearch {
  final int? id; // 서버에서 내려준 id (로컬에서 막 추가한 경우엔 null일 수 있음)
  final String keyword;
  const _RecentSearch({this.id, required this.keyword});
}

/// 검색 탭 화면 (Search Page).
///
/// Recommended Tags는 최근 검색어가 아니라 "최근에 본 상품들의 카테고리 이름"을 보여줌
/// (GET /products/me/recent/general 응답의 categoryName 필드, 중복 제거).
///
/// ⚠️ TODO: GET /search/recent 응답의 정확한 JSON 필드명이 test.md 문서에 완전히
/// 명시되어 있지 않습니다. 실제 서버 코드(searchModel.getRecentSearches) 기준으로
/// title/searchId를 사용하도록 맞춰뒀습니다.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<_RecentSearch> _recentSearches = [];
  List<String> _recommendedTags = [];
  bool _isLoadingMeta = true;

  List<_SimilarItem> _similarItems = [];
  bool _isLoadingSimilar = true;

  @override
  void initState() {
    super.initState();
    _loadSearchMeta();
    _loadSimilarItems();
  }

  // 서버 응답 한 항목에서 검색어 텍스트를 뽑아냄.
  // DB 컬럼명은 'title'이지만, 혹시 서버가 'keyword'로 매핑해서 줄 수도 있어
  // 둘 다 대응 (title 우선).
  static String _parseKeyword(dynamic e) {
    if (e is String) return e;
    if (e is Map) {
      return (e['title'] ?? e['keyword'] ?? '').toString();
    }
    return e.toString();
  }

  // 실제 서버 응답 필드는 'id'가 아니라 'searchId' (searchModel.getRecentSearches 기준)
  static int? _parseId(dynamic e) {
    if (e is Map && e['searchId'] != null) {
      return e['searchId'] is int
          ? e['searchId'] as int
          : int.tryParse('${e['searchId']}');
    }
    return null;
  }

  // "Similar to your previous items" + "Recommended Tags"
  // 1) GET /products/me/recent/general 로 최근 본 상품 목록 조회
  //    - Recommended Tags: 목록에 포함된 카테고리 이름들(categoryName)을 중복 제거해서 사용
  //    - Similar items: 가장 최근에 본 상품(첫 번째)의 id로 related-category 재조회
  Future<void> _loadSimilarItems() async {
    setState(() => _isLoadingSimilar = true);

    try {
      final recentRes = await ProductService.getRecentGeneral();
      final recentList = (recentRes['data'] is List)
          ? recentRes['data'] as List
          : <dynamic>[];

      // 카테고리 태그: 최근 본 상품들의 categoryName을 중복 없이, 최신순 유지
      final tags = <String>[];
      for (final e in recentList) {
        if (e is Map<String, dynamic>) {
          final name = e['categoryName']?.toString();
          if (name != null && name.isNotEmpty && !tags.contains(name)) {
            tags.add(name);
          }
        }
      }
      if (mounted) {
        setState(() => _recommendedTags = tags);
      }

      if (recentList.isEmpty) {
        if (!mounted) return;
        setState(() {
          _similarItems = [];
          _isLoadingSimilar = false;
        });
        return;
      }

      final latest = recentList.first as Map<String, dynamic>;
      final latestId = latest['id'] is int
          ? latest['id'] as int
          : int.tryParse('${latest['id']}');

      if (latestId == null) {
        if (!mounted) return;
        setState(() {
          _similarItems = [];
          _isLoadingSimilar = false;
        });
        return;
      }

      final relatedRes = await ProductService.getRelatedByCategory(latestId);
      final relatedList = (relatedRes['data'] is List)
          ? relatedRes['data'] as List
          : <dynamic>[];

      if (!mounted) return;
      setState(() {
        _similarItems = relatedList
            .whereType<Map<String, dynamic>>()
            .map(
              (e) => _SimilarItem(
                id: e['id'] is int
                    ? e['id'] as int
                    : int.tryParse('${e['id']}'),
                imageUrl: e['img'] as String?,
              ),
            )
            .toList();
        _isLoadingSimilar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _similarItems = [];
        _isLoadingSimilar = false;
      });
    }
  }

  Future<void> _loadSearchMeta() async {
    setState(() => _isLoadingMeta = true);

    try {
      final res = await SearchService.getRecentSearches();
      final recentRaw = (res['data'] is List)
          ? res['data'] as List
          : <dynamic>[];

      if (!mounted) return;
      setState(() {
        _recentSearches = recentRaw
            .map(
              (e) => _RecentSearch(id: _parseId(e), keyword: _parseKeyword(e)),
            )
            .where((s) => s.keyword.isNotEmpty)
            .toList();

        _isLoadingMeta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMeta = false);
      // 최근 검색어는 화면 진입 시 부가 정보라, 실패해도 검색 자체는
      // 계속 쓸 수 있게 조용히 무시 (빈 목록으로 표시됨)
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.removeWhere((s) => s.keyword == trimmed);
      _recentSearches.insert(0, _RecentSearch(keyword: trimmed));
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(initialQuery: trimmed),
      ),
    );
  }

  Future<void> _removeRecentSearch(_RecentSearch search) async {
    setState(() => _recentSearches.remove(search));
    if (search.id != null) {
      try {
        await SearchService.deleteRecentSearch(search.id!);
      } catch (e) {
        // 삭제 실패해도 화면에서는 이미 지운 채로 둠 (다음 조회 때 서버와 동기화됨)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ChatColors.screenBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildRecentSearchesHeader(),
                const SizedBox(height: 12),
                _buildRecentSearches(),
                const SizedBox(height: 28),
                _buildSectionTitle('Recommended Tags'),
                const SizedBox(height: 12),
                _buildRecommendedTags(),
                const SizedBox(height: 28),
                _buildSectionTitle('Similar to your previous items'),
                const SizedBox(height: 12),
                _buildSimilarItemsRow(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----- 검색창 -----
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white70, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (value) => _runSearch(value),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                setState(() {
                  _searchController.clear();
                });
              },
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
        ],
      ),
    );
  }

  // ----- Section 타이틀 (공통) -----
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ----- Recent Searches 헤더 + clear all 버튼 -----
  Widget _buildRecentSearchesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Searches',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_recentSearches.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final toRemove = List<_RecentSearch>.from(_recentSearches);
              setState(() => _recentSearches.clear());
              // 서버에도 개별 삭제 반영 (id 있는 것만)
              for (final search in toRemove) {
                if (search.id != null) {
                  try {
                    await SearchService.deleteRecentSearch(search.id!);
                  } catch (_) {
                    // 개별 실패는 무시하고 계속 진행
                  }
                }
              }
            },
            child: const Text(
              'clear all',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white54,
              ),
            ),
          ),
      ],
    );
  }

  // ----- Recent Searches 태그목록 -----
  Widget _buildRecentSearches() {
    if (_isLoadingMeta) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
      );
    }

    if (_recentSearches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No recent searches',
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _recentSearches
          .map(
            (search) => GestureDetector(
              onTap: () => _runSearch(search.keyword),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      search.keyword,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeRecentSearch(search),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ----- Recommended Tags 목록 (최근 본 상품의 카테고리) -----
  Widget _buildRecommendedTags() {
    if (_isLoadingSimilar) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
      );
    }

    if (_recommendedTags.isEmpty) {
      return const Text(
        'There are no recently viewed items',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: _recommendedTags
          .map(
            (tag) => InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _runSearch(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Text(
                  '# $tag',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // ----- Similar Items 리스트 -----
  Widget _buildSimilarItemsRow() {
    if (_isLoadingSimilar) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
      );
    }

    if (_similarItems.isEmpty) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: Text(
            "You haven't viewed any products recently",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _similarItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _similarItemThumbnail(_similarItems[index]),
      ),
    );
  }

  Widget _similarItemThumbnail(_SimilarItem item) {
    return GestureDetector(
      onTap: item.id != null
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailPage(productId: item.id!),
                ),
              );
              // 상세 페이지에서 돌아오면 최근 본 목록/태그 다시 불러오기
              if (mounted) {
                _loadSimilarItems();
              }
            }
          : null,
      child: Container(
        width: 120,
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ? Image.network(
                item.imageUrl!.startsWith('http')
                    ? item.imageUrl!
                    : '${ApiConfig.baseUrl}/${item.imageUrl}',
                fit: BoxFit.cover,
              )
            : const Icon(Icons.image, color: Colors.white24, size: 40),
      ),
    );
  }
}

class _SimilarItem {
  final int? id;
  final String? imageUrl;
  const _SimilarItem({this.id, this.imageUrl});
}
