import '../../domain/models/customer_wallet_model.dart';

abstract class CustomerWalletRepository {
  Future<CustomerWallet> getWallet();
  Future<CustomerWallet> addRefund({
    required int amount,
    required String bookingId,
    required String photographerName,
  });
  Future<CustomerWallet> addCashback({
    required int coins,
    required String bookingId,
  });
  Future<CustomerWallet> redeemCoins({
    required int coins,
    required String bookingId,
  });
  Future<CustomerWallet> restoreCoins({
    required int coins,
    required String bookingId,
  });
  Future<CustomerWallet> addReviewReward({
    required int coins,
    required String photographerName,
  });
}

class MockCustomerWalletRepository implements CustomerWalletRepository {
  MockCustomerWalletRepository({required this.accountId, bool demo = false}) {
    _byAccount.putIfAbsent(
      accountId,
      () => demo ? _demoWallet() : const CustomerWallet(),
    );
  }

  final String accountId;
  static final Map<String, CustomerWallet> _byAccount = {};
  CustomerWallet get _wallet => _byAccount[accountId]!;
  set _wallet(CustomerWallet value) => _byAccount[accountId] = value;

  static CustomerWallet _demoWallet() => CustomerWallet(
    cashBalance: 1200000,
    coinBalance: 120000,
    expiringCoins: 15000,
    totalCashRefunded: 2400000,
    totalCoinsEarned: 280000,
    totalCoinsUsed: 160000,
    transactions: [
      WalletTransaction(
        id: 'tx-1',
        title: 'Hoàn tiền huỷ lịch chụp #LS-9421',
        subtitle: 'Hoàn 100% tiền cọc do huỷ trước 7 ngày · Alex Photography',
        date: 'Hôm nay, 14:32',
        amount: 600000,
        isPositive: true,
        type: WalletTransactionType.cashRefund,
      ),
      WalletTransaction(
        id: 'tx-2',
        title: 'Thưởng 5% Lens Xu nghiệm thu ảnh #LS-8219',
        subtitle: 'Nghiệm thu thành công gói Chân dung · Studio YC',
        date: 'Hôm qua, 18:20',
        amount: 75000,
        isPositive: true,
        type: WalletTransactionType.coinCashback,
      ),
      WalletTransaction(
        id: 'tx-3',
        title: 'Dùng Lens Xu thanh toán đơn #LS-8219',
        subtitle: 'Khấu trừ 20% giá trị hợp đồng thanh toán đợt 2',
        date: '3 ngày trước',
        amount: 80000,
        isPositive: false,
        type: WalletTransactionType.coinRedemption,
      ),
      WalletTransaction(
        id: 'tx-4',
        title: 'Thưởng Lens Xu gửi đánh giá #LS-7901',
        subtitle: 'Đánh giá 5 sao kèm phản hồi chi tiết · Studio YC',
        date: '12/09/2026',
        amount: 10000,
        isPositive: true,
        type: WalletTransactionType.reviewReward,
      ),
    ],
  );

  @override
  Future<CustomerWallet> getWallet() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _wallet;
  }

  @override
  Future<CustomerWallet> addRefund({
    required int amount,
    required String bookingId,
    required String photographerName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newTx = WalletTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Hoàn tiền huỷ lịch chụp #$bookingId',
      subtitle: 'Hoàn tiền vào số dư khả dụng · $photographerName',
      date: 'Vừa xong',
      amount: amount,
      isPositive: true,
      type: WalletTransactionType.cashRefund,
    );

    _wallet = _wallet.copyWith(
      cashBalance: _wallet.cashBalance + amount,
      totalCashRefunded: _wallet.totalCashRefunded + amount,
      transactions: [newTx, ..._wallet.transactions],
    );
    return _wallet;
  }

  @override
  Future<CustomerWallet> addCashback({
    required int coins,
    required String bookingId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newTx = WalletTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Hoàn +5% Lens Xu nghiệm thu #$bookingId',
      subtitle: 'Tích luỹ sau khi xác nhận nhận đủ ảnh thành công',
      date: 'Vừa xong',
      amount: coins,
      isPositive: true,
      type: WalletTransactionType.coinCashback,
    );

    _wallet = _wallet.copyWith(
      coinBalance: _wallet.coinBalance + coins,
      totalCoinsEarned: _wallet.totalCoinsEarned + coins,
      transactions: [newTx, ..._wallet.transactions],
    );
    return _wallet;
  }

  @override
  Future<CustomerWallet> redeemCoins({
    required int coins,
    required String bookingId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (coins < 0 || coins > _wallet.coinBalance) {
      throw StateError('Số dư Lens Xu không đủ.');
    }
    final newTx = WalletTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Khấu trừ Lens Xu cho đơn #$bookingId',
      subtitle: 'Giảm trừ tiền mặt khi thanh toán phần còn lại',
      date: 'Vừa xong',
      amount: coins,
      isPositive: false,
      type: WalletTransactionType.coinRedemption,
    );

    _wallet = _wallet.copyWith(
      coinBalance: _wallet.coinBalance - coins,
      totalCoinsUsed: _wallet.totalCoinsUsed + coins,
      transactions: [newTx, ..._wallet.transactions],
    );
    return _wallet;
  }

  @override
  Future<CustomerWallet> restoreCoins({
    required int coins,
    required String bookingId,
  }) async {
    if (coins <= 0) return _wallet;
    await Future.delayed(const Duration(milliseconds: 200));
    _wallet = _wallet.copyWith(
      coinBalance: _wallet.coinBalance + coins,
      totalCoinsUsed: (_wallet.totalCoinsUsed - coins).clamp(0, 999999999),
      transactions: [
        WalletTransaction(
          id: 'tx-${DateTime.now().microsecondsSinceEpoch}',
          title: 'Hoàn Lens Xu huỷ lịch #$bookingId',
          subtitle: 'Lens Xu đã dùng được hoàn lại',
          date: 'Vừa xong',
          amount: coins,
          isPositive: true,
          type: WalletTransactionType.coinRedemption,
        ),
        ..._wallet.transactions,
      ],
    );
    return _wallet;
  }

  @override
  Future<CustomerWallet> addReviewReward({
    required int coins,
    required String photographerName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newTx = WalletTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Thưởng viết đánh giá buổi chụp',
      subtitle: 'Cảm ơn phản hồi dành cho $photographerName',
      date: 'Vừa xong',
      amount: coins,
      isPositive: true,
      type: WalletTransactionType.reviewReward,
    );

    _wallet = _wallet.copyWith(
      coinBalance: _wallet.coinBalance + coins,
      totalCoinsEarned: _wallet.totalCoinsEarned + coins,
      transactions: [newTx, ..._wallet.transactions],
    );
    return _wallet;
  }
}
