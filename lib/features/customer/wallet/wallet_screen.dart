import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/lens_page.dart';
import '../../../domain/models/customer_wallet_model.dart';
import '../../../providers/data_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(customerWalletProvider);
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
            tooltip: 'Tải lại',
            onPressed: () => ref.invalidate(customerWalletProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 19),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: walletState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.ember),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.wallet,
                  size: 36,
                  color: AppColors.steel,
                ),
                const SizedBox(height: 12),
                Text(
                  'Không thể tải ví từ Backend.',
                  style: AppTypography.titleMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 6),
                Text(
                  _walletErrorMessage(error),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm(color: AppColors.steel),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(customerWalletProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (wallet) => RefreshIndicator(
          color: AppColors.ember,
          onRefresh: () async {
            final refreshed = ref.refresh(customerWalletProvider.future);
            await refreshed;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.pageHorizontal,
              12,
              AppTokens.pageHorizontal,
              40,
            ),
            children: [
              _BalanceCard(
                label: 'Số dư khả dụng',
                amount: wallet.availableBalance,
                icon: LucideIcons.wallet,
                color: AppColors.lagoon,
              ),
              const SizedBox(height: 12),
              _BalanceCard(
                label: 'Số dư đang giữ',
                amount: wallet.frozenBalance,
                icon: LucideIcons.lockKeyhole,
                color: AppColors.ember,
              ),
              const SizedBox(height: 22),
              Text(
                'Lịch sử biến động ví',
                style: AppTypography.titleMd(color: AppColors.obsidian),
              ),
              const SizedBox(height: 10),
              if (wallet.transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Text(
                    'Backend chưa ghi nhận giao dịch nào.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm(color: AppColors.steel),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < wallet.transactions.length;
                        index++
                      ) ...[
                        _LedgerRow(entry: wallet.transactions[index]),
                        if (index < wallet.transactions.length - 1)
                          const Divider(height: 1, color: AppColors.pebble),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodySm(color: AppColors.steel)),
              const SizedBox(height: 4),
              Text(
                '${AppTypography.formatCurrency(amount)} ₫',
                style: AppTypography.priceDisplay(
                  fontSize: 22,
                  color: AppColors.obsidian,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final WalletTransaction entry;

  @override
  Widget build(BuildContext context) {
    final deltaText = [
      if (entry.availableDelta != 0)
        'Khả dụng ${_signedAmount(entry.availableDelta)}',
      if (entry.frozenDelta != 0)
        'Đang giữ ${_signedAmount(entry.frozenDelta)}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              LucideIcons.arrowLeftRight,
              size: 17,
              color: AppColors.steel,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: AppTypography.labelMd(color: AppColors.obsidian),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    entry.subtitle,
                    if (entry.date.isNotEmpty) entry.date,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  style: AppTypography.bodySm(
                    fontSize: 11.5,
                    color: AppColors.steel,
                  ),
                ),
                if (deltaText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    deltaText,
                    style: AppTypography.bodySm(
                      fontSize: 11.5,
                      color: AppColors.steel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _signedAmount(int amount) {
    final prefix = amount > 0 ? '+' : '';
    return '$prefix${AppTypography.formatCurrency(amount)} ₫';
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.snow,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppColors.pebble),
  boxShadow: const [AppTokens.surfaceShadow],
);

String _walletErrorMessage(Object error) => switch (error) {
  ApiException(:final message) => message,
  ApiConfigurationException(:final message) => message,
  _ => 'Kiểm tra kết nối và API_BASE_URL rồi thử lại.',
};
