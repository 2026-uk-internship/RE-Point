import 'package:flutter/material.dart';

/// 디자인 시안의 보라색 계열 배경/버블 색상을 상수로 관리합니다.
/// 다른 화면(홈, 지도, 검색, 마이페이지)에서도 통일된 컬러를 쓰고 싶다면
/// 이 파일을 공용 theme 폴더로 옮겨서 재사용하세요.
class ChatColors {
  ChatColors._();

  // 배경 그라데이션 (좌측 어두운 남색 -> 중앙 밝은 보라 -> 우측 어두운 남색)
  static const List<Color> backgroundGradient = [
    Color(0xFF1C1330),
    Color(0xFF3A2A5E),
    Color(0xFF1C1330),
  ];
  

  static const Color topBarBackground = Color(0xFF241A3D);
  static const Color cardBackground = Color(0xFF2A2049);

  // 내가 보낸 메시지 버블
  static const Color myBubble = Color(0xFF4B3A78);
  // 상대방이 보낸 메시지 버블
  static const Color otherBubble = Color(0x33FFFFFF); // 반투명 흰색

  static const Color accentYellow = Color(0xFFF2C744); // 하단 인디케이터 바
  static const Color onlineDot = Color(0xFF4CAF50);
  static const Color danger = Color(0xFFE05252); // 채팅방 나가기 등 위험 항목

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB9AFD1);

  static BoxDecoration screenBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: backgroundGradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }
}