import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../models/booking_wizard_state.dart';
import 'date_strip_picker.dart';
import 'package_picker_card.dart';
import 'photographer_summary_banner.dart';
import 'time_slots_grid.dart';

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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.pageHorizontal,
        10,
        AppTokens.pageHorizontal,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photographer banner
          PhotographerSummaryBanner(profile: profile),
          const SizedBox(height: 22),

          // Section 1: Packages
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Chọn Gói Chụp',
                style: AppTypography.headlineSm(
                  fontSize: 17,
                  color: AppColors.obsidian,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Có thể tuỳ biến gói',
                style: AppTypography.labelSm(
                  fontSize: 12,
                  color: AppColors.ember,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (packages.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.ember),
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
          const SizedBox(height: 22),

          // Section 2: Date
          DateStripPicker(
            selectedDate: state.selectedDate,
            onDateSelected: onSelectDate,
            availabilityMap: state.availabilityMap,
          ),
          const SizedBox(height: 22),

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
