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
      // 좁은 화면(예: S23)에서 선택된 탭의 라벨까지 표시할 때 폭이 부족해
      // 잘리는 문제가 있어 좌우 여백을 24로 줄임
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: SizedBox(
            // Container(및 그 안의 FittedBox)가 높이를 스스로 계산하려다
            // 무한대로 커지는 문제가 있어 여기서 높이를 명확히 고정함.
            height: 64,
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
                  // Expanded로 각 탭이 항상 전체 폭의 1/5씩만 차지하도록 고정.
                  // 이렇게 하면 선택된 탭의 라벨이 길어져도 Row 전체가
                  // 화면 밖으로 넘치는 일이 없음.
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: selected ? 12 : 12,
                            vertical: selected ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? ChatColors.accentYellow
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          // 그래도 폭이 좁아 안 맞으면(작은 기기 등) 자동으로
                          // 살짝 축소해서 절대 잘리지 않도록 FittedBox로 감쌈
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _icons[index],
                                  size: 25,
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
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
