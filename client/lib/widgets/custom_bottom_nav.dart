import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 홈, 지도, 검색, 채팅, 마이페이지 5개 탭 하단 네비게이션.
///
/// 이미 팀에서 공용 하단 네비게이션 위젯을 만들어뒀다면 이 파일 대신 그걸 쓰시고,
/// 이 파일은 참고용/임시용으로 보시면 됩니다.
class CustomBottomNav extends StatelessWidget {
  final int currentIndex; // 0: 홈, 1: 지도, 2: 검색, 3: 채팅, 4: 마이페이지
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _icons = [
    Icons.home_rounded,
    Icons.map_rounded,
    Icons.search_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  static const _labels = ['Home', 'Map', 'Search', 'Chat', 'My'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ChatColors.topBarBackground,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_icons.length, (index) {
            final selected = index == currentIndex;
            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 10, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? ChatColors.accentYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      _icons[index],
                      size: 20,
                      color: selected ? const Color(0xFF241A3D) : ChatColors.textSecondary,
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      Text(
                        _labels[index],
                        style: const TextStyle(
                          color: Color(0xFF241A3D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}