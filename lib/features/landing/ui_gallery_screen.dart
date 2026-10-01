import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/outlined_button.dart';
import '../../core/widgets/surface_card.dart';
import '../../core/widgets/lens_badge.dart';

class UiGalleryScreen extends StatelessWidget {
  const UiGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: const Text('Awesomic UI Gallery'),
        backgroundColor: AppColors.snow,
        foregroundColor: AppColors.obsidian,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Buttons',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.obsidian,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(text: 'Book demo', onPressed: () {}),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedWhiteButton(
                  text: 'View projects',
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Badges',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.obsidian,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              LensBadge(text: 'Photography', type: BadgeType.darkFilled),
              LensBadge(text: 'W24', type: BadgeType.ember),
              LensBadge(text: 'Overlay Style', type: BadgeType.darkOverlay),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Cards',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.obsidian,
            ),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'White Surface Card (36px radius)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Used for primary card surface on the canvas. Flat design, no shadow.',
                ),
                const SizedBox(height: 16),
                PrimaryButton(text: 'Action inside card', onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SurfaceCard(
            isMuted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Muted Surface Card (28px radius)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Secondary card or tag surface, slightly elevated feel against white.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
