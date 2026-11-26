import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Token terpusat untuk sistem desain Liquid Glass eksklusif Dark Mode di Tahan Dulu.
///
/// **Prinsip Arsitektur (mengacu pada skill `liquid-glass-widgets` v1.20):**
/// - **Light Mode dipertahankan 100% tanpa efek kaca**.
/// - **Dark Mode** memakai shader Liquid Glass resmi (`GlassThemeData.ios27`)
///   dengan refraksi latar nyata, blur mendekati nol pada chrome mengambang,
///   tint gelap halus, sorotan tepi Fresnel alami, dan tanpa nested glass.
abstract final class GlassDesignTokens {
  /// Mengembalikan `true` hanya saat aplikasi berada dalam Dark Mode dan
  /// sistem aksesibilitas tidak menonaktifkan animasi/transparansi.
  static bool isDarkGlass(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark &&
        !isHighContrast(context);
  }

  /// Tema resmi `iOS 27` untuk mode gelap dari package `liquid_glass_widgets`.
  static final GlassThemeData darkThemeData = GlassThemeData.ios27(
    brightness: Brightness.dark,
  );

  /// Pengaturan platter kaca resmi untuk Dark Mode bottom bar (refraksi nyata, near-zero blur).
  static LiquidGlassSettings darkNavBarSettings(BuildContext context) {
    return const LiquidGlassSettings(
      glassColor: Color(0x1614202B),
      thickness: 22.0,
      blur: 1.5,
      frost: 0.0,
      refractiveIndex: 1.18,
      chromaticAberration: 0.012,
      fresnelStrength: 0.85,
      lightIntensity: 0.55,
      bodyMode: GlassBodyMode.clear,
      lensModel: GlassLensModel.spherical,
      specularSharpness: GlassSpecularSharpness.medium,
    );
  }

  /// Pengaturan platter kaca resmi untuk Dark Mode floating cards, buttons, chips, & pickers.
  static LiquidGlassSettings darkPlatterSettings(BuildContext context) {
    return const LiquidGlassSettings(
      glassColor: Color(0x1A182634),
      thickness: 18.0,
      blur: 1.5,
      frost: 0.0,
      refractiveIndex: 1.14,
      chromaticAberration: 0.008,
      fresnelStrength: 0.78,
      lightIntensity: 0.50,
      bodyMode: GlassBodyMode.clear,
      lensModel: GlassLensModel.spherical,
      specularSharpness: GlassSpecularSharpness.medium,
    );
  }

  /// Pengaturan platter dialog & modal sheet untuk permukaan besar (hindari artefak garis keras).
  static LiquidGlassSettings darkOverlaySettings(BuildContext context) {
    return const LiquidGlassSettings(
      glassColor: Color(0x2816222E),
      thickness: 12.0,
      blur: 6.0,
      frost: 0.0,
      refractiveIndex: 1.08,
      chromaticAberration: 0.0,
      fresnelStrength: 0.55,
      lightIntensity: 0.45,
      bodyMode: GlassBodyMode.clear,
      lensModel: GlassLensModel.spherical,
      specularSharpness: GlassSpecularSharpness.soft,
    );
  }

  /// Pengaturan platter kaca resmi untuk input teks, sandi, pencarian, & picker di Dark Mode.
  static LiquidGlassSettings darkInputSettings(BuildContext context) {
    return const LiquidGlassSettings(
      glassColor: Color(0x20182634),
      thickness: 14.0,
      blur: 2.0,
      frost: 0.0,
      refractiveIndex: 1.12,
      chromaticAberration: 0.006,
      fresnelStrength: 0.72,
      lightIntensity: 0.45,
      bodyMode: GlassBodyMode.clear,
      lensModel: GlassLensModel.spherical,
      specularSharpness: GlassSpecularSharpness.soft,
    );
  }

  // --- Legacy & Surface Opacity Tokens (dipertahankan untuk kompatibilitas) ---
  static const double clearPlatterOpacity = 0.02;
  static const double clearPlatterDarkOpacity = 0.08;
  static const double clearPlatterBlur = 1.5;
  static const double clearPlatterRefractiveIndex = 1.18;
  static const double clearPlatterThickness = 22.0;
  static const double clearPlatterChromaticAberration = 0.012;
  static const double clearPlatterRimLight = 0.30;
  static const double clearPlatterSpecular = 0.24;

  static const double solidCardOpacity = 1.0;
  static const double solidCardBlur = 0.0;
  static const GlassSurfaceStyle adaptiveSurfaceStyle = GlassSurfaceStyle.solid;

  static const double lightSurfaceOpacity = 0.72;
  static const double darkSurfaceOpacity = 0.86;
  static const double solidSurfaceOpacity = 1.0;

  static const double lightBorderOpacity = 0.24;
  static const double darkBorderOpacity = 0.16;

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

  static bool isHighContrast(BuildContext context) {
    return MediaQuery.highContrastOf(context) ||
        MediaQuery.disableAnimationsOf(context);
  }

  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  static Duration motionDuration(BuildContext context, {Duration? fallback}) {
    return isReducedMotion(context)
        ? Duration.zero
        : (fallback ?? durationNormal);
  }
}
