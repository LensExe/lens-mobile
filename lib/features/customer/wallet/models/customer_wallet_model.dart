enum WalletTransactionType {
  cashRefund,
  coinCashback,
  coinRedemption,
  reviewReward,
  ledgerEntry,
}

class WalletTransaction {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final int amount;
  final bool isPositive;
  final WalletTransactionType type;
  final String entryType;
  final int availableDelta;
  final int frozenDelta;
  final String? bookingId;
  final String? bookingStatus;
  final String? bookingFrom;
  final String? bookingTo;
  final String? bookingPackageName;
  final String? transactionCode;
  final String? transactionStatus;
  final String? paymentGateway;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.type,
    this.entryType = '',
    this.availableDelta = 0,
    this.frozenDelta = 0,
    this.bookingId,
    this.bookingStatus,
    this.bookingFrom,
    this.bookingTo,
    this.bookingPackageName,
    this.transactionCode,
    this.transactionStatus,
    this.paymentGateway,
  });
}

class CustomerPayoutDestination {
  const CustomerPayoutDestination({
    required this.isConfigured,
    required this.bankCode,
    required this.accountName,
    required this.accountNumberMasked,
    required this.updatedAt,
  });

  final bool isConfigured;
  final String? bankCode;
  final String? accountName;
  final String? accountNumberMasked;
  final DateTime? updatedAt;
}

class CustomerWallet {
  /// Actual backend wallet amounts. Legacy coin fields below remain only for
  /// isolated mock fixtures and are not displayed in production.
  final int availableBalance;
  final int frozenBalance;
  final int cashBalance; // Tiền mặt hoàn từ huỷ lịch (VND)
  final int coinBalance; // Lens Xu tích luỹ (1 Xu = 1 VND)
  final int expiringCoins; // Xu sắp hết hạn trong 6 tháng
  final int totalCashRefunded; // Tổng hoàn tiền đã nhận
  final int totalCoinsEarned; // Tổng Lens Xu đã nhận
  final int totalCoinsUsed; // Tổng Lens Xu đã tiêu
  final List<WalletTransaction> transactions;

  const CustomerWallet({
    this.availableBalance = 0,
    this.frozenBalance = 0,
    this.cashBalance = 0,
    this.coinBalance = 0,
    this.expiringCoins = 0,
    this.totalCashRefunded = 0,
    this.totalCoinsEarned = 0,
    this.totalCoinsUsed = 0,
    this.transactions = const [],
  });

  CustomerWallet copyWith({
    int? availableBalance,
    int? frozenBalance,
    int? cashBalance,
    int? coinBalance,
    int? expiringCoins,
    int? totalCashRefunded,
    int? totalCoinsEarned,
    int? totalCoinsUsed,
    List<WalletTransaction>? transactions,
  }) {
    return CustomerWallet(
      availableBalance: availableBalance ?? this.availableBalance,
      frozenBalance: frozenBalance ?? this.frozenBalance,
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

class WalletWithdrawalRequest {
  const WalletWithdrawalRequest({
    required this.id,
    required this.amount,
    required this.status,
  });

  final String id;
  final int amount;
  final String status;
}
