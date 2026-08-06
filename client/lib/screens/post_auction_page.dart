import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/chat_theme.dart';
import '../services/api_service.dart';

// 서버에서 내려주는 카테고리 하나 (id + 표시 이름).
class _CategoryOption {
  final int id;
  final String name;
  const _CategoryOption({required this.id, required this.name});
}

/// "Sell Item" 메뉴를 눌렀을 때 뜨는 "Create Listing" (일반 판매 등록) 화면.
class PostAuctionPage extends StatefulWidget {
  const PostAuctionPage({super.key});

  @override
  State<PostAuctionPage> createState() => _PostAuctionPageState();
}

class _PostAuctionPageState extends State<PostAuctionPage> {
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

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _priceController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  List<_CategoryOption> _categories = [];
  bool _isLoadingCategories = true;
  _CategoryOption? _selectedCategory;
  String _location = 'Camden Town';
  String _meetingPreference = 'Public Place';
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

  Future<void> _pickImages() async {
    final remainingSlots = _maxPhotos - _selectedImages.length;
    if (remainingSlots <= 0) return;
    final picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() => _selectedImages.addAll(picked.take(remainingSlots)));
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ----- 등록 API 호출 -----
  Future<void> _handlePostListing() async {
    if (_isSubmitting) return;

    final title = _titleController.text.trim();
    final price = int.tryParse(_priceController.text.trim());

    if (title.isEmpty) {
      _showMessage('제목을 입력해주세요.');
      return;
    }
    if (_selectedCategory == null) {
      _showMessage('카테고리를 선택해주세요.');
      return;
    }
    if (price == null) {
      _showMessage('가격을 올바르게 입력해주세요.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await ProductService.createProduct(
        title: title,
        type: 'general',
        categoryId: _selectedCategory!.id,
        location: _location,
        // TODO: 지도에서 좌표를 선택하는 UI가 생기면 실제 위도/경도로 교체
        latitude: 51.5074,
        longitude: -0.1278,
        moneyPrice: price,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (res['error'] != null) {
        _showMessage(res['message']?.toString() ?? '등록에 실패했어요.');
        return;
      }

      if (!mounted) return;
      _showMessage('등록됐어요!');
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
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ChatColors.screenBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context, 'Create Listing'),
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
                      _pillTextField(controller: _titleController, hint: 'Please enter a title'),
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
                      const SizedBox(height: 20),
                      _label('Price'),
                      const SizedBox(height: 8),
                      _priceField(),
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
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
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
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  // ----- 사진 선택 -----
  Widget _photoPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._selectedImages.asMap().entries.map((entry) => _photoThumbnail(entry.key, entry.value)),
        if (_selectedImages.length < _maxPhotos) _addPhotoTile(),
      ],
    );
  }

  Widget _addPhotoTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.24)),
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
              decoration: const BoxDecoration(color: Color(0xFF241A3D), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
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
        hintStyle: const TextStyle(color: ChatColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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

  Widget _priceField() {
    return TextField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixText: '£  ',
        prefixStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        hintText: '000',
        hintStyle: const TextStyle(color: ChatColors.textSecondary, fontSize: 13),
        suffixIcon: const Icon(Icons.chevron_right_rounded, color: ChatColors.textSecondary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 1.4),
        ),
      ),
    );
  }

  // ----- 카테고리 선택 -----
  Widget _categorySelector() {
    return GestureDetector(
      onTap: _isLoadingCategories ? null : _openCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          _isLoadingCategories
              ? 'Loading categories...'
              : (_selectedCategory?.name ?? 'Select a category'),
          style: TextStyle(
            color: _selectedCategory != null ? Colors.white : ChatColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _openCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6D9E4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category.id == _selectedCategory?.id;
              return ListTile(
                title: Text(
                  category.name,
                  style: TextStyle(
                    color: const Color(0xFF4D2A3A),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() => _selectedCategory = category);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  // ----- Trade Settings 행 (Location / Meeting Preference) -----
  Widget _settingRow({required String label, required String value, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              ...options.map((option) {
                final isSelected = option == current;
                return ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? ChatColors.accentYellow : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: () {
                // TODO: 임시저장 API 연결
              },
              child: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.w600)),
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
              onPressed: _isSubmitting ? null : _handlePostListing,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF241A3D)),
                    )
                  : const Text('Post Listing', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}