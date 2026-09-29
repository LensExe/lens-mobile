import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/photographer_detail_model.dart';

class StudioGearTabView extends StatelessWidget {
  final StudioGearInfo gearInfo;

  const StudioGearTabView({
    super.key,
    required this.gearInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thiết bị & Studio chính hãng',
            style: TextStyle(
              color: Color(0xFF1A1C1D),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),

          // Main Card containing Gear Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Camera Bodies
                _buildGearRow(
                  icon: LucideIcons.camera,
                  title: 'Thân máy (Camera Bodies)',
                  items: gearInfo.cameraBodies,
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEF)),

                // 2. Lighting & Modifiers
                _buildGearRow(
                  icon: LucideIcons.zap,
                  title: 'Hệ thống đèn & Ánh sáng (Lighting)',
                  items: gearInfo.lightingModifiers,
                ),
                const Divider(height: 24, color: Color(0xFFEEEEEF)),

                // 3. Studio Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEEEEF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.mapPin,
                          size: 18,
                          color: Color(0xFF1A1C1D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Địa chỉ Studio tác nghiệp',
                            style: TextStyle(
                              color: Color(0xFF1A1C1D),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gearInfo.studioAddress,
                            style: const TextStyle(
                              color: Color(0xFF5F5E60),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
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
              color: const Color(0xFFFFDBCF).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFDBCF), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 20,
                  color: Color(0xFFA83900),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bảo chứng An toàn LENS Care',
                        style: TextStyle(
                          color: Color(0xFF380D00),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gearInfo.insuranceNotice,
                        style: const TextStyle(
                          color: Color(0xFF5B4137),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          decoration: const BoxDecoration(
            color: Color(0xFFEEEEEF),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF1A1C1D),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A1C1D),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                items.join(' • '),
                style: const TextStyle(
                  color: Color(0xFF5F5E60),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
