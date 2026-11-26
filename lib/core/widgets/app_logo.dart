import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Logo TahanDulu dari [AppAssets.logo].
/// Menampilkan ikon fallback bila asset gagal dimuat (mis. saat widget test).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 56});

  final double height;

  @override
  Widget build(BuildContext context) {
    final cacheHeight = (height * MediaQuery.devicePixelRatioOf(context))
        .ceil();
    return Image.asset(
      AppAssets.logo,
      height: height,
      fit: BoxFit.contain,
      cacheHeight: kReleaseMode ? cacheHeight : null,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.pause_circle_outline,
        size: height,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
