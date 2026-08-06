import 'package:flutter/material.dart';
import '../widgets/onboarding_step_header.dart';
import '../services/api_service.dart';
import '../services/current_user.dart';
import 'sign_in_page.dart';

class PickInterestsPage extends StatefulWidget {
  const PickInterestsPage({super.key});

  @override
  State<PickInterestsPage> createState() => _PickInterestsPageState();
}

class _PickInterestsPageState extends State<PickInterestsPage> {
  static const int maxSelection = 5;

  final List<String> categories = const [
    "Electronics",
    "Phones & Tab",
    "Computers",
    "Gaming",
    "Home & Furniture",
    "Shoes",
    "Home Appliances",
    "Clothing",
    "Bicycles",
    "Toys & Hobbies",
    "Beauty & Health",
    "Books & Stationery",
    "Sports & Outdoor",
    "Automotive",
    "Musical Instruments",
    "Pets",
    "Garden & DIY",
    "Food & Drinks",
    "Free Items",
    "Tickets & Events",
    "Furniture",
    "Other",
  ];

  final Set<String> selected = {};

  void _toggle(String category) {
    setState(() {
      if (selected.contains(category)) {
        selected.remove(category);
      } else if (selected.length < maxSelection) {
        selected.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14091F),
      body: SafeArea(
        child: Column(
          children: [
            OnboardingStepHeader(
              totalSteps: 3,
              currentStep: 3,
              title: "Pick your interests",
              onNext: () {
                // 온보딩(지역 선택 + 관심사 선택) 완료 후에는 홈으로 바로 보내지 않고,
                // 가입 때 자동으로 로그인된 상태를 정리한 뒤 로그인 화면으로 돌려보냄.
                // (뒤로가기로 온보딩에 못 돌아오도록 스택은 통째로 교체)
                ApiConfig.clearToken();
                CurrentUser.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                  (route) => false,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Please select up to $maxSelection",
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categories.map((category) {
                    final isSelected = selected.contains(category);
                    return GestureDetector(
                      onTap: () => _toggle(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.white24,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF14091F)
                                : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}