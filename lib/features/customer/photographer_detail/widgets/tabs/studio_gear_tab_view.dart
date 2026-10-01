import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_tokens.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../models/photographer_detail_model.dart';

class StudioGearTabView extends StatelessWidget {
  final StudioGearInfo gearInfo;

  const StudioGearTabView({super.key, required this.gearInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thiết bị & Studio tác nghiệp',
          style: AppTypography.headlineSm(
            fontSize: 18,
            color: AppColors.obsidian,
          ),
        ),
        const SizedBox(height: 14),

        // Main Card containing Gear Info
        Container(
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
              // 1. Camera Bodies
              _buildGearRow(
                icon: LucideIcons.camera,
                title: 'Thân máy chuyên nghiệp (Bodies)',
                items: gearInfo.cameraBodies,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.pebble),
              ),

              // 2. Lighting & Modifiers
              _buildGearRow(
                icon: LucideIcons.zap,
                title: 'Hệ thống ánh sáng & Đèn Flash',
                items: gearInfo.lightingModifiers,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.pebble),
              ),

              // 3. Studio Location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.fog,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.pebble.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.mapPin,
                        size: 17,
                        color: AppColors.obsidian,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Địa chỉ Studio tác nghiệp',
                          style: AppTypography.titleMd(
                            fontSize: 14.5,
                            color: AppColors.obsidian,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gearInfo.studioAddress,
                          style: AppTypography.bodySm(
                            fontSize: 12.5,
                            color: AppColors.steel,
                          ).copyWith(height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // LENS Care Insurance Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fog,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.pebble.withValues(alpha: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.shieldCheck,
                size: 20,
                color: AppColors.emerald,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bảo chứng An toàn LENS Care',
                      style: AppTypography.titleMd(
                        fontSize: 13.5,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gearInfo.insuranceNotice,
                      style: AppTypography.bodySm(
                        fontSize: 12,
                        color: AppColors.steel,
                      ).copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGearRow({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.fog,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pebble.withValues(alpha: 0.5)),
          ),
          child: Center(child: Icon(icon, size: 17, color: AppColors.obsidian)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMd(
                  fontSize: 14.5,
                  color: AppColors.obsidian,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                items.join(' • '),
                style: AppTypography.bodySm(
                  fontSize: 12.5,
                  color: AppColors.steel,
                ).copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
