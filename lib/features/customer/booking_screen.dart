import 'package:flutter/material.dart';

import 'booking_flow/screens/booking_wizard_screen.dart';

class BookingScreen extends StatelessWidget {
  final String id;
  final String? packageId;
  const BookingScreen({super.key, required this.id, this.packageId});

  @override
  Widget build(BuildContext context) {
    return BookingWizardScreen(photographerId: id, initialPackageId: packageId);
  }
}
