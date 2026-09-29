import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/photographer_detail_model.dart';

class PhotographerDetailHeader extends StatelessWidget {
  final PhotographerProfile profile;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleBookmark;

  const PhotographerDetailHeader({
    super.key,
    required this.profile,
    required this.isBookmarked,
    required this.onBack,
    required this.onShare,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Cover Image
          CachedNetworkImage(
            imageUrl: profile.coverImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: const Color(0xFFE8E8E9)),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFFE8E8E9),
              child: const Icon(LucideIcons.image, color: Color(0xFF5F5E60), size: 40),
            ),
          ),

          // 2. Gradient Overlay for smooth transition into background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black38,
                  Colors.transparent,
                  Color(0x40F9F9FA),
                  Color(0xFFF9F9FA),
                ],
                stops: [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),

          // 3. Top Action Row with Safe Area
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.arrowLeft,
                            color: Color(0xFF1A1C1D),
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    // Right Actions (Share + Favorite)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onShare,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.share2,
                                color: Color(0xFF1A1C1D),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onToggleBookmark,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isBookmarked ? Icons.favorite : LucideIcons.heart,
                                color: isBookmarked ? const Color(0xFFFF5A00) : const Color(0xFF1A1C1D),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Studio Verified & Insured Floating Badge
          if (profile.isVerified)
            Positioned(
              left: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.shieldCheck,
                      color: Color(0xFFA83900),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      profile.verificationBadge,
                      style: const TextStyle(
                        color: Color(0xFF1A1C1D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
