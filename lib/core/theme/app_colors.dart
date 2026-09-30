import 'package:flutter/material.dart';

class AppColors {
  // --- Dark / Text ---
  static const Color obsidian = Color(
    0xFF09090B,
  ); // Chữ chính, icon chính, viền active
  static const Color ink = Color(0xFF18181B);
  static const Color graphite = Color(0xFF3F3F46);
  static const Color slate = Color(0xFF52525B);
  static const Color steel = Color(0xFF71717A); // Chữ phụ (subtitle), icon phụ

  // --- Light / Border / Background ---
  static const Color ash = Color(0xFFA1A1AA);
  static const Color pebble = Color(
    0xFFD4D4D8,
  ); // Viền (border) thẻ, đường kẻ divider
  static const Color fog = Color(
    0xFFECECEE,
  ); // Nền khối phụ (secondary background)
  static const Color mist = Color(0xFFF4F4F5); // Nền hover, nền thẻ rất nhạt
  static const Color snow = Color(
    0xFFFFFFFF,
  ); // Trắng tinh (nền thẻ chính - SurfaceCard)
  static const Color canvas = Color(0xFFF9F9FA); // Nền màn hình chính (Surface canvas)
  static const Color surface = Color(0xFFF9F9FA);

  // --- Brand / Accents ---
  static const Color ember = Color(
    0xFFFF5A00,
  ); // MÀU THƯƠNG HIỆU: Nút bấm chính, progress bar, badge nổi bật
  static const Color lagoon = Color(
    0xFF0F766E,
  ); // Trạng thái an toàn, đã chọn, đã nhận
  static const Color orchidFlash = Color(0xFFFE45E2);

  // --- Semantic (Alerts/Status) ---
  static const Color destructive = Color(0xFFDC2626); // Lỗi, nút Xóa, Hủy
  static const Color crimson = Color(0xFFDC2626); // Crimson theo DESIGN.md
  static const Color success = Color(
    0xFF16A34A,
  ); // Emerald (#16A34A) cho verified badges và confirmed bookings
  static const Color emerald = Color(0xFF16A34A);
  static const Color warning = Color(
    0xFFF59E0B,
  ); // Cam nhạt/Vàng (Cảnh báo, Sắp hết hạn)

  static const Color statusOrange = Color(0xFFC2410C);
  static const Color statusAmber = Color(0xFFB45309);
  static const Color statusBlue = Color(0xFF1D4ED8);
  static const Color statusViolet = Color(0xFF6D28D9);
}
