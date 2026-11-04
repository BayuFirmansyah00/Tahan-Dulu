import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../data/models/purchase_consideration.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../utils/tahandulu_ui.dart';

/// Navigasi bawah standar semua layar TahanDulu (tanpa tab aktif).
void tahanDuluBottomNavTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRoutes.dashboard);
    case 1:
      context.push(AppRoutes.transactions);
    case 2:
      context.push(AppRoutes.transactionRecordMethod);
    case 3:
      context.push(AppRoutes.goals);
    case 4:
      context.push(AppRoutes.settings);
  }
}

/// Scaffold standar TahanDulu: AppBar kembali + konten 480px + nav.
///
/// Tahap 46: background cream netral khas TahanDulu
/// ([TdColors.background]); struktur, route, dan bottom nav global
/// tidak diubah.
class TahanDuluScaffold extends StatelessWidget {
  const TahanDuluScaffold({
    super.key,
    required this.title,
    required this.child,
    this.bottomButton,
  });

  final String title;
  final Widget child;
  final Widget? bottomButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TdColors.background,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(title),
        backgroundColor: TdColors.background,
      ),
      bottomNavigationBar: DashboardBottomNav(
        onTap: (i) => tahanDuluBottomNavTap(context, i),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(child: child),
                if (bottomButton != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: bottomButton!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ikon kategori 3D dengan fallback ikon Material.
///
/// Selalu `Image.asset(..., BoxFit.contain)`; bila berkas gagal
/// dimuat, tampilkan ikon pastel dari [productVisual] — tidak pernah
/// broken-image.
class TdCategoryIcon extends StatelessWidget {
  const TdCategoryIcon({
    super.key,
    required this.category,
    this.size = 40,
    this.iconSize,
  });

  final ProductCategory category;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final visual = productVisual(category);
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        productCategoryAsset(category),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: visual.background,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(
            visual.icon,
            color: visual.foreground,
            size: iconSize ?? size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Ilustrasi header hero dengan fallback ilustrasi pendukung.
///
/// `BoxFit.contain`, tidak pernah memenuhi layar; bila header gagal
/// dimuat, pakai [fallbackAsset], lalu ikon Material.
class TdHeroImage extends StatelessWidget {
  const TdHeroImage({
    super.key,
    required this.asset,
    this.fallbackAsset,
    this.height = 120,
    this.width = 140,
  });

  final String asset;
  final String? fallbackAsset;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    Widget materialFallback() => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: TdColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TdColors.border),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: TdColors.warning,
        size: 48,
      ),
    );

    return Image.asset(
      asset,
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (fallbackAsset == null) return materialFallback();
        return Image.asset(
          fallbackAsset!,
          height: height,
          width: width,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => materialFallback(),
        );
      },
    );
  }
}

/// Gambar produk berlapis: network -> file lokal -> ikon kategori 3D
/// -> placeholder pastel. Tidak pernah menampilkan broken-image
/// sebagai desain final.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageRef,
    required this.category,
    this.height = 72,
    this.width,
    this.borderRadius = 12,
    this.iconSize = 40,
  });

  final String? imageRef;
  final ProductCategory category;
  final double height;
  final double? width;
  final double borderRadius;
  final double iconSize;

  Widget _categoryFallback(BuildContext context) {
    final visual = productVisual(category);
    final w = width ?? double.infinity;
    return Container(
      height: height,
      width: w,
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: TdColors.border),
      ),
      child: Center(
        child: TdCategoryIcon(category: category, size: iconSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = imageRef?.trim() ?? '';
    if (ref.startsWith('http://') || ref.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          ref,
          height: height,
          width: width ?? double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _categoryFallback(context),
        ),
      );
    }
    if (ref.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(ref),
          height: height,
          width: width ?? double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _categoryFallback(context),
        ),
      );
    }
    return _categoryFallback(context);
  }
}

/// Kartu putih standar TahanDulu: radius 16–20, border tipis lembut,
/// shadow halus.
class TdCard extends StatelessWidget {
  const TdCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = TdColors.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TdColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F102A43),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Header ilustrasi kecil untuk layar form/analisis (opsional).
class TdHeaderArt {
  TdHeaderArt._();

  /// Header yang tersedia — semua terverifikasi ada di disk.
  static const String list = AppAssets.tdHeaderList;
  static const String add = AppAssets.tdHeaderAdd;
  static const String link = AppAssets.tdHeaderLink;
  static const String analysis = AppAssets.tdHeaderAnalysis;
  static const String simulate = AppAssets.tdHeaderSimulate;
  static const String wait = AppAssets.tdHeaderWait;
}
