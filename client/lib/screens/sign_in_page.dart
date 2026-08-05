import 'package:flutter/material.dart';
import 'main_page.dart';
import 'create_account_page.dart';
import '../services/api_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final controller = PageController();
  int currentPage = 0;
  bool obscurePassword = true;
  bool _isSubmitting = false; // 로그인 API 호출 중 버튼 중복 탭 방지

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ----- 로그인 API 호출 -----
  Future<void> _handleLogin() async {
    if (_isSubmitting) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('이메일과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await AuthService.login(email, password);

      // AuthService.login은 statusCode 200 + token이 있을 때만 토큰을 저장함
      if (res['token'] == null) {
        _showError(res['message']?.toString() ?? '이메일 또는 비밀번호를 확인해주세요.');
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } catch (e) {
      _showError('네트워크 오류가 발생했어요: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 소셜 로그인 로고 이미지를 원형 아이콘 형태로 보여주는 헬퍼
  Widget _socialImageIcon(String assetPath) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white12,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            // 1. 메인 슬라이드 (PageView)
            PageView(
              controller: controller,
              onPageChanged: (index) {
                setState(() => currentPage = index);
              },
              children: [
                // 첫 번째 페이지
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(151, 154, 223, 1),
                        Color.fromRGBO(77, 80, 165, 1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const SizedBox(height: 80),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Ready for\nanother owner?",
                            style: TextStyle(color: Colors.white, fontSize: 28),
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: const Alignment(0.4, 0),
                          child: Image.asset("images/BoxImage.png", width: 170),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // 두 번째 페이지
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      // 기본 보라 배경
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(77, 80, 165, 1),
                              Color.fromRGBO(10, 11, 36, 1),
                            ],
                          ),
                        ),
                      ),
                      // 아래에서 검은색이 올라오는 오버레이
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Color(0x6614091F),
                              Color(0xCC14091F),
                            ],
                            stops: [0.0, 0.45, 0.75, 1.0],
                          ),
                        ),
                      ),
                      // 내용
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            const SizedBox(height: 100),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                "Every item deserves\nanother chance.",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              "RE:point",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 세 번째 페이지 (로그인 페이지)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(151, 154, 223, 1),
                              Color.fromRGBO(77, 80, 165, 1),
                              Color.fromRGBO(10, 11, 36, 1),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x6614091F),
                              Color(0xCC14091F),
                              Color(0xFF0A0B24),
                            ],
                            stops: [0.0, 0.25, 0.55, 1.0],
                          ),
                        ),
                      ),
                      // 내용
                      SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 60),
                              const Text(
                                "Log in",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                ),
                              ),
                              const SizedBox(height: 40),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "E-mail",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 이메일 입력창
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Enter your E-mail",
                                  hintStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.08),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Colors.white38,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 비밀번호 입력창
                              TextField(
                                controller: passwordController,
                                obscureText: obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                onSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  hintText: "Enter your password",
                                  hintStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white12,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              // 로그인 버튼
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color.fromRGBO(
                                      10,
                                      11,
                                      36,
                                      1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: _isSubmitting ? null : _handleLogin,
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Color.fromRGBO(10, 11, 36, 1),
                                          ),
                                        )
                                      : const Text(
                                          "Log in",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // 회원가입 및 계정 찾기 링크
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CreateAccountPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Create an account",
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      "/",
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                  const Text(
                                    "Need help signing in?",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // 소셜 로그인 아이콘 목록
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _socialImageIcon("images/google.png"),
                                  _socialImageIcon("images/apple.png"),
                                  _socialImageIcon("images/twitter.png"),
                                ],
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. 상단 인디케이터 바 (Overlay)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Row(
                children: List.generate(3, (index) {
                  final isActive = index == currentPage;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}