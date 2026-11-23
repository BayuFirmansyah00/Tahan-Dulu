import 'package:flutter/material.dart';
import 'package:liquid_glass_toolkit/liquid_glass_toolkit.dart';

import 'app_radius.dart';

/// Permukaan daftar memakai dekorasi statis. Hanya panel mengambang mengambil
/// sampel piksel latar melalui perender Liquid Glass.
abstract final class Glass {
  static const duration = Duration(milliseconds: 190);
  static const curve = Curves.easeOutCubic;
  static const capsule = BorderRadius.all(Radius.circular(32));

  static bool accessible(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) || MediaQuery.highContrastOf(context);

  static Duration motion(BuildContext context) =>
      accessible(context) ? Duration.zero : duration;

  static BoxDecoration panel(BuildContext context, {BorderRadius? radius, Color? tint}) {
    final scheme = Theme.of(context).colorScheme;
    final base = tint ?? scheme.surface;
    final solid = accessible(context);
    return BoxDecoration(
      borderRadius: radius ?? AppRadius.cardLarge,
      color: solid ? base : null,
      gradient: solid ? null : LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(scheme.onSurface.withValues(alpha: .025), base),
          base.withValues(alpha: .96),
          Color.alphaBlend(scheme.secondary.withValues(alpha: .08), base),
        ],
        stops: const [0, .46, 1],
      ),
      border: Border.all(color: solid ? scheme.outline : scheme.outlineVariant),
      boxShadow: solid ? null : const [BoxShadow(color: Color(0x0C163748), blurRadius: 10, offset: Offset(0, 3))],
    );
  }
}

enum GlassQuality { high, balanced, low }

/// Profil seimbang menjadi bawaan. Mode tinggi mengaktifkan refraksi jika tersedia.
class FloatingGlass extends StatelessWidget {
  const FloatingGlass({super.key, required this.child, this.radius = Glass.capsule});
  final Widget child;
  final BorderRadius radius;
  static const preset = String.fromEnvironment('GLASS_QUALITY', defaultValue: 'balanced');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quality = GlassQuality.values.asNameMap()[preset] ?? GlassQuality.balanced;
    if (Glass.accessible(context) || quality == GlassQuality.low) {
      return DecoratedBox(decoration: Glass.panel(context, radius: radius), child: child);
    }
    final high = quality == GlassQuality.high;
    final dark = scheme.brightness == Brightness.dark;
    return LiquidGlassSurface(
      quality: high ? LiquidGlassQuality.premium : LiquidGlassQuality.standard,
      foregroundColor: scheme.onSurface,
      borderRadius: radius,
      style: LiquidGlassStyle(
        blur: high ? 14 : 8, opacity: dark ? .86 : .72,
        tintColor: scheme.surface, borderColor: scheme.outlineVariant,
        saturation: 1.05, highlightOpacity: dark ? .08 : .24,
        rimLightIntensity: dark ? .12 : .24, specularIntensity: .16,
        enableRefraction: high, refractionStrength: .17,
        dispersion: .04, shadowBlur: 14, shadowOffset: const Offset(0, 4),
      ),
      child: child,
    );
  }
}
