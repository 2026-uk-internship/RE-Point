import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 검색 탭 placeholder.
/// TODO: 실제 검색 화면 디자인/기능 구현 시 이 파일 내용을 교체하세요.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ChatColors.screenBackground(),
      child: const SafeArea(
        child: Center(
          child: Text(
            '검색 화면 (구현 예정)',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}