import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/outlined_button.dart';
import '../../data/mock_database.dart';

// --- Components ---

class CountUpStat extends StatelessWidget {
  final double endValue;
  final String suffix;
  final String label;
  final bool isInt;

  const CountUpStat({
    super.key,
    required this.endValue,
    required this.label,
    this.suffix = '',
    this.isInt = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: endValue),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            final formatted = isInt
                ? value.toInt().toString()
                : value.toStringAsFixed(1);
            return Text(
              '$formatted$suffix',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.obsidian,
                letterSpacing: -1,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.steel),
        ),
      ],
    );
  }
}

class KineticBand extends StatefulWidget {
  const KineticBand({super.key});

  @override
  State<KineticBand> createState() => _KineticBandState();
}

class _KineticBandState extends State<KineticBand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text =
        "Chân dung • Cưới • Sự kiện • Du lịch • Thời trang • Ẩm thực • Gia đình • Kiến trúc • ";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.pebble),
          bottom: BorderSide(color: AppColors.pebble),
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Move from 0 to -screen width (approximately)
          return Transform.translate(
            offset: Offset(-_controller.value * 500, 0),
            child: child,
          );
        },
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: List.generate(
              4,
              (index) => Text(
                text,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.obsidian,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StyleShowcase extends StatefulWidget {
  const StyleShowcase({super.key});

  @override
  State<StyleShowcase> createState() => _StyleShowcaseState();
}

class _StyleShowcaseState extends State<StyleShowcase> {
  final PageController _pageController = PageController(viewportFraction: 0.75);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photographers = MockDatabase.photographers;

    return Column(
      children: [
        const Text(
          'Xem trước phong cách',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.obsidian,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Vuốt để khám phá. Mỗi nhiếp ảnh gia một dấu ấn riêng.',
            style: TextStyle(fontSize: 14, color: AppColors.steel),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            itemCount: photographers.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                  }

                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 400,
                      width: Curves.easeOut.transform(value) * 280,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          photographers[index].cover,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              Container(color: AppColors.fog),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(150), // black/60
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photographers[index].name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.star,
                                      color: AppColors.ember,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${photographers[index].rating} • ${photographers[index].styles.first}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- Screen ---

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Collect all portfolio images for the gallery
    final galleryImages = MockDatabase.photographers
        .expand((p) => p.portfolio)
        .take(6)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. HERO SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.snow.withAlpha(180),
                              border: Border.all(color: AppColors.pebble),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  LucideIcons.star,
                                  color: AppColors.ember,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Hơn 1.200 nhiếp ảnh gia trên khắp Việt Nam',
                                  style: TextStyle(
                                    color: AppColors.steel,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fade(duration: 500.ms)
                        .slideY(begin: 0.5, end: 0, curve: Curves.easeOutQuad),
                    const SizedBox(height: 24),
                    RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppColors.obsidian,
                              height: 1.12,
                            ),
                            children: [
                              TextSpan(text: 'Tìm nhiếp ảnh gia\ncho mọi\n'),
                              TextSpan(
                                text: 'khoảnh khắc',
                                style: TextStyle(color: AppColors.ash),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fade(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    const SizedBox(height: 20),
                    const Text(
                          'Xem portfolio, so sánh đánh giá và đặt lịch với nhiếp ảnh gia phù hợp, tất cả trên một nền tảng.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.steel,
                            height: 1.5,
                          ),
                        )
                        .animate()
                        .fade(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    const SizedBox(height: 32),

                    Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.snow,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.pebble),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                offset: Offset(0, 8),
                                blurRadius: 30,
                                spreadRadius: -12,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(
                                LucideIcons.search,
                                color: AppColors.steel,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Phong cách, địa điểm...',
                                    hintStyle: TextStyle(
                                      color: AppColors.steel,
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              PrimaryButton(text: 'Tìm kiếm', onPressed: () {}),
                            ],
                          ),
                        )
                        .animate()
                        .fade(delay: 600.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- 2. STATS STRIP ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.pebble),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: CountUpStat(
                            endValue: 1200,
                            suffix: '+',
                            label: 'Nhiếp ảnh gia',
                          ),
                        ),
                        Expanded(
                          child: CountUpStat(
                            endValue: 28000,
                            suffix: '+',
                            label: 'Buổi chụp hoàn thành',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: const [
                        Expanded(
                          child: CountUpStat(
                            endValue: 63,
                            label: 'Tỉnh thành phủ sóng',
                          ),
                        ),
                        Expanded(
                          child: CountUpStat(
                            endValue: 4.9,
                            suffix: '/5',
                            label: 'Đánh giá trung bình',
                            isInt: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(delay: 800.ms).scaleY(begin: 0.9, end: 1),

              const SizedBox(height: 48),

              // --- 3. KINETIC BAND ---
              const KineticBand().animate().fade(delay: 1000.ms),

              const SizedBox(height: 48),

              // --- 4. GALLERY MASONRY (Mobile: 2-col Grid) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Khoảnh khắc trên Lens',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.obsidian,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hàng nghìn bộ ảnh thực tế từ cộng đồng nhiếp ảnh gia.',
                      style: TextStyle(fontSize: 14, color: AppColors.steel),
                    ),
                    const SizedBox(height: 24),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75, // 3:4 aspect ratio
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: galleryImages.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            galleryImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: AppColors.fog),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 64),

              // --- 5. STYLE SHOWCASE ---
              const StyleShowcase(),

              const SizedBox(height: 64),

              // --- 6. FOOTER CTA ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      text: 'Tìm nhiếp ảnh gia',
                      onPressed: () => context.go('/login'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedWhiteButton(
                      text: 'Trở thành nhiếp ảnh gia',
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
