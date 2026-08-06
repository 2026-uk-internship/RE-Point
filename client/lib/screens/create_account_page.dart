import 'package:flutter/material.dart';
import 'choose_area_page.dart';
import '../services/api_service.dart';
import '../services/current_user.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreedToTerms = false;
  bool _isSubmitting = false; // 회원가입 API 호출 중 버튼 중복 탭 방지

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ----- 회원가입 API 호출 (성공 시 바로 로그인까지 처리) -----
  Future<void> _handleSignup() async {
    if (_isSubmitting) return;

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final phone = phoneController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      _showError('모든 항목을 입력해주세요.');
      return;
    }
    if (password != confirmPassword) {
      _showError('비밀번호가 일치하지 않아요.');
      return;
    }
    if (!agreedToTerms) {
      _showError('약관에 동의해야 다음으로 진행할 수 있어요.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final signupRes = await AuthService.signup(
        username: username,
        email: email,
        password: password,
        repassword: confirmPassword,
        phone: phone,
      );

      // TODO: 백엔드의 성공 응답 형태(예: {message, data} 등)에 맞춰 성공 판정 조건 조정
      if (signupRes['error'] != null || signupRes['message'] == 'fail') {
        _showError(signupRes['message']?.toString() ?? '회원가입에 실패했어요.');
        return;
      }

      // 가입 직후 바로 로그인해서 토큰을 받아두고, 다음 온보딩 단계로 이동
      final loginRes = await AuthService.login(email, password);
      if (loginRes['token'] == null) {
        // 가입은 됐지만 자동 로그인이 실패한 경우 - 그래도 다음 단계는 진행시켜줌
        _showError('가입은 완료됐어요! 다시 로그인해주세요.');
      } else {
        await CurrentUser.refresh();
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChooseAreaPage()),
      );
    } catch (e) {
      _showError('네트워크 오류가 발생했어요: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 로그인 페이지와 동일한 스타일의 입력창 데코레이션
  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.white38, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
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
          SafeArea(
            child: Column(
              children: [
                // 상단 뒤로가기 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          "Create your Account",
                          style: TextStyle(color: Colors.white, fontSize: 30),
                        ),
                        const SizedBox(height: 32),

                        _label("Username"),
                        const SizedBox(height: 10),
                        TextField(
                          controller: usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _fieldDecoration("Enter your username"),
                        ),
                        const SizedBox(height: 20),

                        _label("Email"),
                        const SizedBox(height: 10),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _fieldDecoration("Enter your email"),
                        ),
                        const SizedBox(height: 20),

                        _label("Password"),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _fieldDecoration("Enter your password").copyWith(
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
                        const SizedBox(height: 20),

                        _label("Confirm your password"),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: _fieldDecoration("Confirm your password")
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _label("Phone number"),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _fieldDecoration("For a safer marketplace"),
                        ),
                        const SizedBox(height: 20),

                        // 약관 동의 문구
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: agreedToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    agreedToTerms = value ?? false;
                                  });
                                },
                                checkColor: const Color.fromRGBO(10, 11, 36, 1),
                                fillColor:
                                    MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Colors.white;
                                  }
                                  return Colors.transparent;
                                }),
                                side: const BorderSide(
                                    color: Colors.white54, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                        text:
                                            "By creating an account, you agree to "),
                                    TextSpan(
                                      text: "the Terms of Service",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextSpan(text: " and "),
                                    TextSpan(
                                      text: "Privacy Policy",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // NEXT 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  const Color.fromRGBO(10, 11, 36, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _isSubmitting ? null : _handleSignup,
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
                                    "NEXT",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
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
    );
  }
}