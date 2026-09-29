import 'package:flutter/material.dart';

class BookingStatusFilterTabs extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabSelected;
  final int Function(String) countProvider;

  const BookingStatusFilterTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.countProvider,
  });

  static const List<String> tabs = [
    'Đang thực hiện',
    'Tất cả',
    'Chờ duyệt',
    'Đã xác nhận',
    'Hoàn thành',
    'Đã hủy',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = (tab == selectedTab);
          final count = countProvider(tab);

          return GestureDetector(
            onTap: () => onTabSelected(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2F3132) : const Color(0xFFF3F3F4),
                borderRadius: BorderRadius.circular(9999),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFF0F1F2) : const Color(0xFF5F5E60),
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF5A00) : const Color(0xFFE8E8E9),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF5F5E60),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
