import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Token terpusat untuk Liquid Glass Design System di aplikasi Tahan Dulu.
///
/// Menyediakan nilai baku transparansi, blur, radius, bayangan, dan preset
/// kualitas agar konsisten di seluruh aplikasi dengan tetap mempertahankan
/// identitas warna hijau emerald khas Tahan Dulu.
abstract final class GlassDesignTokens {
  // --- Surface Transparency & Opacities ---
  static const double lightSurfaceOpacity = 0.72;
  static const double darkSurfaceOpacity = 0.86;
  static const double solidSurfaceOpacity = 1.0;

  static const double lightBorderOpacity = 0.24;
  static const double darkBorderOpacity = 0.16;

  // --- Blur Intensities ---
  static const double blurSubtle = 8.0;
  static const double blurStandard = 14.0;
  static const double blurElevated = 20.0;

  // --- Radius Tokens ---
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(AppRadius.sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(AppRadius.md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(AppRadius.lg));
  static const BorderRadius radiusCapsule = BorderRadius.all(Radius.circular(32));

  // --- Motion & Animation ---
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;

  // --- Glass Tints ---
  static const Color lightTint = Color(0xFFFFFFFF);
  static const Color darkTint = Color(0xFF142433);
  static const Color primaryTint = AppColors.primary;
  static const Color primaryGlow = AppColors.primaryGlow;

  // --- Shadows ---
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0C163748),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x14163748),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // --- Quality & Style Presets ---
  /// Kualitas default untuk floating navigation dan overlays
  static const GlassQuality defaultNavigationQuality = GlassQuality.premium;

  /// Kualitas standar untuk floating cards dan standalone buttons
  static const GlassQuality defaultSurfaceQuality = GlassQuality.standard;

  /// Gaya visual utama aplikasi
  static const GlassStyle defaultStyle = GlassStyle.ios27;

  /// Helper untuk mengecek apakah animasi dinonaktifkan (Reduced Motion)
  static bool isReducedMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Helper untuk mengecek apakah kontras tinggi diaktifkan (High Contrast)
  static bool isHighContrast(BuildContext context) =>
      MediaQuery.highContrastOf(context);

  /// Durasi animasi yang otomatis 0 bila reduced motion aktif
  static Duration motionDuration(BuildContext context) =>
      isReducedMotion(context) ? Duration.zero : durationNormal;
}
