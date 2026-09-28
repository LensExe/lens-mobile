import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/data_providers.dart';

class PhotographerDetailScreen extends ConsumerWidget {
  final String id;
  const PhotographerDetailScreen({super.key, required this.id});

  String _formatPrice(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photographers = ref.watch(photographersProvider);
    final p = photographers.firstWhere((p) => p.id == id, orElse: () => photographers.first);

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                p.cover,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: AppColors.fog),
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowLeft, color: AppColors.snow, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundImage: NetworkImage(p.avatar),
                          onBackgroundImageError: (e, s) => {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.obsidian),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (p.featured)
                                  const Icon(LucideIcons.checkCircle, color: AppColors.ember, size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                _buildIconText(LucideIcons.mapPin, p.city),
                                _buildIconText(LucideIcons.star, '${p.rating} (${p.reviewCount})', iconColor: AppColors.ember),
                                _buildIconText(LucideIcons.briefcase, '${p.experienceYears} năm KN'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: p.styles.map((style) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.pebble.withAlpha(100),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(style, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.obsidian)),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  // Trust Panel
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.snow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.pebble),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(LucideIcons.shield, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Độ uy tín', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.obsidian)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTrustStat(LucideIcons.star, p.rating.toString(), 'Đánh giá', iconColor: AppColors.ember)),
                            Expanded(child: _buildTrustStat(LucideIcons.thumbsUp, '98%', 'Đánh giá 5★', iconColor: Colors.green)),
                            Expanded(child: _buildTrustStat(LucideIcons.calendar, '120+', 'Buổi chụp')),
                            Expanded(child: _buildTrustStat(LucideIcons.users, '45%', 'Khách quay lại')),
                          ],
                        ),
                        if (p.featured) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Icon(LucideIcons.checkCircle, color: AppColors.ember, size: 16),
                              SizedBox(width: 6),
                              Text('Hồ sơ nổi bật, đã được Lens xác minh.', style: TextStyle(color: AppColors.steel, fontSize: 12)),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),
                  const Text('Giới thiệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.obsidian)),
                  const SizedBox(height: 12),
                  Text(p.bio, style: const TextStyle(color: AppColors.steel, height: 1.6, fontSize: 14)),
                  
                  const SizedBox(height: 32),
                  const Text('Tác phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.obsidian)),
                  const SizedBox(height: 16),
                  
                  // Portfolio Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: p.portfolio.length,
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          p.portfolio[index],
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: AppColors.fog),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      const Text('Đánh giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.obsidian)),
                      const SizedBox(width: 8),
                      Text('(${p.reviewCount})', style: const TextStyle(fontSize: 14, color: AppColors.steel)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Chưa có đánh giá nào.', style: TextStyle(color: AppColors.steel)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.snow,
          border: const Border(top: BorderSide(color: AppColors.pebble)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Giá từ', style: TextStyle(color: AppColors.steel, fontSize: 12)),
                    Text(
                      _formatPrice(p.pricePerSession),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.obsidian),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: 'Đặt lịch ngay',
                  onPressed: () => context.go('/customer_home/photographer/${p.id}/book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, {Color iconColor = AppColors.steel}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.steel, fontSize: 12)),
      ],
    );
  }

  Widget _buildTrustStat(IconData icon, String value, String label, {Color iconColor = AppColors.steel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.obsidian)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.steel, fontSize: 10)),
      ],
    );
  }
}
