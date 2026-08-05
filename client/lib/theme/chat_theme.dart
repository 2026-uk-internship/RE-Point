import 'package:flutter/material.dart';

class ChatColors {
  ChatColors._();

  // 배경 그라데이션 (위 -> 아래 방향)
  static const List<Color> backgroundGradient = [
    Color(0xFF3A2A5E),
    Color(0xFF1C1330),
  ];

  static const Color topBarBackground = Color(0xFF241A3D);
  static const Color cardBackground = Color(0xFF2A2049);

  // 채팅 버블 색상
  static const Color myBubble = Color(0xFF4B3A78);
  static const Color otherBubble = Color(0x33FFFFFF);

  static const Color accentYellow = Color(0xFFF2C744);
  static const Color onlineDot = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE05252); // 채팅방 나가기 등 경고색상

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB9AFD1);

  static BoxDecoration screenBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: backgroundGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }
}
