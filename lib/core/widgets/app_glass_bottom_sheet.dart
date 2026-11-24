import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../constants/glass_design_tokens.dart';
import '../theme/app_radius.dart';
import '../theme/glass.dart';

/// Helper terpusat untuk menampilkan Modal Bottom Sheet bergaya Liquid Glass di Tahan Dulu.
///
/// **Keunggulan:**
/// - Menggunakan animasi spring dan fluid detent (setengah layar / layar penuh).
/// - Mengikuti **Rule 2**: Konten di dalam sheet dibungkus dalam `InheritedGlassSurfaceStyle(surfaceStyle: GlassSurfaceStyle.solid)`
///   agar elemen kontrol di dalamnya tidak mengalami distorsi refraksi ganda (double-refraction)
///   dan menghemat GPU budget di Android.
/// - Fallback mulus untuk aksesibilitas kontras tinggi atau reduced motion.
Future<T?> showAppGlassBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext sheetContext) builder,
  double halfSize = 0.5,
  double? fullSize,
  bool isDismissible = true,
  bool showDragIndicator = true,
}) {
  if (GlassDesignTokens.isHighContrast(context)) {
    // Fallback Material Bottom Sheet untuk mode kontras tinggi
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: builder(ctx),
        ),
      ),
    );
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final scheme = context.palette;

  return GlassModalSheet.show<T>(
    context: context,
    initialState: GlassSheetState.half,
    halfSize: halfSize,
    fullSize: fullSize,
    isDismissible: isDismissible,
    showDragIndicator: showDragIndicator,
    dragIndicatorColor: isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.2),
    topBorderRadius: AppRadius.xl,
    expandedColor: isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95),
    builder: (sheetContext) {
      // Mengikuti Rule 2 SKILL.md: elemen anak mengadopsi solid styling
      // agar tidak terjadi double refraction di atas sheet kaca
      return InheritedGlassSurfaceStyle(
        surfaceStyle: GlassSurfaceStyle.solid,
        child: Material(
          type: MaterialType.transparency,
          child: builder(sheetContext),
        ),
      );
    },
  );
}
