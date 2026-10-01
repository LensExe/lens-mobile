import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/models/customer_wallet_model.dart';
import '../../../providers/data_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(customerWalletProvider);
    if (walletState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.ember)),
      );
    }
    if (walletState.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ví của tôi')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Không thể tải ví. Vui lòng thử lại.'),
              TextButton(
                onPressed: () => ref.invalidate(customerWalletProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    final wallet = walletState.value ?? const CustomerWallet();

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
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.helpCircle,
              color: AppColors.steel,
              size: 20,
            ),
            onPressed: () => _showWalletRulesSheet(context),
          ),
          const SizedBox(width: 8),
        ],
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
          // 1. Thẻ Số dư khả dụng tiền mặt (Tiền hoàn từ đơn huỷ)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.snow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.pebble),
              boxShadow: const [AppTokens.surfaceShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.lagoon.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.wallet,
                              size: 16,
                              color: AppColors.lagoon,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Số dư tiền hoàn khả dụng',
                              maxLines: 2,
                              style: AppTypography.titleMd(
                                fontSize: 14,
                                color: AppColors.obsidian,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fog,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'VND',
                        style: AppTypography.numeric(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.steel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  AppTypography.formatCurrency(wallet.cashBalance),
                  style: AppTypography.priceDisplay(
                    fontSize: 28,
                    color: AppColors.obsidian,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tiền hoàn từ các lịch đã huỷ sẽ được cộng vào ví của bạn.',
                  style: AppTypography.bodySm(
                    color: AppColors.steel,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Dùng đặt lịch mới',
                        height: 42,
                        onPressed: () => context.go('/customer_home/discovery'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: null, // Disabled for client
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          side: const BorderSide(color: AppColors.pebble),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: Text(
                          'Rút về ngân hàng',
                          style: AppTypography.labelMd(color: AppColors.pebble),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '* Tính năng rút tiền về tài khoản ngân hàng chỉ áp dụng cho đối tác Nhiếp ảnh gia.',
                  style: AppTypography.bodySm(
                    color: AppColors.steel,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Dark VIP Coin Card (Lens Xu Tích Luỹ)
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
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.coins,
                            color: AppColors.ember,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Số dư Lens Xu',
                              style: AppTypography.titleMd(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showWalletRulesSheet(context),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.helpCircle,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cách dùng',
                              style: AppTypography.numeric(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '${AppTypography.formatCurrency(wallet.coinBalance)} Xu',
                  style: AppTypography.priceDisplay(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1 Xu = 1 VNĐ. Khấu trừ trực tiếp tối đa 20% giá trị gói khi thanh toán.',
                  style: AppTypography.bodySm(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                if (wallet.expiringCoins > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ember.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.ember.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          size: 15,
                          color: AppColors.ember,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Có ${AppTypography.formatCurrency(wallet.expiringCoins)} Xu sẽ hết hạn trong 6 tháng tới.',
                            style: AppTypography.bodySm(
                              fontSize: 11.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Summary 3 Metrics
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
                  'Thống kê tích luỹ',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 14),
                _Stat(
                  label: 'Đã hoàn về ví (VND)',
                  value: AppTypography.formatCurrency(wallet.totalCashRefunded),
                  icon: LucideIcons.rotateCcw,
                  color: AppColors.lagoon,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),
                _Stat(
                  label: 'Tổng Xu đã nhận',
                  value:
                      '${AppTypography.formatCurrency(wallet.totalCoinsEarned)} Xu',
                  icon: LucideIcons.trendingUp,
                  color: AppColors.emerald,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.pebble),
                ),
                _Stat(
                  label: 'Tổng Xu đã dùng',
                  value:
                      '${AppTypography.formatCurrency(wallet.totalCoinsUsed)} Xu',
                  icon: LucideIcons.ticket,
                  color: AppColors.ember,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Lịch sử giao dịch
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
                  'Lịch sử biến động',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 14),
                if (wallet.transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Chưa có giao dịch nào phát sinh',
                        style: AppTypography.bodySm(color: AppColors.steel),
                      ),
                    ),
                  )
                else
                  ...wallet.transactions.map((tx) {
                    final isCash = tx.type == WalletTransactionType.cashRefund;
                    final unit = isCash ? '₫' : 'Xu';
                    final sign = tx.isPositive ? '+' : '-';
                    final amountStr =
                        '$sign${AppTypography.formatCurrency(tx.amount)} $unit';

                    return Column(
                      children: [
                        _Transaction(
                          icon: _iconForType(tx.type),
                          label: tx.title,
                          subtitle: tx.subtitle,
                          date: tx.date,
                          amount: amountStr,
                          positive: tx.isPositive,
                        ),
                        if (tx != wallet.transactions.last)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: AppColors.pebble),
                          ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.cashRefund:
        return LucideIcons.rotateCcw;
      case WalletTransactionType.coinCashback:
        return LucideIcons.gift;
      case WalletTransactionType.coinRedemption:
        return LucideIcons.ticket;
      case WalletTransactionType.reviewReward:
        return LucideIcons.star;
    }
  }

  void _showWalletRulesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.snow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.coins, color: AppColors.ember, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Quy chế Ví & Tích luỹ Lens Xu',
                  style: AppTypography.titleMd(
                    fontSize: 16,
                    color: AppColors.obsidian,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _WalletRuleRow(
              number: '1',
              title: 'Hoàn 5% sau mỗi buổi chụp',
              desc: 'Sau khi nghiệm thu và nhận đủ ảnh từ thợ, bạn được hoàn lại 5% tổng giá trị gói dưới dạng Lens Xu.',
            ),
            const SizedBox(height: 12),
            _WalletRuleRow(
              number: '2',
              title: 'Khấu trừ 20% khi đặt lịch mới',
              desc: 'Bạn có thể dùng Lens Xu để trừ tối đa 20% chi phí ở bước thanh toán phần còn lại của gói chụp.',
            ),
            const SizedBox(height: 12),
            _WalletRuleRow(
              number: '3',
              title: 'Tiền hoàn huỷ lịch',
              desc: 'Tiền hoàn khi huỷ lịch chụp hợp lệ được lưu trong số dư khả dụng và có thể tái sử dụng ngay cho lịch mới.',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Đã hiểu',
              height: 48,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletRuleRow extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _WalletRuleRow({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.fog,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.numeric(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMd(color: AppColors.obsidian),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTypography.bodySm(
                  fontSize: 12,
                  color: AppColors.steel,
                ),
              ),
            ],
          ),
        ),
      ],
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
          style: AppTypography.bodySm(fontSize: 13, color: AppColors.steel),
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
  final String subtitle;
  final String date;
  final String amount;
  final bool positive;

  const _Transaction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: (positive ? AppColors.emerald : AppColors.ember).withValues(
            alpha: 0.12,
          ),
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
              subtitle,
              style: AppTypography.bodySm(fontSize: 11, color: AppColors.steel),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: AppTypography.bodySm(
                fontSize: 10.5,
                color: AppColors.steel,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
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
