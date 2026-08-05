import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      // 1. 양옆 여백을 20 -> 36으로 늘려서 네비게이션 바 전체 길이를 짤막하고 콤팩트하게 변경
      padding: EdgeInsets.fromLTRB(36, 0, 36, bottomInset + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: ChatColors.topBarBackground.withOpacity(0.55),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_icons.length, (index) {
                final selected = index == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    // 2. 선택/비선택 탭 내부 패딩 설정
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 16 : 12,
                      vertical: selected ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      // 이미지처럼 선택 탭은 노란 알약 형태, 비선택 탭은 살짝 어두운 원형 배경 적용
                      color: selected
                          ? ChatColors.accentYellow
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icons[index],
                          size: 25, // 3. 아이콘 크기를 기존 20 -> 25로 크게 키움
                          color: selected
                              ? const Color(0xFF241A3D)
                              : ChatColors.textSecondary,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(
                            _labels[index],
                            style: const TextStyle(
                              color: Color(0xFF241A3D),
                              fontSize: 14,
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
        ),
      ),
    );
  }
}
