import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 마이페이지 탭 placeholder.
/// TODO: 실제 마이페이지 디자인/기능(프로필, 설정 등) 구현 시 이 파일 내용을 교체하세요.
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ChatColors.screenBackground(),
      child: const SafeArea(
        child: Center(
          child: Text(
            '마이페이지 (구현 예정)',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}