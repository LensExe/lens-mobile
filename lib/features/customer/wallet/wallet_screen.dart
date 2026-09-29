import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/lens_page.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return LensPage(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: const Text('Ví của tôi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pageHorizontal,
          10,
          AppTokens.pageHorizontal,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.obsidian,
              borderRadius: BorderRadius.circular(AppTokens.largeCardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.coins, color: AppColors.ember, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Lens Xu',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  format.format(120000),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Có thể dùng cho lần thanh toán tiếp theo',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.gift, size: 16, color: AppColors.ember),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Xu hoàn lại sau khi bạn xác nhận nhận ảnh.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LensSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tóm tắt',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                _Stat(
                  label: 'Xu đã nhận',
                  value: format.format(280000),
                  icon: LucideIcons.trendingUp,
                  color: AppColors.lagoon,
                ),
                const SizedBox(height: 9),
                _Stat(
                  label: 'Xu đã dùng',
                  value: format.format(160000),
                  icon: LucideIcons.ticket,
                  color: AppColors.ember,
                ),
                const SizedBox(height: 9),
                _Stat(
                  label: 'Sắp hết hạn',
                  value: format.format(0),
                  icon: LucideIcons.clock3,
                  color: AppColors.steel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LensSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch sử giao dịch',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _Transaction(
                  icon: LucideIcons.gift,
                  label: 'Hoàn Lens Xu sau khi nhận ảnh',
                  date: 'Hôm nay',
                  amount: '+120.000 Xu',
                  positive: true,
                ),
                const Divider(height: 22),
                _Transaction(
                  icon: LucideIcons.ticket,
                  label: 'Dùng Xu cho lịch chụp',
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.steel, fontSize: 12),
        ),
      ),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
      Icon(
        icon,
        size: 17,
        color: positive ? AppColors.lagoon : AppColors.ember,
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              date,
              style: const TextStyle(color: AppColors.steel, fontSize: 11),
            ),
          ],
        ),
      ),
      Text(
        amount,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: positive ? AppColors.lagoon : AppColors.ink,
        ),
      ),
    ],
  );
}
