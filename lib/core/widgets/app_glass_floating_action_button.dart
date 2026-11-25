import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/glass_design_tokens.dart';
import '../theme/app_colors.dart';
import '../theme/glass.dart' hide GlassQuality;

/// Floating Action Button dengan sentuhan Liquid Glass.
///
/// Menyediakan touch target yang ergonomis (>= 52px), border halus,
/// aksen hijau emerald khas Tahan Dulu, dan umpan balik sentuhan spring.
class AppGlassFloatingActionButton extends StatelessWidget {
  const AppGlassFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.tooltip,
    this.heroTag,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Callback aksi saat FAB ditekan.
  final VoidCallback? onPressed;

  /// Ikon utama FAB.
  final Widget icon;

  /// Label teks opsional (untuk Extended FAB).
  final String? label;

  /// Tooltip aksesibilitas.
  final String? tooltip;

  /// Hero tag opsional untuk animasi transisi.
  final Object? heroTag;

  /// Warna latar kustom opsional.
  final Color? backgroundColor;

  /// Warna ikon dan teks kustom opsional.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReduced = GlassDesignTokens.isReducedMotion(context);

    final fgColor = foregroundColor ?? (isDark ? Colors.white : scheme.onPrimary);
    final bgColor = backgroundColor ?? scheme.primary;

    Widget fabContent;

    if (label != null && label!.isNotEmpty) {
      // --- Extended Glass FAB ---
      fabContent = Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: GlassDesignTokens.radiusCapsule,
          color: bgColor.withValues(alpha: isDark ? 0.85 : 0.92),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGlow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: GlassDesignTokens.radiusCapsule,
          child: InkWell(
            onTap: onPressed,
            borderRadius: GlassDesignTokens.radiusCapsule,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: fgColor, size: 20),
                  child: icon,
                ),
                const SizedBox(width: 8),
                Text(
                  label!,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // --- Circular Glass FAB (56x56) ---
      fabContent = SizedBox(
        width: 56,
        height: 56,
        child: GlassIsolationScope(
          defaultQuality: GlassQuality.premium,
          child: GlassIconButton(
            icon: IconTheme(
              data: IconThemeData(
                color: foregroundColor ?? AppColors.primary,
                size: 24,
              ),
              child: icon,
            ),
            onPressed: onPressed,
            shape: GlassIconButtonShape.circle,
            surfaceStyle: GlassSurfaceStyle.glass,
            style: GlassButtonStyle.prominent,
            tintColor: backgroundColor ??
                (isDark
                    ? const Color(0x0C142433)
                    : const Color(0x08FFFFFF)),
          ),
        ),
      );
    }

    if (tooltip != null) {
      fabContent = Tooltip(message: tooltip!, child: fabContent);
    }

    if (heroTag != null) {
      fabContent = Hero(tag: heroTag!, child: fabContent);
    }

    return AnimatedScale(
      scale: onPressed != null ? 1.0 : 0.95,
      duration: isReduced ? Duration.zero : GlassDesignTokens.durationFast,
      curve: GlassDesignTokens.curve,
      child: fabContent,
    );
  }
}
