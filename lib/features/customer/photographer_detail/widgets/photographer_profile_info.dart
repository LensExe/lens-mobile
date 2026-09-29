import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/photographer_detail_model.dart';

class PhotographerProfileInfo extends StatelessWidget {
  final PhotographerProfile profile;

  const PhotographerProfileInfo({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avatar & Identity Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with active badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profile.avatarUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: const Color(0xFFE8E8E9)),
                        errorWidget: (context, url, error) => const Icon(LucideIcons.user, size: 36),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5A00),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Name, Rank & City
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: const TextStyle(
                              color: Color(0xFF1A1C1D),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile.rank,
                            style: const TextStyle(
                              color: Color(0xFF5B4137),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // City & Rating
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 13, color: Color(0xFF5F5E60)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            profile.city,
                            style: const TextStyle(
                              color: Color(0xFF5F5E60),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5F5E60),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Color(0xFFFF5A00), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          '${profile.rating}',
                          style: const TextStyle(
                            color: Color(0xFF1A1C1D),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${profile.reviewCount})',
                          style: const TextStyle(
                            color: Color(0xFF5F5E60),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Bio Summary
          Text(
            profile.bio,
            style: const TextStyle(
              color: Color(0xFF2F3132),
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Trust Metrics Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  '${profile.experienceYears}+ Năm',
                  'Kinh nghiệm',
                  LucideIcons.award,
                ),
                _buildDivider(),
                _buildMetricItem(
                  '${profile.completedShoots}+',
                  'Buổi chụp xong',
                  LucideIcons.camera,
                ),
                _buildDivider(),
                _buildMetricItem(
                  '${profile.completionRate}%',
                  'Nghiệm thu',
                  LucideIcons.checkCheck,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFA83900)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1C1D),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5F5E60),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFEEEEEF),
    );
  }
}
