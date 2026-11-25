import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Token terpusat untuk Liquid Glass Design System di aplikasi Tahan Dulu.
///
/// Menyediakan 3 Preset Utama:
/// - **PRESET A (True Clear Platter)**: Untuk floating chrome (Bottom Navigation Bar, FAB, tabs)
///   dengan transparansi sangat tinggi (tint ~2%), blur ~0, dan refraksi optik nyata.
/// - **PRESET B (Regular Adaptive Content Surface)**: Untuk kartu data finansial (saldo, transaksi, goal)
///   dengan kontras tinggi tanpa distorsi refraksi pada angka dan teks.
/// - **PRESET C (Lightweight Fallback)**: Untuk perangkat low-end atau mode aksesibilitas
///   (Reduce Motion / High Contrast) tanpa shader berat.
abstract final class GlassDesignTokens {
  // ==========================================
  // PRESET A: TRUE CLEAR OPTICAL PLATTER
  // ==========================================
  /// Opasitas lapisan kaca bening (True Clear) dalam mode terang (~2% white tint).
  static const double clearPlatterOpacity = 0.02;

  /// Opasitas lapisan kaca bening (True Clear) dalam mode gelap (~4% dark tint).
  static const double clearPlatterDarkOpacity = 0.04;

  /// Intensitas blur untuk True Clear glass (0.0px untuk mencegah kabur putih susu).
  static const double clearPlatterBlur = 0.0;

  /// Indeks bias cahaya (Snell's Law) optik kaca melengkung (1.20 - 1.33).
  static const double clearPlatterRefractiveIndex = 1.25;

  /// Ketebalan fisik virtual kaca optik pada tepi superellipse (dp).
  static const double clearPlatterThickness = 24.0;

  /// Dispersi kromatik halus (RGB separation) pada bevel pinggir kaca.
  static const double clearPlatterChromaticAberration = 0.015;

  /// Intensitas pantulan tepi (Fresnel Rim Lighting).
  static const double clearPlatterRimLight = 0.35;

  /// Intensitas kilau specular saat terkena cahaya sudut.
  static const double clearPlatterSpecular = 0.28;

  /// Sudut pencahayaan virtual (radian atau derajat).
  static const double clearPlatterLightAngle = GlassDefaults.lightAngle;

  /// Helper untuk membangun [LiquidGlassSettings] True Clear Platter yang konsisten.
  static LiquidGlassSettings createClearPlatterSettings({
    bool isDark = false,
    double? refractiveIndex,
    double? blur,
  }) {
    return LiquidGlassSettings(
      glassColor: isDark
          ? const Color(0x0A142433)
          : const Color(0x05FFFFFF),
      thickness: clearPlatterThickness,
      blur: blur ?? clearPlatterBlur,
      frost: 0.0,
      refractiveIndex: refractiveIndex ?? clearPlatterRefractiveIndex,
      chromaticAberration: clearPlatterChromaticAberration,
      fresnelStrength: 0.90,
      lightIntensity: 0.55,
      bodyMode: GlassBodyMode.clear,
      lensModel: GlassLensModel.spherical,
      specularSharpness: GlassSpecularSharpness.medium,
    );
  }

  // ==========================================
  // PRESET B: REGULAR ADAPTIVE CONTENT SURFACE
  // ==========================================
  /// Opasitas permukaan kartu konten finansial (100% solid adaptive).
  static const double solidCardOpacity = 1.0;

  /// Blur kartu konten finansial (0.0px tanpa blur shader).
  static const double solidCardBlur = 0.0;

  /// Gaya permukaan baku kartu finansial (Rule 1 & Rule 2: Solid wells).
  static const GlassSurfaceStyle adaptiveSurfaceStyle = GlassSurfaceStyle.solid;

  // ==========================================
  // PRESET C: LIGHTWEIGHT FALLBACK & LEGACY COMPAT
  // ==========================================
  /// Legacy surface opacity untuk backward compatibility pengujian lama.
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
  /// Kualitas default untuk floating navigation dan overlays (Impeller Vulkan multi-pass).
  static const GlassQuality defaultNavigationQuality = GlassQuality.premium;

  /// Kualitas standar untuk floating cards dan standalone buttons (single-pass shader).
  static const GlassQuality defaultSurfaceQuality = GlassQuality.standard;

  /// Gaya visual utama aplikasi (iOS 27 Superellipse Optics).
  static const GlassStyle defaultStyle = GlassStyle.ios27;

  /// Helper untuk mengecek apakah animasi dinonaktifkan (Reduced Motion).
  static bool isReducedMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Helper untuk mengecek apakah kontras tinggi diaktifkan (High Contrast).
  static bool isHighContrast(BuildContext context) =>
      MediaQuery.highContrastOf(context);

  /// Durasi animasi yang otomatis 0 bila reduced motion aktif.
  static Duration motionDuration(BuildContext context) =>
      isReducedMotion(context) ? Duration.zero : durationNormal;
}
