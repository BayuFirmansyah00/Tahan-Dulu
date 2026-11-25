import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/glass_design_tokens.dart';
import '../theme/app_radius.dart';
import '../theme/glass.dart';

/// Kartu pintar berorientasi Liquid Glass Design System.
///
/// **Prinsip Utama:**
/// - Kartu data keuangan (saldo, riwayat transaksi, anggaran, goals) menggunakan
///   `surfaceStyle: GlassSurfaceStyle.solid` agar teks nominal dan detail kontras
///   maksimal dan mudah dibaca tanpa distorsi refraksi.
/// - Kartu mengambang (floating spotlight, header khusus, status banner) dapat
///   mengaktifkan `isFloatingGlass: true` untuk mendapatkan efek refraksi liquid glass.
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.isFloatingGlass = false,
    this.surfaceStyle,
    this.borderRadius,
    this.tintColor,
    this.border,
    this.margin,
  });

  /// Konten di dalam kartu.
  final Widget child;

  /// Padding konten (default: EdgeInsets.all(16)).
  final EdgeInsetsGeometry padding;

  /// Margin luar kartu opsional.
  final EdgeInsetsGeometry? margin;

  /// Callback sentuhan kartu opsional.
  final VoidCallback? onTap;

  /// Menentukan apakah kartu adalah floating platter (refractive glass)
  /// atau solid adaptive surface (default false untuk menjaga keterbacaan).
  final bool isFloatingGlass;

  /// Override eksplisit gaya permukaan (solid atau glass).
  final GlassSurfaceStyle? surfaceStyle;

  /// Radius sudut kartu (default: AppRadius.cardLarge ~20px).
  final BorderRadius? borderRadius;

  /// Tint warna kaca opsional.
  final Color? tintColor;

  /// Garis tepi kustom opsional.
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final scheme = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.cardLarge;
    final effectiveStyle = surfaceStyle ??
        (isFloatingGlass ? GlassSurfaceStyle.glass : GlassSurfaceStyle.solid);

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    Widget cardWidget;

    if (GlassDesignTokens.isDarkGlass(context) &&
        effectiveStyle == GlassSurfaceStyle.glass) {
      // Dark Mode Floating Refractive Glass Card (memakai package resmi + Rule 2 solid descendants)
      cardWidget = GlassContainer.card(
        useOwnLayer: true,
        padding: EdgeInsets.zero,
        surfaceStyle: GlassSurfaceStyle.glass,
        settings: GlassDesignTokens.darkPlatterSettings(context),
        shape: LiquidRoundedSuperellipse(borderRadius: radius.topLeft.x),
        color: tintColor,
        child: InheritedGlassSurfaceStyle(
          surfaceStyle: GlassSurfaceStyle.solid,
          child: content,
        ),
      );
    } else {
      // Light Mode asli atau Dark Mode Solid Adaptive Card (kontras maksimal untuk data finansial)
      cardWidget = Container(
        decoration: BoxDecoration(
          color: tintColor ?? scheme.surface,
          borderRadius: radius,
          border: border ??
              Border.all(
                color: isDark
                    ? scheme.outlineVariant.withValues(alpha: 0.6)
                    : const Color(0xFFF1F5F9),
                width: 1.2,
              ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      );
    }

    if (margin != null) {
      cardWidget = Padding(padding: margin!, child: cardWidget);
    }

    return cardWidget;
  }
}
