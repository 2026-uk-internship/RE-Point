import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import '../services/api_service.dart';
import '../services/current_user.dart';
import 'sign_in_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // CurrentUser 캐시로 우선 채우고, 없으면 서버에서 다시 조회
  String userName = CurrentUser.username ?? "Oliver :B";
  String userEmail = CurrentUser.email ?? "";
  int rePoints = CurrentUser.points ?? 0;

  // TODO: 평점/거래 수는 별도 API가 생기면 그걸로 교체 (지금은 profile 응답에 없으면 더미 유지)
  double rating = 4.9;
  int totalTransactions = 18;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    await CurrentUser.refresh();
    if (!mounted) return;
    setState(() {
      userName = CurrentUser.username ?? userName;
      userEmail = CurrentUser.email ?? userEmail;
      rePoints = CurrentUser.points ?? rePoints;
      _isLoading = false;
    });
  }

  Future<void> _handleSignOut() async {
    ApiConfig.clearToken();
    CurrentUser.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 떠 있는 하단 메뉴바(CustomBottomNav)에 마지막 메뉴(Sign Out)가 가려지지
    // 않도록, 기기의 하단 안전영역(S23 제스처 내비게이션 등)을 반영해서
    // 메뉴바가 차지하는 높이만큼 스크롤 콘텐츠 하단에 여유 공간을 둠.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBarClearance = bottomInset + 12 + 64 + 20; // 메뉴바 높이 + 여백

    return Container(
      decoration: ChatColors.screenBackground(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: ChatColors.topBarBackground,
          elevation: 0,
          title: const Text(
            'My Page',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                // TODO: 설정 화면 이동
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, navBarClearance),
            child: Column(
              children: [
                // 1. 프로필 영역 (아바타, 이름, 이메일, 수정 버튼)
                _buildProfileHeader(),
                const SizedBox(height: 20),

                // 2. RE Point 및 통계 카드
                _buildPointStatsCard(),
                const SizedBox(height: 24),

                // 3. 주요 거래 메뉴 (판매, 입찰/구매, 관심목록)
                _buildQuickMenuGrid(),
                const SizedBox(height: 24),

                // 4. 서비스 설정 및 기타 목록
                _buildMenuList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----- 1. 프로필 상단 헤더 -----
  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white.withOpacity(0.15),
              child: const Text(
                'O',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: ChatColors.accentYellow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Color(0xFF241A3D),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userEmail,
          style: const TextStyle(color: ChatColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ----- 2. RE Point 카드 및 거래 통계 -----
  Widget _buildPointStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChatColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RE Point Balance',
                    style: TextStyle(
                      color: ChatColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$rePoints',
                        style: const TextStyle(
                          color: ChatColors.accentYellow,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'P',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChatColors.accentYellow,
                  foregroundColor: const Color(0xFF241A3D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () {
                  // TODO: 포인트 충전/내역 이동
                },
                child: const Text(
                  'Charge',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white12, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Rating', '★ $rating'),
              Container(width: 1, height: 24, color: Colors.white12),
              _buildStatItem('Transactions', '$totalTransactions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: ChatColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ----- 3. 퀵 그리드 메뉴 (내 판매/구매/관심목록) -----
  Widget _buildQuickMenuGrid() {
    return Row(
      children: [
        _buildGridTile(Icons.sell_outlined, 'My Listings', () {}),
        const SizedBox(width: 12),
        _buildGridTile(Icons.shopping_bag_outlined, 'Purchases', () {}),
        const SizedBox(width: 12),
        _buildGridTile(Icons.favorite_border_rounded, 'Favorites', () {}),
      ],
    );
  }

  Widget _buildGridTile(IconData icon, String title, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, color: ChatColors.accentYellow, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- 4. 메뉴 리스트 -----
  Widget _buildMenuList() {
    return Container(
      decoration: BoxDecoration(
        color: ChatColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            Icons.receipt_long_rounded,
            'Transaction History',
            () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            Icons.rate_review_outlined,
            'Reviews & Ratings',
            () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            Icons.notifications_none_rounded,
            'Notifications',
            () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            Icons.help_outline_rounded,
            'Customer Support / FAQ',
            () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            Icons.logout_rounded,
            'Sign Out',
            _handleSignOut,
            textColor: ChatColors.danger,
            iconColor: ChatColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color textColor = Colors.white,
    Color iconColor = Colors.white70,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white30,
        size: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.white12,
      height: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}