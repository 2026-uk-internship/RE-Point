import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/chat_theme.dart';
import '../widgets/auction_end_date_picker.dart';
import '../services/api_service.dart';

// 서버에서 내려주는 카테고리 하나 (id + 표시 이름).
class _CategoryOption {
  final int id;
  final String name;
  const _CategoryOption({required this.id, required this.name});
}

/// "Start Auction" 메뉴를 눌렀을 때 뜨는 "Create Auction" (경매 등록) 화면.
class ListForAuctionPage extends StatefulWidget {
  const ListForAuctionPage({super.key});

  @override
  State<ListForAuctionPage> createState() => _ListForAuctionPageState();
}

class _ListForAuctionPageState extends State<ListForAuctionPage> {
  static const int _maxPhotos = 10;
  static const List<String> _locationOptions = [
    'Camden Town',
    'Islington',
    'Hackney',
    'Westminster',
    'Greenwich',
    'Southwark',
  ];
  static const List<String> _meetingOptions = [
    'Public Place',
    'My Location',
    "Buyer's Location",
    'Flexible',
  ];
  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _startingBidController = TextEditingController(text: '10');
  final _buyNowController = TextEditingController(text: '500');

  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  List<_CategoryOption> _categories = [];
  bool _isLoadingCategories = true;
  _CategoryOption? _selectedCategory;
  String _location = 'Camden Town';
  String _meetingPreference = 'Public Place';
  DateTime _auctionEndsAt = DateTime.now().add(const Duration(days: 5));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final res = await CategoryService.getCategories();
      final rawList = (res['data'] is List) ? res['data'] as List : <dynamic>[];
      setState(() {
        _categories = rawList
            .map((e) => _CategoryOption(
                  id: e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}') ?? 0,
                  name: e['name']?.toString() ?? e['title']?.toString() ?? 'Category',
                ))
            .toList();
      });
    } catch (e) {
      // 카테고리 조회 실패 시 빈 목록 - 사용자가 다시 열어서 재시도 가능
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ----- 경매 등록 API 호출 -----
  Future<void> _handlePostListing() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    final startPoint = int.tryParse(_startingBidController.text.trim());

    if (title.isEmpty) {
      _showMessage('제목을 입력해주세요.');
      return;
    }
    if (_selectedCategory == null) {
      _showMessage('카테고리를 선택해주세요.');
      return;
    }
    if (startPoint == null) {
      _showMessage('시작 입찰가를 올바르게 입력해주세요.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await ProductService.createProduct(
        title: title,
        type: 'auction',
        categoryId: _selectedCategory!.id,
        location: _location,
        // TODO: 지도에서 좌표를 선택하는 UI가 생기면 실제 위도/경도로 교체
        latitude: 51.5074,
        longitude: -0.1278,
        startPoint: startPoint,
        endDate: _auctionEndsAt.toIso8601String(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (res['error'] != null) {
        _showMessage(res['message']?.toString() ?? '등록에 실패했어요.');
        return;
      }

      if (!mounted) return;
      _showMessage('경매가 등록됐어요!');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('네트워크 오류가 발생했어요: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _startingBidController.dispose();
    _buyNowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B24),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, 'Create Auction'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _photoPicker(),
                    const SizedBox(height: 24),
                    _label('title'),
                    const SizedBox(height: 8),
                    _pillTextField(
                      controller: _titleController,
                      hint: 'Please enter a title',
                    ),
                    const SizedBox(height: 20),
                    _label('Category'),
                    const SizedBox(height: 8),
                    _categorySelector(),
                    const SizedBox(height: 20),
                    _label('content'),
                    const SizedBox(height: 8),
                    _pillTextField(
                      controller: _contentController,
                      hint: 'Describe your item...\nAvoid profanity or offensive language.',
                      maxLines: 4,
                      borderRadius: 20,
                    ),
                    const SizedBox(height: 24),
                    _label('Starting Bid'),
                    const SizedBox(height: 8),
                    _startingBidBox(),
                    const SizedBox(height: 24),
                    _label('Auction Ends'),
                    const SizedBox(height: 8),
                    _auctionEndsBox(),
                    const SizedBox(height: 28),
                    _label('Trade Settings'),
                    const SizedBox(height: 8),
                    _settingRow(
                      label: 'Location',
                      value: _location,
                      onTap: () => _openOptionPicker(
                        title: 'Location',
                        options: _locationOptions,
                        current: _location,
                        onSelected: (value) => setState(() => _location = value),
                      ),
                    ),
                    _settingRow(
                      label: 'Meeting Preference',
                      value: _meetingPreference,
                      onTap: () => _openOptionPicker(
                        title: 'Meeting Preference',
                        options: _meetingOptions,
                        current: _meetingPreference,
                        onSelected: (value) => setState(() => _meetingPreference = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ----- 사진 선택 -----
  static const double _photoTileSize = 64;
  static const double _photoTileRadius = 16;
  static final BorderRadius _photoTileBorderRadius = BorderRadius.circular(_photoTileRadius);
  static final Color _photoTileBorderColor = Colors.white.withOpacity(0.24);
  static final Color _photoTileBackground = Colors.white.withOpacity(0.08);

  Widget _photoPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._selectedImages.asMap().entries.map(
              (entry) => _photoThumbnail(entry.key, entry.value),
            ),
        if (_selectedImages.length < _maxPhotos) _addPhotoTile(),
      ],
    );
  }

  Widget _addPhotoTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: _photoTileSize,
        height: _photoTileSize,
        decoration: BoxDecoration(
          color: _photoTileBackground,
          borderRadius: _photoTileBorderRadius,
          border: Border.all(color: _photoTileBorderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 22),
            const SizedBox(height: 4),
            Text(
              '${_selectedImages.length}/$_maxPhotos',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoThumbnail(int index, XFile file) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _photoTileSize,
          height: _photoTileSize,
          decoration: BoxDecoration(
            color: _photoTileBackground,
            borderRadius: _photoTileBorderRadius,
            border: Border.all(color: _photoTileBorderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(File(file.path), fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF241A3D),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final remainingSlots = _maxPhotos - _selectedImages.length;
    if (remainingSlots <= 0) return;

    final picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() {
      _selectedImages.addAll(picked.take(remainingSlots));
    });
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ----- 공용 입력 필드 -----
  Widget _pillTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    double borderRadius = 30,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: ChatColors.textSecondary,
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: Colors.white, width: 1.4),
        ),
      ),
    );
  }

  // ----- 카테고리 선택 버튼 -----
  Widget _categorySelector() {
    return GestureDetector(
      onTap: _isLoadingCategories ? null : _openCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          _isLoadingCategories
              ? 'Loading categories...'
              : (_selectedCategory?.name ?? 'Select a category'),
          style: TextStyle(
            color: _selectedCategory != null
                ? Colors.white
                : Colors.white.withOpacity(0.38),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ----- 이미지 스타일 맞춤 카테고리 드롭다운 -----
  void _openCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.only(left: 20, right: 140, bottom: 40, top: 100),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category.id == _selectedCategory?.id;

              return InkWell(
                onTap: () {
                  setState(() => _selectedCategory = category);
                  Navigator.pop(context);
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      // 글자 앞 짝대기 (세로 구분선)
                      Container(
                        width: 2,
                        height: 14,
                        color: isSelected
                            ? const Color(0xFF241A3D)
                            : Colors.grey.withOpacity(0.35),
                      ),
                      const SizedBox(width: 10),
                      // 연한 글자색 카테고리 텍스트
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF241A3D)
                                : const Color(0xFF8E8E93),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ----- Starting Bid / Buy Now 박스 -----
  Widget _startingBidBox() {
    return GestureDetector(
      onTap: _openStartingBidEditor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Point',
                    style: TextStyle(
                      color: ChatColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Starting Bid :  ${_startingBidController.text}p',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Buy Now :  ${_buyNowController.text}p',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ChatColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _openStartingBidEditor() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Starting Bid / Buy Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _label('Starting Bid (P)'),
              const SizedBox(height: 8),
              _pillTextField(controller: _startingBidController, hint: '10'),
              const SizedBox(height: 16),
              _label('Buy Now (P)'),
              const SizedBox(height: 8),
              _pillTextField(controller: _buyNowController, hint: '500'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChatColors.accentYellow,
                    foregroundColor: const Color(0xFF241A3D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(sheetContext);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----- Auction Ends 박스 -----
  Widget _auctionEndsBox() {
    return GestureDetector(
      onTap: _pickAuctionEndDateTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDateTime(_auctionEndsAt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ChatColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAuctionEndDateTime() async {
    final picked = await showAuctionEndDatePicker(
      context,
      initialDateTime: _auctionEndsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked == null || !mounted) return;

    setState(() => _auctionEndsAt = picked);
  }

  String _formatDateTime(DateTime dt) {
    final month = _monthNames[dt.month - 1];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, $hour12:$minute $period';
  }

  // ----- Trade Settings 행 (Location / Meeting Preference) -----
  Widget _settingRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white12),
        ],
      ),
    );
  }

  void _openOptionPicker({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...options.map((option) {
                final isSelected = option == current;
                return ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isSelected
                          ? ChatColors.accentYellow
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ----- 하단 Save Draft / Post Listing 버튼 -----
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              onPressed: () {
                // TODO: 임시저장 API 연결
              },
              child: const Text(
                'Save Draft',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatColors.accentYellow,
                foregroundColor: const Color(0xFF241A3D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              onPressed: _isSubmitting ? null : _handlePostListing,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF241A3D)),
                    )
                  : const Text(
                      'Post Listing',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}