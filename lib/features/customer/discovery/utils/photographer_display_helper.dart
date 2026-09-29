import '../models/photographer_model.dart';

class PhotographerDisplayHelper {
  /// Formats price in standard Millions (M ₫) or Thousands (k ₫)
  static String formatPrice(double price) {
    if (price >= 1000000) {
      final double millions = price / 1000000;
      final bool isInt = (millions % 1 == 0);
      return '${isInt ? millions.toInt() : millions.toStringAsFixed(1)}M ₫';
    } else if (price >= 1000) {
      final double thousands = price / 1000;
      return '${thousands.toInt()}k ₫';
    }
    return '${price.toInt()} ₫';
  }

  /// Returns 3 curated high-resolution gallery images for each photographer
  /// without mutating or altering the core PhotographerModel.
  static List<String> getGalleryImages(PhotographerModel photographer) {
    // Specific curated image sets matching the reference UI design
    if (photographer.id == 'p1' || photographer.name.contains('Minh Hà')) {
      return [
        'https://images.unsplash.com/photo-1554080353-a576cf803bda?auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&q=80',
      ];
    }
    if (photographer.id == 'p2' || photographer.name.contains('Elena')) {
      return [
        'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80',
      ];
    }
    if (photographer.id == 'p3' || photographer.name.contains('Khải')) {
      return [
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&q=80',
      ];
    }

    // Default fallback based on photographer cover and aesthetic photography
    return [
      photographer.coverImageUrl,
      'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1493863641943-9b68992a8d07?auto=format&fit=crop&q=80',
    ];
  }

  /// Formats photographer styles and city into subtitle
  static String getCategorySubtitle(PhotographerModel photographer) {
    final stylesText = photographer.styles.isNotEmpty
        ? photographer.styles.join(' & ')
        : 'Nhiếp ảnh';
    return '$stylesText • ${photographer.city}';
  }
}
