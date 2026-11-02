import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/customer_wallet_model.dart';
import '../repositories/api_customer_wallet_repository.dart';

final customerWalletRepositoryProvider = Provider<CustomerWalletDataSource>((
  ref,
) {
  return ApiCustomerWalletRepository(ref.watch(dioProvider));
});

class CustomerWalletNotifier extends AsyncNotifier<CustomerWallet> {
  @override
  Future<CustomerWallet> build() async {
    final repo = ref.watch(customerWalletRepositoryProvider);
    return repo.getWallet();
  }
}

final customerWalletProvider =
    AsyncNotifierProvider<CustomerWalletNotifier, CustomerWallet>(
      () => CustomerWalletNotifier(),
    );

final customerPayoutDestinationProvider =
    FutureProvider<CustomerPayoutDestination>(
      (ref) =>
          ref.watch(customerWalletRepositoryProvider).getPayoutDestination(),
    );

