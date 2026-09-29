import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IntroCard(profile: profile),
          const SizedBox(height: 14),
          PackagesTabView(
            packages: packages,
            selectedPackage: selectedPackage,
            onSelectPackage: onSelectPackage,
            onBookPackage: onBookPackage,
          ),
          const SizedBox(height: 14),
          StudioGearTabView(gearInfo: gearInfo),
          const SizedBox(height: 24),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Về nhiếp ảnh gia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1C1D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile.bio,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF3E4143),
            ),
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

  const _FactChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5F5E60)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3E4143),
            ),
          ),
        ],
      ),
    );
  }
}
