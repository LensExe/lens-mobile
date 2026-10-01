enum WalletTransactionType {
  cashRefund,
  coinCashback,
  coinRedemption,
  reviewReward,
}

class WalletTransaction {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final int amount;
  final bool isPositive;
  final WalletTransactionType type;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.type,
  });
}

class CustomerWallet {
  final int cashBalance; // Tiền mặt hoàn từ huỷ lịch (VND)
  final int coinBalance; // Lens Xu tích luỹ (1 Xu = 1 VND)
  final int expiringCoins; // Xu sắp hết hạn trong 6 tháng
  final int totalCashRefunded; // Tổng hoàn tiền đã nhận
  final int totalCoinsEarned; // Tổng Lens Xu đã nhận
  final int totalCoinsUsed; // Tổng Lens Xu đã tiêu
  final List<WalletTransaction> transactions;

  const CustomerWallet({
    this.cashBalance = 0,
    this.coinBalance = 0,
    this.expiringCoins = 0,
    this.totalCashRefunded = 0,
    this.totalCoinsEarned = 0,
    this.totalCoinsUsed = 0,
    this.transactions = const [],
  });

  CustomerWallet copyWith({
    int? cashBalance,
    int? coinBalance,
    int? expiringCoins,
    int? totalCashRefunded,
    int? totalCoinsEarned,
    int? totalCoinsUsed,
    List<WalletTransaction>? transactions,
  }) {
    return CustomerWallet(
      cashBalance: cashBalance ?? this.cashBalance,
      coinBalance: coinBalance ?? this.coinBalance,
      expiringCoins: expiringCoins ?? this.expiringCoins,
      totalCashRefunded: totalCashRefunded ?? this.totalCashRefunded,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalCoinsUsed: totalCoinsUsed ?? this.totalCoinsUsed,
      transactions: transactions ?? this.transactions,
    );
  }
}
