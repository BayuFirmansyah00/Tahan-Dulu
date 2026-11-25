import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

import 'app_radius.dart';
import 'app_colors.dart';
import '../constants/glass_design_tokens.dart';

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

/// Profil seimbang menjadi bawaan. Mode tinggi mengaktifkan refraksi jika tersedia.
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
    final scheme = Theme.of(context).colorScheme;
    final quality =
        context.dependOnInheritedWidgetOfExactType<_QualityScope>()?.quality ??
        GlassQuality.balanced;
    if (Glass.accessible(context) || quality == GlassQuality.low) {
      return DecoratedBox(
        decoration: Glass.panel(context, radius: radius),
        child: child,
      );
    }
    final high = quality == GlassQuality.high;
    final dark = scheme.brightness == Brightness.dark;
    return LiquidGlassSurface(
      quality: high ? LiquidGlassQuality.premium : LiquidGlassQuality.standard,
      foregroundColor: scheme.onSurface,
      borderRadius: radius,
      style: LiquidGlassStyle(
        blur: GlassDesignTokens.clearPlatterBlur,
        opacity: dark
            ? GlassDesignTokens.clearPlatterDarkOpacity
            : GlassDesignTokens.clearPlatterOpacity,
        tintColor: dark ? const Color(0xFF142433) : Colors.white,
        borderColor: Colors.white.withValues(alpha: dark ? 0.16 : 0.28),
        saturation: 1.05,
        highlightOpacity: 0.20,
        rimLightIntensity: GlassDesignTokens.clearPlatterRimLight,
        specularIntensity: GlassDesignTokens.clearPlatterSpecular,
        enableRefraction: true,
        refractionStrength: high ? 0.38 : 0.26,
        dispersion: high ? GlassDesignTokens.clearPlatterChromaticAberration : 0.0,
        shadowBlur: 14,
        shadowOffset: const Offset(0, 4),
      ),
      child: child,
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
Future<T?> showGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool scrollContent = false,
}) {
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
