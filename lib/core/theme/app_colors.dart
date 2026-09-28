import 'package:flutter/material.dart';

class AppColors {
  // --- Dark / Text ---
  static const Color obsidian = Color(0xFF09090B); // Chữ chính, icon chính, viền active
  static const Color ink = Color(0xFF18181B);
  static const Color graphite = Color(0xFF3F3F46);
  static const Color slate = Color(0xFF52525B);
  static const Color steel = Color(0xFF71717A); // Chữ phụ (subtitle), icon phụ

  // --- Light / Border / Background ---
  static const Color ash = Color(0xFFA1A1AA);
  static const Color pebble = Color(0xFFD4D4D8); // Viền (border) thẻ, đường kẻ divider
  static const Color fog = Color(0xFFECECEE); // Nền khối phụ (secondary background)
  static const Color mist = Color(0xFFF4F4F5); // Nền hover, nền thẻ rất nhạt
  static const Color snow = Color(0xFFFFFFFF); // Trắng tinh (nền thẻ chính - SurfaceCard)

  // --- Brand / Accents ---
  static const Color ember = Color(0xFFFF5A00); // MÀU THƯƠNG HIỆU: Nút bấm chính, progress bar, badge nổi bật
  static const Color orchidFlash = Color(0xFFFE45E2);
  
  // --- Semantic (Alerts/Status) ---
  static const Color destructive = Color(0xFFDC2626); // Lỗi, nút Xóa, Hủy
  static const Color success = Color(0xFF10B981); // Xanh lá (Đã hoàn thành, Huy hiệu)
  static const Color warning = Color(0xFFF59E0B); // Cam nhạt/Vàng (Cảnh báo, Sắp hết hạn)
}
