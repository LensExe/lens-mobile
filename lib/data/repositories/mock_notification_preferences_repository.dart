class NotificationPreferences {
  final bool emailBooking;
  final bool emailMessage;
  final bool smsReminder;
  final bool promoCashback;

  const NotificationPreferences({
    this.emailBooking = true,
    this.emailMessage = true,
    this.smsReminder = true,
    this.promoCashback = false,
  });

  NotificationPreferences copyWith({
    bool? emailBooking,
    bool? emailMessage,
    bool? smsReminder,
    bool? promoCashback,
  }) => NotificationPreferences(
    emailBooking: emailBooking ?? this.emailBooking,
    emailMessage: emailMessage ?? this.emailMessage,
    smsReminder: smsReminder ?? this.smsReminder,
    promoCashback: promoCashback ?? this.promoCashback,
  );
}

abstract class NotificationPreferencesRepository {
  NotificationPreferences getForAccount(String accountId);
  void saveForAccount(String accountId, NotificationPreferences preferences);
}

class MockNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  static final Map<String, NotificationPreferences> _byAccount = {};

  @override
  NotificationPreferences getForAccount(String accountId) =>
      _byAccount[accountId] ?? const NotificationPreferences();

  @override
  void saveForAccount(String accountId, NotificationPreferences preferences) {
    _byAccount[accountId] = preferences;
  }
}
