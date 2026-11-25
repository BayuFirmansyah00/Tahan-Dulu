import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lgw;

import '../constants/glass_design_tokens.dart';
import 'app_radius.dart';
import 'app_colors.dart';

/// Permukaan daftar memakai dekorasi statis. Hanya panel mengambang mengambil
/// sampel piksel latar melalui perender Liquid Glass.
abstract final class Glass {
  static const duration = Duration(milliseconds: 190);
  static const curve = Curves.easeOutCubic;
  static const capsule = BorderRadius.all(Radius.circular(32));

  static bool accessible(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.highContrastOf(context);

  static Duration motion(BuildContext context) =>
      accessible(context) ? Duration.zero : duration;

  static BoxDecoration panel(
    BuildContext context, {
    BorderRadius? radius,
    Color? tint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final base = tint ?? scheme.surface;
    final solid = accessible(context);
    return BoxDecoration(
      borderRadius: radius ?? AppRadius.cardLarge,
      color: solid ? base : null,
      gradient: solid
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: .025),
                  base,
                ),
                base.withValues(alpha: .96),
                Color.alphaBlend(scheme.secondary.withValues(alpha: .08), base),
              ],
              stops: const [0, .46, 1],
            ),
      border: Border.all(color: solid ? scheme.outline : scheme.outlineVariant),
      boxShadow: solid
          ? null
          : const [
              BoxShadow(
                color: Color(0x0C163748),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
    );
  }
}

/// Latar berwarna lembut memberi kedalaman tanpa filter layar penuh.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.palette;
    final canvas = context.canvasColor;
    if (Glass.accessible(context)) {
      return ColoredBox(color: canvas, child: child);
    }
    if (Theme.of(context).brightness == Brightness.dark) {
      // Latar gelap bernuansa emerald & slate agar refraksi Liquid Glass tampak autentik.
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0C141B),
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.75),
            radius: 1.4,
            colors: [
              AppColors.primary.withValues(alpha: 0.16),
              const Color(0xFF101D28),
              const Color(0xFF0B1218),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: child,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            canvas,
            Color.alphaBlend(scheme.secondary.withValues(alpha: .065), canvas),
            Color.alphaBlend(scheme.tertiary.withValues(alpha: .05), canvas),
            canvas,
          ],
          stops: const [0, .35, .72, 1],
        ),
      ),
      child: child,
    );
  }
}

enum GlassQuality { high, balanced, low }

/// Dua jendela berturut-turut dengan raster lambat menurunkan kualitas untuk
/// sesi ini. Frame debug tidak mewakili biaya rendering pada perangkat.
class GlassQualityController extends StatefulWidget {
  const GlassQualityController({super.key, required this.child});
  final Widget child;

  @override
  State<GlassQualityController> createState() => _GlassQualityControllerState();
}

class _GlassQualityControllerState extends State<GlassQualityController> {
  static const preset = String.fromEnvironment(
    'GLASS_QUALITY',
    defaultValue: 'balanced',
  );
  late GlassQuality quality =
      GlassQuality.values.asNameMap()[preset] ?? GlassQuality.balanced;
  int frames = 0;
  int slow = 0;
  int slowWindows = 0;

  @override
  void initState() {
    super.initState();
    if (!kDebugMode) SchedulerBinding.instance.addTimingsCallback(_measure);
  }

  void _measure(List<FrameTiming> timings) {
    if (!mounted || quality == GlassQuality.low) return;
    for (final timing in timings) {
      frames++;
      if (timing.rasterDuration.inMicroseconds > 16667) slow++;
      if (frames < 60) continue;
      slowWindows = slow >= 10 ? slowWindows + 1 : 0;
      frames = 0;
      slow = 0;
      if (slowWindows >= 2) {
        setState(() => quality = GlassQuality.values[quality.index + 1]);
        slowWindows = 0;
        break;
      }
    }
  }

  @override
  void dispose() {
    if (!kDebugMode) SchedulerBinding.instance.removeTimingsCallback(_measure);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _QualityScope(quality: quality, child: widget.child);
}

class _QualityScope extends InheritedWidget {
  const _QualityScope({required this.quality, required super.child});
  final GlassQuality quality;

