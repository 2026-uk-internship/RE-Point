import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 홈 탭 placeholder.
/// TODO: 실제 홈 화면 디자인/기능 구현 시 이 파일 내용을 교체하세요.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ChatColors.screenBackground(),
      child: const SafeArea(
        child: Center(
          child: Text(
            '홈 화면 (구현 예정)',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}