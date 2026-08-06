import 'package:flutter/material.dart';
import '../widgets/onboarding_step_header.dart';
import 'main_page.dart';
import '../services/api_service.dart';
import '../services/current_user.dart';

// 서버에서 내려주는 카테고리 하나 (id + 표시 이름).
class _CategoryOption {
  final int id;
  final String name;
  const _CategoryOption({required this.id, required this.name});
}

class PickInterestsPage extends StatefulWidget {
  const PickInterestsPage({super.key});

  @override
  State<PickInterestsPage> createState() => _PickInterestsPageState();
}

class _PickInterestsPageState extends State<PickInterestsPage> {
  static const int maxSelection = 5;

  // TODO: CategoryService.getCategories() 응답 키가 다르면 _loadCategories()의 파싱 부분만 조정
  List<_CategoryOption> categories = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final Set<int> selected = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final res = await CategoryService.getCategories();
      final rawList = (res['data'] is List) ? res['data'] as List : (res['categories'] as List? ?? []);
      setState(() {
        categories = rawList
            .map((e) => _CategoryOption(
                  id: e['id'] is int ? e['id'] as int : int.tryParse('${e['id']}') ?? 0,
                  name: e['name']?.toString() ?? e['title']?.toString() ?? 'Category',
                ))
            .toList();
      });
    } catch (e) {
      // 카테고리 조회 실패 시에는 빈 목록으로 두고, 화면에서 재시도할 수 있게 둠
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggle(int categoryId) {
    setState(() {
      if (selected.contains(categoryId)) {
        selected.remove(categoryId);
      } else if (selected.length < maxSelection) {
        selected.add(categoryId);
      }
    });
  }

  Future<void> _handleNext() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      if (CurrentUser.id != null && selected.isNotEmpty) {
        await CategoryService.setUserCategories(CurrentUser.id!, selected.toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('관심사 저장에 실패했어요: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    // 온보딩 마지막 단계 -> 메인 화면으로 이동 (뒤로가기로 온보딩에 못 돌아오도록 스택 교체)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainPage()),
      (route) => false,
    );
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
              onNext: _isSaving ? null : _handleNext,
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: categories.map((category) {
                          final isSelected = selected.contains(category.id);
                          return GestureDetector(
                            onTap: () => _toggle(category.id),
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
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white24,
                                ),
                              ),
                              child: Text(
                                category.name,
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