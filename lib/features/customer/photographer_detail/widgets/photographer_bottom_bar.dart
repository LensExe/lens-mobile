import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/photographer_detail_model.dart';

class PhotographerBottomBar extends StatelessWidget {
  final ProfilePackage? selectedPackage;
  final int startingPrice;
  final VoidCallback onMessage;
  final VoidCallback onBook;

  const PhotographerBottomBar({
    super.key,
    required this.selectedPackage,
    required this.startingPrice,
    required this.onMessage,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final displayPrice = selectedPackage != null ? selectedPackage!.price : startingPrice;
    final priceLabel = selectedPackage != null ? 'Gói đã chọn' : 'Giá chỉ từ';

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceLabel,
                  style: const TextStyle(
                    color: Color(0xFF5F5E60),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currencyFormat.format(displayPrice),
                  style: const TextStyle(
                    color: Color(0xFF1A1C1D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),

          // Message Button
          GestureDetector(
            onTap: onMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F4),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.messageCircle,
                  color: Color(0xFF1A1C1D),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Book Now Button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onBook,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A00),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5A00).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Đặt lịch ngay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
