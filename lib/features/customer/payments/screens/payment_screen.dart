import 'package:flutter/material.dart';

import '../repositories/payment_repository.dart';
import 'booking_payment_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) => BookingPaymentScreen(
    bookingId: bookingId,
    type: BookingPaymentType.remaining,
  );
}

