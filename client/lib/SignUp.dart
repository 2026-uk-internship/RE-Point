import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LoginPage());
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Create your Account",
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const TextField(
                style: const TextStyle(
                  color: Colors.white, // 입력한 글자 색
                ),
                decoration: const InputDecoration(
                  hintText: "Enter your name",
                  hintStyle: TextStyle(
                    color: Colors.white70, // 입력 전 안내 글자 색
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                obscureText: obscurePassword,

                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  hintText: "Enter your password",
                  hintStyle: TextStyle(
                    color: Colors.white70, // 입력 전 안내 글자 색
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
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
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  child: Icon(FontAwesomeIcons.google, color: Colors.white),
                ),

                SizedBox(width: 20),

                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  child: Icon(FontAwesomeIcons.apple, color: Colors.white),
                ),

                SizedBox(width: 20),

                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  child: Icon(FontAwesomeIcons.facebookF, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
