import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/glass_design_tokens.dart';
import '../theme/app_colors.dart';
import 'app_image_icon.dart';

/// Gaya untuk tindakan hapus atau batalkan yang memerlukan konfirmasi.
ButtonStyle destructiveButtonStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return ElevatedButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError);
}

/// Tombol utama TahanDulu. Gunakan untuk semua CTA primer.
/// Warna default emerald; override opsional untuk kasus desain khusus
/// (mis. tombol Login dark navy) — tetap backward-compatible.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.assetPath,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final String? assetPath;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final childWidget = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor ?? Colors.white,
              semanticsLabel: label,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  color: GlassDesignTokens.isDarkGlass(context)
                      ? (foregroundColor ?? Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GlassDesignTokens.isDarkGlass(context)
                      ? TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: foregroundColor ?? Colors.white,
                        )
                      : null,
                ),
              ),
            ],
          );

    if (GlassDesignTokens.isDarkGlass(context)) {
      final disabled = isLoading || onPressed == null;
      final baseTint = backgroundColor ?? AppColors.primary;
      return SizedBox(
        height: 50,
        width: double.infinity,
        child: GlassButton.custom(
          useOwnLayer: true,
          onTap: disabled ? () {} : onPressed!,
          enabled: !disabled,
          style: GlassButtonStyle.filled,
          tintColor: baseTint.withValues(alpha: disabled ? 0.45 : 0.85),
          settings: GlassDesignTokens.darkPlatterSettings(context),
          shape: const LiquidRoundedSuperellipse(borderRadius: 14),
          child: Center(child: childWidget),
        ),
      );
    }

    final style = (backgroundColor != null || foregroundColor != null)
        ? ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          )
        : null;
    return ElevatedButton(
      style: style,
      onPressed: isLoading ? null : onPressed,
      child: childWidget,
    );
  }
}

/// Tombol sekunder (outline).
class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.assetPath,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? assetPath;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foregroundColor ?? scheme.primary;
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
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
            color: GlassDesignTokens.isDarkGlass(context) ? fg : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GlassDesignTokens.isDarkGlass(context)
                ? TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: fg,
                  )
                : null,
          ),
        ),
      ],
    );

    if (GlassDesignTokens.isDarkGlass(context)) {
      final disabled = onPressed == null;
      return SizedBox(
        height: 50,
        width: double.infinity,
        child: GlassButton.custom(
          useOwnLayer: true,
          onTap: disabled ? () {} : onPressed!,
          enabled: !disabled,
          style: GlassButtonStyle.transparent,
          tintColor: const Color(0x16FFFFFF),
          settings: GlassDesignTokens.darkPlatterSettings(context),
          shape: const LiquidRoundedSuperellipse(borderRadius: 14),
          child: Center(child: row),
        ),
      );
    }

    final style = foregroundColor != null
        ? OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            side: BorderSide(color: foregroundColor!),
          )
        : null;
    return OutlinedButton(
      style: style,
      onPressed: onPressed,
      child: row,
    );
  }
}
