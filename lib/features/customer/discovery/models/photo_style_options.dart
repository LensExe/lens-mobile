/// Danh sách phong cách chụp ảnh chuẩn hệ thống LENS
class PhotoStyleOptions {
  static const List<String> all = [
    'Chân dung',
    'Cưới',
    'Sự kiện',
    'Thời trang',
    'Sản phẩm',
    'Gia đình',
    'Du lịch',
    'Ẩm thực',
    'Kiến trúc',
    'Đường phố',
  ];

  /// Metadata kèm keyword để map ảnh demo hoặc icon
  static const Map<String, ({String keyword, String description})> metadata = {
    'Chân dung': (keyword: 'portrait', description: 'Ảnh cá nhân, thần thái tự nhiên'),
    'Gia đình': (keyword: 'family', description: 'Khoảnh khắc gia đình ấm áp'),
    'Cưới': (keyword: 'wedding', description: 'Phóng sự cưới, ảnh viện'),
    'Sự kiện': (keyword: 'event', description: 'Tiệc, hội nghị, sự kiện'),
    'Thời trang': (keyword: 'fashion', description: 'Lookbook, editorial, fashion'),
    'Sản phẩm': (keyword: 'product', description: 'Ảnh sản phẩm, thương mại'),
    'Ẩm thực': (keyword: 'food', description: 'Món ăn, đồ uống, quán'),
    'Du lịch': (keyword: 'travel', description: 'Ảnh du lịch, phong cảnh'),
    'Kiến trúc': (keyword: 'architecture', description: 'Không gian, nội thất, công trình'),
    'Đường phố': (keyword: 'street', description: 'Street, đời thường'),
  };
}
