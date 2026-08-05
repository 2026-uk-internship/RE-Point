import 'package:flutter/material.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'search_page.dart';
import 'chat_list_screen.dart';
import 'my_page.dart';
import '../widgets/custom_bottom_nav.dart';

/// 앱의 메인 셸(shell) 화면.
///
/// 이 화면 하나가 Scaffold를 담당하고,
/// 홈/지도/검색/채팅/마이페이지는 전부 "탭 콘텐츠(body)"로만 존재합니다.
/// (각 탭 화면은 자체 Scaffold나 BottomNavigationBar를 갖지 않아야 합니다 -
///  두 개가 겹치면 네비게이션 바가 중복으로 나옵니다.)
///
/// 하단 네비게이션은 더 이상 Scaffold.bottomNavigationBar가 아니라
/// Stack + Align으로 탭 콘텐츠 위에 "떠 있는" 형태로 겹쳐서 배치합니다
/// (둥글고 반투명한 유리 느낌 디자인을 위함, custom_bottom_nav.dart 참고).
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // 0: 홈, 1: 지도, 2: 검색, 3: 채팅, 4: 마이페이지

  // IndexedStack을 쓰면 탭을 전환해도 각 화면의 상태(스크롤 위치, 검색어 등)가 유지됩니다.
  final List<Widget> _pages = const [
    HomePage(),
    MapPage(),
    SearchPage(),
    ChatListScreen(),
    MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 하단 네비가 콘텐츠 위에 떠 있는 구조이므로 body를 화면 끝까지 확장
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomBottomNav(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}