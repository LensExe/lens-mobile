import 'package:flutter/material.dart';

import '../models/photographer_model.dart';
import 'photographer_card_collage.dart';
import 'photographer_card_hero.dart';
import 'photographer_card_triptych.dart';

class PhotographerFeedCard extends StatelessWidget {
  final PhotographerModel photographer;
  final int index;
  final VoidCallback onTap;

  const PhotographerFeedCard({
    super.key,
    required this.photographer,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Specifically preserve iconic mappings for p1, p2, p3 or cycle through variants
    final int variant = (photographer.id == 'p1')
        ? 0
        : (photographer.id == 'p2')
        ? 1
        : (photographer.id == 'p3')
        ? 2
        : (index % 3);

    switch (variant) {
      case 0:
        return PhotographerCardCollage(
          photographer: photographer,
          onTap: onTap,
        );
      case 1:
        return PhotographerCardHero(photographer: photographer, onTap: onTap);
      case 2:
      default:
        return PhotographerCardTriptych(
          photographer: photographer,
          onTap: onTap,
        );
    }
  }
}
