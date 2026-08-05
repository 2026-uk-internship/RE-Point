import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import 'sign_in_page.dart';

/// 앱 최초 진입 시 보여주는 웰컴 화면 ("Welcome to RE Point").
///
/// 배경 사진(backgroundimg.png) 위에 보라색 톤 오버레이를 깔고,
/// 장식용 노란 원 두 개와 타이틀/서브 문구를 얹은 형태입니다.
///
/// [주의] 배경 이미지를 쓰려면 프로젝트에 아래 작업이 필요합니다.
/// 1) assets/images/backgroundimg.png 경로에 이미지 파일을 넣기
/// 2) pubspec.yaml 의 flutter: 섹션에 assets 등록
///      flutter:
///        assets:
///          - assets/images/backgroundimg.png
/// (경로를 다르게 쓰고 싶으면 아래 _backgroundAssetPath 값만 바꾸면 됩니다.)
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const String _backgroundAssetPath = 'assets/images/backgroundimg.png';

  void _goToSignIn(BuildContext context) {
    // TODO: 로그인 상태 확인 로직이 있다면 여기서 분기 처리
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // 디자인이 아직 버튼 없이 화면 전체 탭으로 넘어가는 형태라
        // 우선 화면 전체를 탭하면 로그인 화면으로 이동하도록 연결해뒀습니다.
        // 나중에 버튼이 추가되면 이 GestureDetector는 지우고 버튼의 onPressed로 옮기면 됩니다.
        onTap: () => _goToSignIn(context),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 사진
            Image.asset(
              _backgroundAssetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 아직 이미지를 assets에 등록하지 않았을 때도 화면이 깨지지 않도록 fallback
                return Container(color: ChatColors.topBarBackground);
              },
            ),

            // 보라색 톤 오버레이 (사진 위에 브랜드 컬러를 은은하게 덮어줌)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ChatColors.topBarBackground.withOpacity(0.55),
                    ChatColors.backgroundGradient[1].withOpacity(0.55),
                    ChatColors.topBarBackground.withOpacity(0.75),
                  ],
                ),
              ),
            ),

            // 장식용 원 (오른쪽 위, 화면 밖으로 살짝 걸치도록 배치)
            Positioned(
              top: -70,
              right: -90,
              child: _decorativeCircle(220),
            ),
            // 장식용 원 두 개 (왼쪽 아래, 겹쳐서 배치)
            Positioned(
              bottom: 140,
              left: -60,
              child: _decorativeCircle(160),
            ),
            Positioned(
              bottom: 90,
              left: 10,
              child: _decorativeCircle(120),
            ),

            // 텍스트 콘텐츠
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        children: [
                          TextSpan(text: 'RE ', style: TextStyle(color: Colors.white)),
                          TextSpan(text: 'Point', style: TextStyle(color: ChatColors.accentYellow)),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    const Text(
                      'Every Point, A New Beginning.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(flex: 5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ChatColors.accentYellow.withOpacity(0.6),
          width: 1.2,
        ),
      ),
    );
  }
}