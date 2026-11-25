import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/glass_design_tokens.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/glass.dart';
import 'app_image_icon.dart';

/// Tombol Liquid Glass untuk Tahan Dulu.
///
/// Membagi tindakan secara semantik:
/// - **Primary Actions**: Solid Emerald Green (`AppColors.primary`) dengan kontras tinggi,
///   indikator pemuatan, dan disabled state tanpa transparansi berlebih agar CTA utama tegas.
/// - **Secondary Actions**: Subtle Liquid Glass platter dengan batas halus,
///   refraksi ringan, dan umpan balik sentuhan lembut.
class AppGlassButton extends StatelessWidget {
  const AppGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
    this.assetPath,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.height = 50.0,
    this.surfaceStyle,
  });

  /// Label teks tombol.
  final String label;

  /// Callback saat tombol ditekan. Bila null atau isLoading, tombol berstatus nonaktif.
  final VoidCallback? onPressed;

  /// Menentukan apakah tombol adalah CTA primer (solid emerald) atau sekunder (glass).
  final bool isPrimary;

  /// Menampilkan indikator loading saat true.
  final bool isLoading;

  /// Ikon Material opsional di sisi kiri label.
  final IconData? icon;

  /// Aset ikon 3D / PNG kustom opsional.
  final String? assetPath;

  /// Warna latar kustom.
  final Color? backgroundColor;

  /// Warna teks dan ikon kustom.
  final Color? foregroundColor;

  /// Radius sudut tombol (default: AppRadius.button).
  final BorderRadius? borderRadius;

  /// Tinggi tombol (default: 50.0).
  final double height;

  /// Override gaya permukaan (solid atau glass).
  final GlassSurfaceStyle? surfaceStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.button;
    final isReduced = GlassDesignTokens.isReducedMotion(context);

    final disabled = isLoading || onPressed == null;

    // --- 1. PRIMARY ACTION (Solid Emerald Green CTA) ---
    if (isPrimary) {
      final effectiveBg = backgroundColor ??
          (disabled
              ? (isDark
                  ? scheme.surfaceContainerHighest
                  : AppColors.buttonMuted)
              : scheme.primary);

      final effectiveFg = foregroundColor ??
          (disabled
              ? (isDark ? scheme.onSurfaceVariant : AppColors.textDisabled)
              : scheme.onPrimary);

      return AnimatedContainer(
        duration: isReduced ? Duration.zero : GlassDesignTokens.durationFast,
        curve: GlassDesignTokens.curve,
        height: height,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: radius,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: disabled ? null : onPressed,
            borderRadius: radius,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (assetPath != null) ...[
                          AppImageIcon(
                            assetPath: assetPath!,
                            size: 18,
                            fallbackIcon: icon ?? Icons.arrow_forward,
                          ),
                          const SizedBox(width: 8),
                        ] else if (icon != null) ...[
                          Icon(icon, size: 18, color: effectiveFg),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: effectiveFg,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    }

    // --- 2. SECONDARY ACTION (Liquid Glass Platter) ---
    final glassStyle = surfaceStyle ?? GlassSurfaceStyle.glass;
    final double radiusValue = radius.topLeft.x;

    return SizedBox(
      height: height,
      child: GlassButton.custom(
        onTap: disabled ? () {} : onPressed!,
        enabled: !disabled,
        surfaceStyle: glassStyle,
        style: GlassButtonStyle.prominent,
        shape: LiquidRoundedSuperellipse(borderRadius: radiusValue),
        tintColor: isDark
            ? const Color(0x0C142433)
            : const Color(0x08FFFFFF),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? scheme.primary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (assetPath != null) ...[
                      AppImageIcon(
                        assetPath: assetPath!,
                        size: 18,
                        fallbackIcon: icon ?? Icons.arrow_forward,
                      ),
                      const SizedBox(width: 8),
                    ] else if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: foregroundColor ?? scheme.primary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor ??
                            (isDark ? Colors.white : scheme.onSurface),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Icon Button berpermukaan Liquid Glass dengan area sentuh minimal 48x48.
class AppGlassIconButton extends StatelessWidget {
  const AppGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 48.0,
    this.iconSize = 20.0,
    this.tintColor,
    this.foregroundColor,
    this.surfaceStyle = GlassSurfaceStyle.glass,
  });

  /// Widget ikon yang ditampilkan di tengah tombol.
  final Widget icon;

  /// Callback saat ditekan. Bila null, tombol berstatus nonaktif.
  final VoidCallback? onPressed;

  /// Tooltip aksesibilitas.
  final String? tooltip;

  /// Ukuran sisi tombol (default: 48.0, memenuhi standar 48px touch target).
  final double size;

  /// Ukuran ikon.
  final double iconSize;

  /// Warna tint kaca kustom.
  final Color? tintColor;

  /// Warna foreground ikon.
  final Color? foregroundColor;

  /// Gaya permukaan kaca (glass atau solid).
  final GlassSurfaceStyle surfaceStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget button = SizedBox(
      width: size,
      height: size,
      child: GlassIconButton(
        icon: IconTheme(
          data: IconThemeData(
            size: iconSize,
            color: foregroundColor ??
                (isDark ? Colors.white : scheme.onSurface),
          ),
          child: icon,
        ),
        onPressed: onPressed,
        surfaceStyle: surfaceStyle,
        style: GlassButtonStyle.prominent,
        shape: GlassIconButtonShape.circle,
        tintColor: tintColor ??
            (isDark
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.8)),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
