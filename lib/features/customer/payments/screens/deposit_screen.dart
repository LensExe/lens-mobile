import 'package:flutter/material.dart';

import '../repositories/payment_repository.dart';
import 'booking_payment_screen.dart';

class DepositScreen extends StatelessWidget {
  const DepositScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) => BookingPaymentScreen(
    bookingId: bookingId,
    type: BookingPaymentType.deposit,
  );
}