  @override
  bool updateShouldNotify(_QualityScope oldWidget) =>
      quality != oldWidget.quality;
}

/// Light Mode memakai dekorasi statis asli. Dark Mode memakai shader resmi
/// `GlassContainer` (`liquid_glass_widgets`) dengan `InheritedGlassSurfaceStyle.solid`
/// pada subtree agar elemen interaktif di dalamnya tidak mengalami double-refraction.
class FloatingGlass extends StatelessWidget {
  const FloatingGlass({
    super.key,
    required this.child,
    this.radius = Glass.capsule,
  });
  final Widget child;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    if (!GlassDesignTokens.isDarkGlass(context)) {
      return DecoratedBox(
        decoration: Glass.panel(context, radius: radius),
        child: child,
      );
    }

    final quality =
        context.dependOnInheritedWidgetOfExactType<_QualityScope>()?.quality ??
            GlassQuality.balanced;
    final effectiveQuality = switch (quality) {
      GlassQuality.high => lgw.GlassQuality.premium,
      GlassQuality.balanced => lgw.GlassQuality.standard,
      GlassQuality.low => lgw.GlassQuality.minimal,
    };

    return lgw.GlassContainer(
      useOwnLayer: true,
      quality: effectiveQuality,
      shape: lgw.LiquidRoundedSuperellipse(borderRadius: radius.topLeft.x),
      settings: GlassDesignTokens.darkPlatterSettings(context),
      child: lgw.InheritedGlassSurfaceStyle(
        surfaceStyle: lgw.GlassSurfaceStyle.solid,
        child: child,
      ),
    );
  }
}

extension GlassPalette on BuildContext {
  ColorScheme get palette => Theme.of(this).colorScheme;
  Color get canvasColor => Theme.of(this).scaffoldBackgroundColor;
  Color get warningInk => palette.brightness == Brightness.dark
      ? const Color(0xffffd695)
      : AppColors.warning;
  Color get warningFill => palette.brightness == Brightness.dark
      ? const Color(0xff483924)
      : const Color(0xfffaf0d9);
}

/// Isi dan hasil modal tetap dikelola oleh pemanggil.
/// Light Mode: Material modal sheet asli.
/// Dark Mode: Official `GlassModalSheet.show` dengan `InheritedGlassSurfaceStyle.solid`.
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool scrollContent = false,
}) {
  if (GlassDesignTokens.isDarkGlass(context)) {
    return lgw.GlassModalSheet.show<T>(
      context: context,
      detents: scrollContent
          ? const {lgw.GlassSheetDetent.medium, lgw.GlassSheetDetent.large}
          : const {lgw.GlassSheetDetent.medium},
      initialState: lgw.GlassSheetState.half,
      halfSize: 0.65,
      topBorderRadius: AppRadius.xl,
      dragIndicatorColor: Colors.white.withValues(alpha: 0.35),
      settings: GlassDesignTokens.darkOverlaySettings(context),
      expandedColor: const Color(0xEC16222E),
      expandedDarkColor: const Color(0xEC16222E),
      builder: (sheetContext) {
        final content = builder(sheetContext);
        final scrollProvider = lgw.ScrollControllerProvider.of(sheetContext);
        return lgw.InheritedGlassSurfaceStyle(
          surfaceStyle: lgw.GlassSurfaceStyle.solid,
          child: Material(
            type: MaterialType.transparency,
            child: scrollContent
                ? SingleChildScrollView(
                    controller: scrollProvider?.controller,
                    physics: scrollProvider?.physics,
                    child: content,
                  )
                : content,
          ),
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled || scrollContent,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    sheetAnimationStyle: Glass.accessible(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) {
      final content = builder(context);
      return FloatingGlass(
        radius: AppRadius.sheet,
        child: Material(
          type: MaterialType.transparency,
          child: scrollContent
              ? SingleChildScrollView(child: content)
              : content,
        ),
      );
    },
  );
}
