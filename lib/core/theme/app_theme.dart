import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final canvas = dark ? const Color(0xff131c24) : AppColors.background;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: dark ? const Color(0xff9bdace) : AppColors.primary,
      secondary: dark ? const Color(0xffb7cfed) : AppColors.secondary,
      tertiary: dark ? const Color(0xffd3beef) : AppColors.accentPurple,
      primaryContainer: dark
          ? const Color(0xff264b44)
          : const Color(0xffdceee7),
      onPrimaryContainer: dark
          ? const Color(0xffd1eee5)
          : const Color(0xff153f37),
      secondaryContainer: dark
          ? const Color(0xff2d4057)
          : const Color(0xffe0eaf5),
      tertiaryContainer: dark
          ? const Color(0xff433b53)
          : const Color(0xffeae4f2),
      errorContainer: dark ? const Color(0xff58303b) : const Color(0xfff9e3e6),
      surface: dark ? const Color(0xff202d38) : AppColors.surface,
      onSurface: dark ? const Color(0xffedf4f6) : AppColors.textPrimary,
      onSurfaceVariant: dark
          ? const Color(0xffbfccd3)
          : AppColors.textSecondary,
      outlineVariant: dark ? const Color(0xff45525c) : AppColors.border,
      error: dark ? const Color(0xffffacb8) : AppColors.error,
    );
    final outline = BorderSide(color: scheme.outlineVariant);
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.cardLarge,
      side: outline,
    );
    final field = OutlineInputBorder(
      borderRadius: AppRadius.button,
      borderSide: BorderSide(color: scheme.outline),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme
        .merge(AppTypography.textTheme)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    return base.copyWith(
      textTheme: text.copyWith(
        bodySmall: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      scaffoldBackgroundColor: canvas,
      dividerColor: scheme.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: shape,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
              textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
            ).copyWith(
              backgroundBuilder: (context, states, child) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.button,
                  gradient: states.contains(WidgetState.disabled)
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x13ffffff),
                            Colors.transparent,
                            Color(0x10000000),
                          ],
                        ),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          side: outline,
          backgroundColor: scheme.surface,
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          backgroundColor: scheme.surface.withValues(alpha: .72),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .72)),
          shape: const CircleBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: const StadiumBorder(),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: outline,
        selectedColor: scheme.primaryContainer,
        backgroundColor: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: field,
        enabledBorder: field,
        focusedBorder: field.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: shape,
        elevation: 3,
      ),
      popupMenuTheme: dark
          ? PopupMenuThemeData(
              color: const Color(0xEC182532),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            )
          : null,
      dropdownMenuTheme: dark
          ? DropdownMenuThemeData(
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(
                  const Color(0xEC182532),
                ),
                surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
            )
          : null,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sheet,
          side: outline,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
