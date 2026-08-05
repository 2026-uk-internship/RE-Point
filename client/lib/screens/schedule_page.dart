import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 채팅방 메뉴의 "doing schedule"를 누르면 뜨는 캘린더 화면.
/// 날짜를 하나 선택하고 "Confirm"을 누르면 선택한 DateTime을
/// Navigator.pop(context, selectedDate) 로 돌려줍니다.
///
/// 사용 예 (chat_room_screen.dart 쪽):
///   final picked = await Navigator.push<DateTime>(
///     context,
///     MaterialPageRoute(builder: (_) => const SchedulePage()),
///   );
///   if (picked != null) {
///     // TODO: 선택된 날짜(picked)로 일정 등록 API 호출
///   }
class SchedulePage extends StatefulWidget {
  /// 처음 보여줄 달. 지정하지 않으면 오늘이 속한 달로 시작합니다.
  final DateTime? initialMonth;

  /// 처음부터 선택되어 있을 날짜.
  final DateTime? initialSelectedDate;

  const SchedulePage({
    super.key,
    this.initialMonth,
    this.initialSelectedDate,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime _visibleMonth; // 항상 day=1로 유지
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final baseMonth = widget.initialMonth ?? now;
    _visibleMonth = DateTime(baseMonth.year, baseMonth.month, 1);
    _selectedDate = widget.initialSelectedDate ?? now;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // 달력 그리드에 표시할 날짜 목록 (앞뒤로 이전/다음 달 날짜 포함, 월요일 시작).
  List<DateTime> _buildGridDays() {
    final firstOfMonth = _visibleMonth;
    final firstWeekday = firstOfMonth.weekday; // 1=Mon ... 7=Sun
    final gridStart = firstOfMonth.subtract(Duration(days: firstWeekday - 1));

    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = ((firstWeekday - 1 + daysInMonth) / 7).ceil() * 7;

    return List.generate(totalCells, (index) => gridStart.add(Duration(days: index)));
  }

  String _formatPickupDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final gridDays = _buildGridDays();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B24),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 8),
            _buildMonthHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildDayGrid(gridDays)),
            _buildPickupDateField(),
            const SizedBox(height: 16),
            _buildConfirmButton(),
            const SizedBox(height: 12),
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
              'Pickup Schedule',
              textAlign: TextAlign.center,
              style: TextStyle(
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

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _changeMonth(-1),
            child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
          ),
          Text(
            '${_visibleMonth.month}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () => _changeMonth(1),
            child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 26),
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
          final isCurrentMonth = day.month == _visibleMonth.month;

          if (!isCurrentMonth) {
            // 다른 달의 날짜는 숫자 없이 빈 칸으로 남겨서
            // 이번 달 날짜만 눈에 띄게 표시합니다.
            return const SizedBox.shrink();
          }

          final isSelected = _selectedDate != null && _isSameDay(day, _selectedDate!);

          return GestureDetector(
            onTap: () => _selectDate(day),
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: isSelected
                    ? const BoxDecoration(
                        color: ChatColors.accentYellow,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF241A3D) : Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPickupDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pickup Date',
              style: TextStyle(color: ChatColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              _selectedDate != null ? _formatPickupDate(_selectedDate!) : 'Select a date',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
          onPressed: _selectedDate == null
              ? null
              : () => Navigator.pop(context, _selectedDate),
          child: const Text(
            'Confirm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}