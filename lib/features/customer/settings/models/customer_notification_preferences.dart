class CustomerNotificationPreferences {
  const CustomerNotificationPreferences({
    this.bookingUpdates = true,
    this.messages = true,
    this.promotions = false,
    this.emailDigest = false,
  });

  final bool bookingUpdates;
  final bool messages;
  final bool promotions;
  final bool emailDigest;

  factory CustomerNotificationPreferences.fromApiJson(Object? value) {
    final json = value is Map
        ? value.map((key, item) => MapEntry('$key', item))
        : const <String, dynamic>{};
    return CustomerNotificationPreferences(
      bookingUpdates: json['booking_updates'] != false,
      messages: json['messages'] != false,
      promotions: json['promotions'] == true,
      emailDigest: json['email_digest'] == true,
    );
  }

  Map<String, bool> toApiJson() => {
    'booking_updates': bookingUpdates,
    'messages': messages,
    'promotions': promotions,
    'email_digest': emailDigest,
  };

  CustomerNotificationPreferences copyWith({
    bool? bookingUpdates,
    bool? messages,
    bool? promotions,
    bool? emailDigest,
  }) => CustomerNotificationPreferences(
    bookingUpdates: bookingUpdates ?? this.bookingUpdates,
    messages: messages ?? this.messages,
    promotions: promotions ?? this.promotions,
    emailDigest: emailDigest ?? this.emailDigest,
  );
}
