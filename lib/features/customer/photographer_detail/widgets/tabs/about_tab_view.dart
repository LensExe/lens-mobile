import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../models/photographer_detail_model.dart';
import 'packages_tab_view.dart';
import 'studio_gear_tab_view.dart';

class AboutTabView extends StatelessWidget {
  final PhotographerProfile profile;
  final List<ProfilePackage> packages;
  final StudioGearInfo gearInfo;
  final ProfilePackage? selectedPackage;
  final ValueChanged<ProfilePackage> onSelectPackage;
  final ValueChanged<ProfilePackage> onBookPackage;

  const AboutTabView({
    super.key,
    required this.profile,
    required this.packages,
    required this.gearInfo,
    required this.selectedPackage,
    required this.onSelectPackage,
    required this.onBookPackage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IntroCard(profile: profile),
          const SizedBox(height: 16),
          PackagesTabView(
            packages: packages,
            selectedPackage: selectedPackage,
            onSelectPackage: onSelectPackage,
            onBookPackage: onBookPackage,
          ),
          const SizedBox(height: 16),
          StudioGearTabView(gearInfo: gearInfo),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final PhotographerProfile profile;

  const _IntroCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pebble),
        boxShadow: const [AppTokens.surfaceShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Về nhiếp ảnh gia',
            style: AppTypography.titleMd(
              fontSize: 16,
              color: AppColors.obsidian,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bio,
            style: AppTypography.bodySm(
              fontSize: 13.5,
              color: AppColors.graphite,
            ).copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FactChip(icon: LucideIcons.mapPin, label: profile.city),
              _FactChip(
                icon: LucideIcons.briefcaseBusiness,
                label: '${profile.experienceYears}+ năm kinh nghiệm',
              ),
              _FactChip(
                icon: LucideIcons.shieldCheck,
                label: profile.isInsured ? 'Có bảo hiểm' : 'Đã xác minh',
                isHighlight: profile.isInsured,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isHighlight;

  const _FactChip({
    required this.icon,
    required this.label,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.emerald.withValues(alpha: 0.1)
            : AppColors.fog,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: isHighlight
              ? AppColors.emerald.withValues(alpha: 0.3)
              : AppColors.pebble.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isHighlight ? AppColors.emerald : AppColors.steel,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.numeric(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isHighlight ? AppColors.emerald : AppColors.graphite,
            ),
          ),
        ],
      ),
    );
  }
}
