import 'package:flutter/material.dart';

/// 온보딩 단계(예: Create account → Choose area → Pick interests)에서
/// 공통으로 쓰는 상단 진행 표시 헤더.
/// - 위쪽: 구간별로 채워지는 진행 바
/// - 그 아래 오른쪽: 현재 단계를 나타내는 동그라미 인디케이터
/// - 그 아래: 화면 제목 + (선택) 다음으로 넘어가는 화살표 버튼
class OnboardingStepHeader extends StatelessWidget {
  final int totalSteps;
  final int currentStep; // 1부터 시작
  final String title;
  final VoidCallback? onNext;

  const OnboardingStepHeader({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.title,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 구간 진행 바
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 6 : 0,
                  ),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // 오른쪽 정렬 동그라미 인디케이터
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(totalSteps, (index) {
              final isFilled = index < currentStep;
              return Padding(
                padding: EdgeInsets.only(
                  left: index > 0 ? 8 : 0,
                ),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.2,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // 화면 제목 + 다음 화살표
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
              if (onNext != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 18),
                  onPressed: onNext,
                ),
            ],
          ),
        ],
      ),
    );
  }
}