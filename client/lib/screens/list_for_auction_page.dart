import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// "Start Auction" 메뉴를 눌렀을 때 뜨는 "Create Auction" (경매 등록) 화면.
///
/// TODO(백엔드 연동):
/// - 사진 선택: image_picker 패키지 붙여서 _selectedImageCount 대신 실제 파일 리스트 관리
/// - Save Draft / Post Listing: 실제 등록 API 연결
class ListForAuctionPage extends StatefulWidget {
  const ListForAuctionPage({super.key});

  @override
  State<ListForAuctionPage> createState() => _ListForAuctionPageState();
}

class _ListForAuctionPageState extends State<ListForAuctionPage> {
  static const int _maxPhotos = 10;
  static const List<String> _categories = [
    'Electronics',
    'Phones & Tablets',
    'Computers',
    'Gaming',
    'Home & Furniture',
    'Home Appliances',
    'Clothing',
    'Beauty & Health',
    'Books & Stationery',
    'Sports & Outdoors',
    'Bicycles',
    'Toys & Hobbies',
    'Baby & Kids',
    'Pets',
    'Automotive',
    'Music & Instruments',
    'Collectibles',
    'Garden & DIY',
    'Food & Drinks',
    'Free Items',
    'Tickets & Events',
    'Services',
    'Other',
  ];
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
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _startingBidController = TextEditingController(text: '10');
  final _buyNowController = TextEditingController(text: '500');

  int _selectedImageCount = 0; // TODO: 실제 선택한 이미지 개수로 교체
  String? _selectedCategory;
  String _location = 'Camden Town';
  String _meetingPreference = 'Public Place';
  DateTime _auctionEndsAt = DateTime.now().add(const Duration(days: 5));

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
      body: Container(
        decoration: ChatColors.screenBackground(),
        child: SafeArea(
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
                        hint:
                            'Describe your item...\nAvoid profanity or offensive language.',
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
                          onSelected: (value) =>
                              setState(() => _location = value),
                        ),
                      ),
                      _settingRow(
                        label: 'Meeting Preference',
                        value: _meetingPreference,
                        onTap: () => _openOptionPicker(
                          title: 'Meeting Preference',
                          options: _meetingOptions,
                          current: _meetingPreference,
                          onSelected: (value) =>
                              setState(() => _meetingPreference = value),
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
  Widget _photoPicker() {
    return GestureDetector(
      onTap: () {
        // TODO: image_picker로 갤러리/카메라 연동, 선택 개수를 _selectedImageCount에 반영
        setState(() {
          if (_selectedImageCount < _maxPhotos) _selectedImageCount++;
        });
      },
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
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white70,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              '$_selectedImageCount/$_maxPhotos',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
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

  // ----- 카테고리 선택 -----
  Widget _categorySelector() {
    return GestureDetector(
      onTap: _openCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          _selectedCategory ?? 'Select a category',
          style: TextStyle(
            color: _selectedCategory != null
                ? Colors.white
                : ChatColors.textSecondary,
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
              final isSelected = category == _selectedCategory;
              return ListTile(
                title: Text(
                  category,
                  style: TextStyle(
                    color: const Color(0xFF4D2A3A),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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
                    setState(() {}); // Starting Bid 박스에 새 값 반영
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _auctionEndsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_auctionEndsAt),
    );
    if (pickedTime == null) return;

    setState(() {
      _auctionEndsAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
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
              onPressed: () {
                // TODO: 등록 API 연결
              },
              child: const Text(
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
