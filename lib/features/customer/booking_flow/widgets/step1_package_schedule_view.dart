import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking_wizard_state.dart';
import 'photographer_summary_banner.dart';

import 'package:lens_app/features/customer/booking_flow/widgets/package_picker_card.dart';
import 'package:lens_app/features/customer/booking_flow/widgets/date_strip_picker.dart';
import 'package:lens_app/features/customer/booking_flow/widgets/time_slots_grid.dart';

class Step1PackageScheduleView extends StatelessWidget {
  final BookingWizardState state;
  final ValueChanged<String> onSelectPackage;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<String> onSelectTimeSlot;

  const Step1PackageScheduleView({
    super.key,
    required this.state,
    required this.onSelectPackage,
    required this.onSelectDate,
    required this.onSelectTimeSlot,
  });

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    final packages = profile?.packages ?? [];
    final dateKey = DateFormat('yyyy-MM-dd').format(state.selectedDate);
    final dayAvail = state.availabilityMap[dateKey];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photographer banner
          PhotographerSummaryBanner(profile: profile),
          const SizedBox(height: 20),

          // Section 1: Packages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1. Chọn Gói Chụp',
                style: TextStyle(
                  color: Color(0xFF1A1C1D),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Có thể tuỳ biến gói',
                style: TextStyle(
                  color: const Color(0xFFA83900),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (packages.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ...packages.map((pkg) {
              final isSelected = state.selectedPackageId == pkg.id;
              return PackagePickerCard(
                package: pkg,
                isSelected: isSelected,
                onTap: () => onSelectPackage(pkg.id),
              );
            }),
          const SizedBox(height: 20),

          // Section 2: Date
          DateStripPicker(
            selectedDate: state.selectedDate,
            onDateSelected: onSelectDate,
            availabilityMap: state.availabilityMap,
          ),
          const SizedBox(height: 20),

          // Section 3: Time Slot
          TimeSlotsGrid(
            dayAvailability: dayAvail,
            durationHours: state.durationHours,
            selectedTimeSlot: state.selectedTimeSlot,
            onSelectSlot: onSelectTimeSlot,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
