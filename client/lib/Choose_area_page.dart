import 'package:flutter/material.dart';
import 'pick_interests_page.dart';
import 'onboarding_step_header.dart';

class ChooseAreaPage extends StatefulWidget {
  const ChooseAreaPage({super.key});

  @override
  State<ChooseAreaPage> createState() => _ChooseAreaPageState();
}

class _AreaItem {
  final String title;
  final String price;
  final String location;
  final String? badge; // 예: 수량 표시 (£4, £5 등)

  const _AreaItem({
    required this.title,
    required this.price,
    required this.location,
    this.badge,
  });
}

class _ChooseAreaPageState extends State<ChooseAreaPage> {
  String selectedArea = "Camden";

  final List<String> areaOptions = const [
    "Camden",
    "Islington",
    "Hackney",
    "Westminster",
    "Greenwich",
    "Southwark",
  ];

  final List<_AreaItem> trendingAuctions = const [
    _AreaItem(title: "Formal book", price: "P 10", location: "Camden Town"),
    _AreaItem(title: "CRSFPM", price: "P 25", location: "Camden Town"),
    _AreaItem(title: "Laptop", price: "P 550", location: "Camden Town"),
    _AreaItem(title: "Necklace", price: "P 50", location: "Camden Town"),
  ];

  final List<_AreaItem> secondhand = const [
    _AreaItem(
        title: "Sony sportsbag",
        price: "£4",
        location: "London Camden",
        badge: "£4"),
    _AreaItem(
        title: "Nike hoodie",
        price: "£5",
        location: "London Camden",
        badge: "£5"),
    _AreaItem(title: "Bicycle", price: "", location: "", badge: "£0"),
  ];

  void _openAreaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6D9E4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: areaOptions.length,
            itemBuilder: (context, index) {
              final area = areaOptions[index];
              final isSelected = area == selectedArea;
              return ListTile(
                title: Text(
                  area,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF4D2A3A),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() => selectedArea = area);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _itemCard(_AreaItem item) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.image_outlined,
                    color: Colors.white30, size: 32),
              ),
              if (item.badge != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.badge!,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (item.title.isNotEmpty)
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          if (item.price.isNotEmpty)
            Text(
              item.price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (item.location.isNotEmpty)
            Text(
              item.location,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14091F),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 진행바 + 동그라미 인디케이터 + 타이틀
            OnboardingStepHeader(
              totalSteps: 3,
              currentStep: 2,
              title: "Choose your area",
              onNext: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PickInterestsPage(),
                  ),
                );
              },
            ),

            // 지역 선택 드롭다운
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: _openAreaPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          selectedArea,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("Trending Auctions"),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: trendingAuctions.length,
                        itemBuilder: (context, index) =>
                            _itemCard(trendingAuctions[index]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader("Secondhand"),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: secondhand.length,
                        itemBuilder: (context, index) =>
                            _itemCard(secondhand[index]),
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
    );
  }
}