import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EscrowSummaryCard extends StatelessWidget {
  final int totalAmount;
  final int activeShootsCount;
  final VoidCallback? onTap;

  const EscrowSummaryCard({
    super.key,
    required this.totalAmount,
    required this.activeShootsCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDBCF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                LucideIcons.shieldCheck,
                color: Color(0xFFA83900),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'ESCROW BẢO VỆ',
                      style: TextStyle(
                        color: Color(0xFF5F5E60),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA83900),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(totalAmount),
                  style: const TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activeShootsCount > 0
                      ? '$activeShootsCount buổi chụp đang xử lý & chọn ảnh'
                      : 'Không có buổi chụp nào đang giữ tiền',
                  style: const TextStyle(
                    color: Color(0xFF5F5E60),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Trailing action
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFEEEEEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Color(0xFF5F5E60),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
