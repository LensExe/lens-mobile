import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LensPage(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pebble),
                  boxShadow: const [AppTokens.surfaceShadow],
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  size: 18,
                  color: AppColors.obsidian,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Ví của tôi',
          style: AppTypography.titleMd(color: AppColors.obsidian),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          40,
        ),
        children: [
          // Dark VIP Coin Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.obsidian,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.coins, color: AppColors.ember, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Lens Xu Tích Lũy',
                          style: AppTypography.labelMd(color: Colors.white70),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '1 Xu = 1 VNĐ',
                        style: AppTypography.numeric(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppTypography.formatCurrency(120000),
                  style: AppTypography.priceDisplay(
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Có thể dùng khấu trừ trực tiếp cho lần đặt lịch tiếp theo',
                  style: AppTypography.bodySm(color: Colors.white60),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.gift, size: 16, color: AppColors.ember),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Xu được hoàn tự động sau khi bạn xác nhận hoàn tất buổi chụp.',
                          style: AppTypography.bodySm(fontSize: 11.5, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.snow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.pebble),
              boxShadow: const [AppTokens.surfaceShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan tài khoản',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 14),
                _Stat(
                  label: 'Xu đã tích lũy',
                  value: AppTypography.formatCurrency(280000),
                  icon: LucideIcons.trendingUp,
                  color: AppColors.emerald,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),
                _Stat(
                  label: 'Xu đã sử dụng',
                  value: AppTypography.formatCurrency(160000),
                  icon: LucideIcons.ticket,
                  color: AppColors.ember,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),
                _Stat(
                  label: 'Sắp hết hạn',
                  value: AppTypography.formatCurrency(0),
                  icon: LucideIcons.clock3,
                  color: AppColors.steel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transaction History Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.snow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.pebble),
              boxShadow: const [AppTokens.surfaceShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lịch sử biến động Xu',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 14),
                _Transaction(
                  icon: LucideIcons.gift,
                  label: 'Hoàn Lens Xu sau khi nghiệm thu ảnh',
                  date: 'Hôm nay',
                  amount: '+120.000 Xu',
                  positive: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),
                _Transaction(
                  icon: LucideIcons.ticket,
                  label: 'Khấu trừ đặt cọc cho buổi chụp',
                  date: '12/09/2026',
                  amount: '-80.000 Xu',
                  positive: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: AppTypography.bodySm(
            fontSize: 13,
            color: AppColors.steel,
          ),
        ),
      ),
      Text(
        value,
        style: AppTypography.numeric(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.obsidian,
        ),
      ),
    ],
  );
}

class _Transaction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String date;
  final String amount;
  final bool positive;

  const _Transaction({
    required this.icon,
    required this.label,
    required this.date,
    required this.amount,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (positive ? AppColors.emerald : AppColors.ember).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 17,
          color: positive ? AppColors.emerald : AppColors.ember,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.titleMd(
                fontSize: 13,
                color: AppColors.obsidian,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: AppTypography.bodySm(fontSize: 11, color: AppColors.steel),
            ),
          ],
        ),
      ),
      Text(
        amount,
        style: AppTypography.numeric(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: positive ? AppColors.emerald : AppColors.obsidian,
        ),
      ),
    ],
  );
}
