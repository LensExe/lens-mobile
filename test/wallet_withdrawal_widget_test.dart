import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lens_app/core/network/auth_session_store.dart';
import 'package:lens_app/data/repositories/api_customer_wallet_repository.dart';
import 'package:lens_app/domain/models/customer_wallet_model.dart';
import 'package:lens_app/features/customer/wallet/wallet_withdrawal_dialog.dart';
import 'package:lens_app/providers/data_providers.dart';

void main() {
  testWidgets('validates and submits a customer wallet withdrawal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _RecordingWalletDataSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStoreProvider.overrideWithValue(
            AuthSessionStore(storage: _MemorySessionStorage()),
          ),
          initialAuthUserProvider.overrideWithValue(null),
          customerWalletRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) =>
                      const WalletWithdrawalDialog(availableBalance: 100000),
                ),
                child: const Text('Mở yêu cầu rút tiền'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở yêu cầu rút tiền'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();

    expect(find.text('Số tiền tối thiểu là 10.000 ₫.'), findsOneWidget);
    expect(repository.withdrawalCount, 0);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '50000');
    await tester.enterText(fields.at(1), 'Cần rút tiền');
    await tester.enterText(fields.at(2), '970422');
    await tester.enterText(fields.at(3), '0123456789');
    await tester.enterText(fields.at(4), 'Nguyễn An');
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();

    expect(repository.withdrawalCount, 1);
    expect(repository.lastAmount, 50000);
    expect(repository.lastBankCode, '970422');
    expect(repository.lastAccountNumber, '0123456789');
    expect(repository.lastAccountName, 'Nguyễn An');
    expect(repository.lastIdempotencyKey, startsWith('mobile-withdrawal:'));
  });
}

class _RecordingWalletDataSource implements CustomerWalletDataSource {
  int withdrawalCount = 0;
  int? lastAmount;
  String? lastBankCode;
  String? lastAccountNumber;
  String? lastAccountName;
  String? lastIdempotencyKey;

  @override
  Future<CustomerWallet> getWallet() async => const CustomerWallet();

  @override
  Future<WalletWithdrawalRequest> requestWithdrawal({
    required int amount,
    required String reason,
    required String bankCode,
    required String accountNumber,
    required String accountName,
    required String idempotencyKey,
  }) async {
    withdrawalCount++;
    lastAmount = amount;
    lastBankCode = bankCode;
    lastAccountNumber = accountNumber;
    lastAccountName = accountName;
    lastIdempotencyKey = idempotencyKey;
    return WalletWithdrawalRequest(
      id: 'withdrawal-1',
      amount: amount,
      status: 'requested',
    );
  }
}

class _MemorySessionStorage implements SessionStorage {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
