import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 화면 상단에 잠깐 떴다가 자동으로 사라지는 알림 토스트.
///
/// 사용 예 (입찰 성공 시):
///   showTopToast(
///     context,
///     title: 'Bid placed successfully!',
///     subtitle: "You're currently the highest bidder",
///   );
///
/// - SafeArea 아래쪽, 화면 상단에 슬라이드 + 페이드로 나타납니다.
/// - 기본 [duration](3초) 후 자동으로 사라집니다. 사용자가 탭해서 바로
///   닫을 수도 있습니다.
/// - Scaffold의 SnackBar와 달리 Overlay를 직접 사용하므로 화면 맨 위에
///   자유로운 위치(상단 배너 형태)로 띄울 수 있습니다.
void showTopToast(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData icon = Icons.check_circle_rounded,
  Color iconColor = ChatColors.accentYellow,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlayState = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => _TopToast(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
      onFinished: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );

  overlayState.insert(entry);
}

class _TopToast extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Duration duration;
  final VoidCallback onFinished;

  const _TopToast({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.duration,
    required this.onFinished,
    this.subtitle,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    // duration 만큼 떠 있다가 스스로 역재생(사라지는 애니메이션) 후 제거됨
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topInset + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              // 탭하면 3초를 기다리지 않고 바로 닫힘
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF241A3D).withOpacity(0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}