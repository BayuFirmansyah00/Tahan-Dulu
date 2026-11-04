import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import 'app_icons.dart';

/// Widget terpusat untuk merender seluruh ikon UI aplikasi TahanDulu
/// menggunakan aset PNG 3D transparan dari folder `assets/icons/`.
///
/// Fitur:
/// - Mempertahankan aspect ratio 1:1 (default `BoxFit.contain`).
/// - Mendukung pengaturan ukuran seragam [size] atau eksplisit [width] & [height].
/// - Mendukung [opacity] (0.0 sampai 1.0) untuk state nonaktif tanpa merusak piksel.
/// - Warna asli 3D tetap utuh secara default ([color] bernilai null).
/// - Mendukung [color] & [blendMode] jika mode monokrom/tint eksplisit dibutuhkan.
/// - Mendukung aksesibilitas semantik penuh via [semanticLabel] atau [excludeSemantics].
/// - Memiliki mekanisme fallback [AppIconFallback] bila aset gagal dimuat.
class AppImageIcon extends StatelessWidget {
  const AppImageIcon({
    super.key,
    required this.assetPath,
    this.size = 24.0,
    this.width,
    this.height,
    this.opacity = 1.0,
    this.fit = BoxFit.contain,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.semanticLabel,
    this.excludeSemantics = false,
    this.fallbackIcon = Icons.category_outlined,
  });

  /// Path lengkap berkas aset gambar, disarankan memakai konstanta [AppAssets].
  final String assetPath;

  /// Ukuran sisi persegi seragam (default: 24 dp).
  final double size;

  /// Lebar eksplisit (opsional jika berbeda dari [size]).
  final double? width;

  /// Tinggi eksplisit (opsional jika berbeda dari [size]).
  final double? height;

  /// Tingkat transparansi (0.0 hingga 1.0).
  final double opacity;

  /// Mode scaling gambar (default: BoxFit.contain).
  final BoxFit fit;

  /// Filter warna opsional.
  ///
  /// PERHATIAN: Biarkan null agar warna 3D asli PNG tidak tertimpa warna flat.
  final Color? color;

  /// Mode blending jika [color] ditentukan (default: BlendMode.srcIn).
  final BlendMode blendMode;

  /// Label semantik untuk pembaca layar (TalkBack / VoiceOver).
  final String? semanticLabel;

  /// Mengabaikan semantik jika ikon murni dekoratif (default: false).
  final bool excludeSemantics;

  /// Ikon Material sementara bila berkas aset PNG gagal dimuat.
  /// CATATAN: Ini adalah fallback transisi sementara.
  final IconData fallbackIcon;

  double get _effectiveWidth => width ?? size;
  double get _effectiveHeight => height ?? size;

  @override
  Widget build(BuildContext context) {
    if (assetPath.isEmpty) {
      return _buildFallback();
    }

    Widget imageWidget = Image.asset(
      assetPath,
      width: _effectiveWidth,
      height: _effectiveHeight,
      fit: fit,
      color: color,
      colorBlendMode: color != null ? blendMode : null,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('AppImageIcon: Gagal memuat aset "$assetPath": $error');
        return _buildFallback();
      },
    );

    final clampedOpacity = opacity.clamp(0.0, 1.0);
    if (clampedOpacity < 1.0) {
      imageWidget = Opacity(
        opacity: clampedOpacity,
        child: imageWidget,
      );
    }

    if (excludeSemantics) {
      return ExcludeSemantics(child: imageWidget);
    }

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(
        label: semanticLabel,
        image: true,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    return AppIconFallback(
      icon: fallbackIcon,
      size: _effectiveWidth,
    );
  }
}

/// Tombol kembali AppBar standar aplikasi TahanDulu menggunakan [AppAssets.navBack].
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.size = 24.0,
    this.tooltip = 'Kembali',
  });

  final VoidCallback? onPressed;
  final double size;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AppImageIcon(
        assetPath: AppAssets.navBack,
        size: size,
        semanticLabel: tooltip,
      ),
      tooltip: tooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}

