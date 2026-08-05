import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 검색 탭 화면 (Search Page).
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _recentSearches = ['pallet', 'paint', 'brush'];

  final List<String> _recommendedTags = [
    'Paints',
    'Winsor & Newton',
    'Reeves',
    'Reeves',
    'Reeves',
    'Michael Harding',
  ];

  final List<_SimilarItem> _similarItems = const [
    _SimilarItem(imageUrl: null),
    _SimilarItem(imageUrl: null),
    _SimilarItem(imageUrl: null),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    _recentSearches.insert(0, value.trim());
                  });
                }
              },
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
            onTap: () {
              setState(() {
                _recentSearches.clear();
              });
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
            (search) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    search,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _recentSearches.remove(search);
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ----- Recommended Tags 목록 -----
  Widget _buildRecommendedTags() {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: _recommendedTags
          .map(
            (tag) => InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                _searchController.text = tag;
              },
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
      onTap: () {
        // TODO: 상품 상세 화면으로 이동
      },
      child: Container(
        width: 120,
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: item.imageUrl != null
            ? Image.network(item.imageUrl!, fit: BoxFit.cover)
            : const Icon(Icons.image, color: Colors.white24, size: 40),
      ),
    );
  }
}

class _SimilarItem {
  final String? imageUrl;
  const _SimilarItem({this.imageUrl});
}
