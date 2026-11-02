import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../models/customer_notification_preferences.dart';
import '../repositories/api_customer_notification_preferences_repository.dart';

final customerNotificationPreferencesRepositoryProvider =
    Provider<ApiCustomerNotificationPreferencesRepository>(
      (ref) =>
          ApiCustomerNotificationPreferencesRepository(ref.watch(dioProvider)),
    );

class CustomerNotificationPreferencesNotifier
    extends AsyncNotifier<CustomerNotificationPreferences> {
  @override
  Future<CustomerNotificationPreferences> build() {
    ref.watch(authUserProvider.select((user) => user?.id));
    return ref
        .watch(customerNotificationPreferencesRepositoryProvider)
        .getPreferences();
  }

  Future<void> updatePreferences(
    CustomerNotificationPreferences preferences,
  ) async {
    final previous = state.value;
    if (previous == null) return;
    try {
      final updated = await ref
          .read(customerNotificationPreferencesRepositoryProvider)
          .updatePreferences(preferences);
      state = AsyncData(updated);
    } on Object {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final customerNotificationPreferencesProvider =
    AsyncNotifierProvider<
      CustomerNotificationPreferencesNotifier,
      CustomerNotificationPreferences
    >(() => CustomerNotificationPreferencesNotifier());

