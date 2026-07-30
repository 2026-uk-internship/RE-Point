import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final controller = PageController();

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller,
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

                      Image.asset("images/BoxImage.png", width: 170),

                      const Spacer(),
                    ],
                  ),
                ),
              ),

              // 두 번째 페이지
              Container(
                width: double.infinity,
                height: double.infinity,

                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(77, 80, 165, 1),
                      Color.fromRGBO(10, 11, 36, 1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(30),

                  child: Column(
                    children: [
                      const SizedBox(height: 100),

                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Every item deserves\nanother chance.",
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white, fontSize: 26),
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

                      const Spacer(),
                    ],
                  ),
                ),
              ),

              // 로그인 페이지
              Container(
                width: double.infinity,
                height: double.infinity,

                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(151, 154, 223, 1),
                      Color.fromRGBO(77, 80, 165, 1),
                      Color.fromRGBO(10, 11, 36, 1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),

                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      const Text(
                        "Log in",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 40),

                      TextField(
                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          hintText: "Username",

                          hintStyle: const TextStyle(color: Colors.white70),

                          filled: true,

                          fillColor: Colors.white12,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        obscureText: obscurePassword,

                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          hintText: "Password",

                          hintStyle: const TextStyle(color: Colors.white70),

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

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 페이지 표시
          Positioned(
            top: 60,
            left: 30,
            right: 30,

            child: SmoothPageIndicator(
              controller: controller,

              count: 3,

              effect: const ExpandingDotsEffect(
                activeDotColor: Colors.white,

                dotColor: Colors.white38,

                dotHeight: 6,

                dotWidth: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
