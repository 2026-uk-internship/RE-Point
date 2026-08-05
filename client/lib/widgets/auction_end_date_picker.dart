import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// "Auction Ends" 필드를 눌렀을 때 여는 날짜/시간 선택 화면.
///
/// 바텀시트가 아니라 별도의 전체 화면(Full page)으로 열립니다.
/// 배경은 앱 공통 그라데이션이 아니라 단색 #0A0B24를 사용합니다.
///
/// 사용 예:
///   final picked = await showAuctionEndDatePicker(
///     context,
///     initialDateTime: _auctionEndsAt,
///   );
///   if (picked != null) setState(() => _auctionEndsAt = picked);
Future<DateTime?> showAuctionEndDatePicker(
  BuildContext context, {
  required DateTime initialDateTime,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return Navigator.push<DateTime>(
    context,
    MaterialPageRoute(
      builder: (context) => AuctionEndDatePage(
        initialDateTime: initialDateTime,
        firstDate: firstDate ?? DateTime.now(),
        lastDate: lastDate ?? DateTime.now().add(const Duration(days: 90)),
      ),
    ),
  );
}

/// 단색 배경(#0A0B24)의 캘린더 화면.
class AuctionEndDatePage extends StatefulWidget {
  final DateTime initialDateTime;
  final DateTime firstDate;
  final DateTime lastDate;

  const AuctionEndDatePage({
    super.key,
    required this.initialDateTime,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<AuctionEndDatePage> createState() => _AuctionEndDatePageState();
}

class _AuctionEndDatePageState extends State<AuctionEndDatePage> {
  static const Color _pageBackground = Color(0xFF0A0B24);

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late DateTime _visibleMonth; // 항상 day=1
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.initialDateTime.year, widget.initialDateTime.month, 1);
    _selectedDate = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime);
  }

  bool get _canGoPrevMonth {
    final prevMonthEnd = DateTime(_visibleMonth.year, _visibleMonth.month, 0);
    return !prevMonthEnd.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month, 1));
  }

  bool get _canGoNextMonth {
    final nextMonthStart = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    return !nextMonthStart.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month, 1));
  }

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSelectable(DateTime day) {
    final first = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !day.isBefore(first) && !day.isAfter(last);
  }

  List<DateTime> _buildGridDays() {
    final firstOfMonth = _visibleMonth;
    final firstWeekday = firstOfMonth.weekday; // 1=Mon ... 7=Sun
    final gridStart = firstOfMonth.subtract(Duration(days: firstWeekday - 1));
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = ((firstWeekday - 1 + daysInMonth) / 7).ceil() * 7;
    return List.generate(totalCells, (index) => gridStart.add(Duration(days: index)));
  }

  Future<void> _pickTime() async {
    // 시간 선택은 우선 기본 TimePicker를 사용합니다.
    // 필요하면 이 부분도 커스텀 휠 UI로 교체할 수 있어요.
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}';

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _confirm() {
    final result = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final gridDays = _buildGridDays();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 4),
            _buildMonthHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildDayGrid(gridDays)),
            _buildInfoColumn(),
            const SizedBox(height: 20),
            _buildConfirmButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Set date',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _canGoPrevMonth ? () => _changeMonth(-1) : null,
            child: Icon(
              Icons.chevron_left_rounded,
              size: 26,
              color: _canGoPrevMonth ? Colors.white : Colors.white24,
            ),
          ),
          Text(
            '${_visibleMonth.month}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          GestureDetector(
            onTap: _canGoNextMonth ? () => _changeMonth(1) : null,
            child: Icon(
              Icons.chevron_right_rounded,
              size: 26,
              color: _canGoNextMonth ? Colors.white : Colors.white24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGrid(List<DateTime> gridDays) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: gridDays.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 14,
        ),
        itemBuilder: (context, index) {
          final day = gridDays[index];
          final isInMonth = day.month == _visibleMonth.month;
          final isSelectable = isInMonth && _isSelectable(day);
          final isSelected = isInMonth && _isSameDay(day, _selectedDate);

          if (!isInMonth) {
            // 다른 달의 날짜는 숫자 없이 빈 칸으로 남겨서
            // 이번 달 날짜만 눈에 띄게 표시합니다.
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: isSelectable ? () => setState(() => _selectedDate = day) : null,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: isSelected
                    ? const BoxDecoration(color: ChatColors.accentYellow, shape: BoxShape.circle)
                    : null,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF241A3D)
                        : isSelectable
                            ? Colors.white
                            : Colors.white24,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _infoBox(label: 'Auction End Date', value: _formatDate(_selectedDate)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickTime,
            child: _infoBox(label: 'End time', value: _formatTime(_selectedTime)),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: ChatColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ChatColors.accentYellow,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          onPressed: _confirm,
          child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}