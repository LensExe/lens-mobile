import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/photographer_detail_model.dart';

class PackagesTabView extends StatelessWidget {
  final List<ProfilePackage> packages;
  final ProfilePackage? selectedPackage;
  final Function(ProfilePackage) onSelectPackage;
  final Function(ProfilePackage) onBookPackage;

  const PackagesTabView({
    super.key,
    required this.packages,
    required this.selectedPackage,
    required this.onSelectPackage,
    required this.onBookPackage,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Gói chụp đề xuất',
                style: TextStyle(
                  color: Color(0xFF1A1C1D),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Đã kèm bảo hiểm LENS',
                style: TextStyle(
                  color: Color(0xFF5F5E60),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Packages List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: packages.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final pkg = packages[index];
              final isChosen = selectedPackage?.id == pkg.id;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: isChosen
                      ? Border.all(color: const Color(0xFFFF5A00), width: 2)
                      : Border.all(color: Colors.transparent),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge (if most selected or featured)
                    if (pkg.highlightBadge.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: pkg.isMostSelected ? const Color(0xFFFF5A00) : const Color(0xFFFFDBCF),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              pkg.highlightBadge,
                              style: TextStyle(
                                color: pkg.isMostSelected ? Colors.white : const Color(0xFF380D00),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F4),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              pkg.duration,
                              style: const TextStyle(
                                color: Color(0xFF5F5E60),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Title & Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pkg.name,
                                style: const TextStyle(
                                  color: Color(0xFF1A1C1D),
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                pkg.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF5F5E60),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(pkg.price),
                              style: const TextStyle(
                                color: Color(0xFF1A1C1D),
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (pkg.highlightBadge.isEmpty)
                              Text(
                                pkg.duration,
                                style: const TextStyle(
                                  color: Color(0xFF5F5E60),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Deliverables Checklist
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: pkg.deliverables.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: Color(0xFFFF5A00),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      color: Color(0xFF2F3132),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action Button
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              onSelectPackage(pkg);
                              onBookPackage(pkg);
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: pkg.isMostSelected ? const Color(0xFFFF5A00) : const Color(0xFF1A1C1D),
                                borderRadius: BorderRadius.circular(9999),
                                boxShadow: pkg.isMostSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFFF5A00).withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                pkg.isMostSelected ? 'Chọn gói này & Đặt lịch' : 'Đặt gói này',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
