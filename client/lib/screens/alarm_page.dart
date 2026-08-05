import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 알림 화면 (디자인 시안의 "Alarm").
/// HomePage 상단의 알림 벨 아이콘을 누르면 이 화면으로 이동합니다.
/// 자체 Scaffold를 갖는 별도 페이지입니다 (뒤로가기로 홈으로 복귀).
class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

// 알림 한 건을 나타내는 모델.
// 실제 백엔드 연동 시 lib/models/notification_model.dart 로 옮기고
// fromJson 팩토리를 추가해서 서비스 레이어에서 채워주면 됩니다.
class _NotificationItem {
  final String title;
  final String message;
  final String timeLabel; // 예: "Before 00"

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.timeLabel,
  });
}

class _AlarmPageState extends State<AlarmPage> {
  // TODO: NotificationService.fetchNotifications() 로 교체
  final List<_NotificationItem> _notifications = const [
    _NotificationItem(
      title: 'Point',
      message: 'You spent 10% more than last month!',
      timeLabel: 'Before 00',
    ),
    _NotificationItem(
      title: 'Point',
      message: 'You spent 10% more than last month!',
      timeLabel: 'Before 00',
    ),
    _NotificationItem(
      title: 'Point',
      message: 'You spent 10% more than last month!',
      timeLabel: 'Before 00',
    ),
    _NotificationItem(
      title: 'Point',
      message: 'You spent 10% more than last month!',
      timeLabel: 'Before 00',
    ),
    _NotificationItem(
      title: 'Point',
      message: 'You spent 10% more than last month!',
      timeLabel: 'Before 00',
    ),
    _NotificationItem(
      title: 'Point',
      message: 'You spent 10% more than last month!',
      timeLabel: 'Before 00',
    ),
  ];

  // 알림 리스트 중간에 끼워 넣을 프로모션 배너를 몇 번째 뒤에 표시할지.
  static const int _promoAfterIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: ChatColors.screenBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: _notifications.length + 1, // 프로모션 배너 한 줄 추가
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == _promoAfterIndex + 1) {
                      return _buildPromoBanner();
                    }
                    final itemIndex = index > _promoAfterIndex
                        ? index - 1
                        : index;
                    return _notificationTile(_notifications[itemIndex]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              'Alarm',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // 뒤로가기 버튼과 대칭을 맞추기 위한 여백
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _notificationTile(_NotificationItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 디자인처럼 대비가 강한 흰 원+검은 별 대신 은은한 파스텔 톤 원형 아이콘 사용
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFF6B4E9A),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.timeLabel,
                      style: const TextStyle(
                        color: ChatColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showItemMenu(item),
                      child: const Icon(
                        Icons.more_vert,
                        color: ChatColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: ChatColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // TODO: 인기 상품 TOP 10 화면으로 이동
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            "Check out this week's top 10 hot items",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showItemMenu(_NotificationItem item) {
    // TODO: 알림 개별 항목의 옵션(읽음 처리/삭제 등) 메뉴 구현
    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: ChatColors.danger,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
