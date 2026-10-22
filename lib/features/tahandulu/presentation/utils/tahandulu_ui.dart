import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/purchase_consideration.dart';

/// Palet khusus fitur TahanDulu (Tahap 46, identitas kuning).
///
/// Sengaja TIDAK mengubah [AppColors] global agar halaman di luar
/// TahanDulu tidak terpengaruh. Kuning dipakai sebagai aksen
/// (hero, CTA, status aktif), bukan background seluruh halaman.
abstract final class TdColors {
  /// Background utama warm off-white / cream netral.
  static const Color background = Color(0xFFFFFDF7);

  /// Surface kartu: putih + cream sangat muda.
  static const Color card = Color(0xFFFFFFFF);
  static const Color creamCard = Color(0xFFFFF9E8);

  /// Primary accent kuning lembut + highlight.
  static const Color primary = Color(0xFFFFD65A);
  static const Color highlight = Color(0xFFFFE7A3);

  /// Teks utama navy + sekunder slate.
  static const Color navy = Color(0xFF102A43);
  static const Color slate = Color(0xFF5B6B82);

  /// Border tipis kontras lembut untuk kartu TahanDulu.
  static const Color border = Color(0xFFF0E6C6);

  /// Status dampak.
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFE11D48);
  static const Color dangerBg = Color(0xFFFFE4E6);
}

/// Aset ikon kategori 3D per [ProductCategory].
///
/// Satu ikon per kategori — jangan memakai satu ikon untuk semua.
/// Path terverifikasi ada di disk; [TdCategoryIcon] menyediakan
/// fallback ikon Material bila berkas gagal dimuat.
String productCategoryAsset(ProductCategory category) {
  switch (category) {
    case ProductCategory.fashion:
      return AppAssets.tdCatFashion;
    case ProductCategory.electronics:
      return AppAssets.tdCatElectronics;
    case ProductCategory.food:
      return AppAssets.tdCatFood;
    case ProductCategory.transport:
      return AppAssets.tdCatTransport;
    case ProductCategory.entertainment:
      return AppAssets.tdCatEntertainment;
    case ProductCategory.household:
      return AppAssets.tdCatHousehold;
    case ProductCategory.education:
      return AppAssets.tdCatEducation;
    case ProductCategory.others:
      return AppAssets.tdCatOthers;
  }
}

/// Label kategori produk (Bahasa Indonesia, satu sumber).
String productCategoryLabel(ProductCategory category) {
  switch (category) {
    case ProductCategory.fashion:
      return AppStrings.productCatFashion;
    case ProductCategory.electronics:
      return AppStrings.productCatElectronics;
    case ProductCategory.food:
      return AppStrings.productCatFood;
    case ProductCategory.transport:
      return AppStrings.productCatTransport;
    case ProductCategory.entertainment:
      return AppStrings.productCatEntertainment;
    case ProductCategory.household:
      return AppStrings.productCatHousehold;
    case ProductCategory.education:
      return AppStrings.productCatEducation;
    case ProductCategory.others:
      return AppStrings.productCatOthers;
  }
}

/// Visual kategori: ikon + pastel khas (tanpa emoji).
///
/// Tetap dipertahankan sebagai fallback bila aset 3D gagal dimuat.
({IconData icon, Color foreground, Color background}) productVisual(
  ProductCategory category,
) {
  switch (category) {
    case ProductCategory.fashion:
      return (
        icon: Icons.checkroom_outlined,
        foreground: const Color(0xFF8B5CF6),
        background: const Color(0xFFEEE9FE),
      );
    case ProductCategory.electronics:
      return (
        icon: Icons.devices_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case ProductCategory.food:
      return (
        icon: Icons.restaurant_outlined,
        foreground: AppColors.warning,
        background: const Color(0xFFFEF3C7),
      );
    case ProductCategory.transport:
      return (
        icon: Icons.directions_car_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case ProductCategory.entertainment:
      return (
        icon: Icons.movie_outlined,
        foreground: const Color(0xFF8B5CF6),
        background: const Color(0xFFEEE9FE),
      );
    case ProductCategory.household:
      return (
        icon: Icons.chair_outlined,
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      );
    case ProductCategory.education:
      return (
        icon: Icons.school_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case ProductCategory.others:
      return (
        icon: Icons.category_outlined,
        foreground: AppColors.textSecondary,
        background: AppColors.surfaceVariant,
      );
  }
}

/// Label tab status.
String considerationTabLabel(ConsiderationStatus status) {
  switch (status) {
    case ConsiderationStatus.considering:
      return AppStrings.tabWaiting;
    case ConsiderationStatus.wishlist:
      return AppStrings.tabWishlist;
    case ConsiderationStatus.bought:
    case ConsiderationStatus.cancelled:
      return AppStrings.tabDone;
  }
}

/// Durasi tunggu yang didukung (jam).
const List<int> waitOptionsHours = [24, 48, 168];

/// Label durasi: 24 -> "24 Jam", 168 -> "7 Hari".
String waitHoursLabel(int hours) {
  switch (hours) {
    case 24:
      return AppStrings.wait24;
    case 48:
      return AppStrings.wait48;
    case 168:
      return AppStrings.wait7d;
    default:
      return '$hours ${AppStrings.waitRemainingHours}';
  }
}

/// Teks sisa masa tunggu dari timestamp eksplisit.
/// "18:42:15" bila < 1 hari, "X hari lagi", atau "Selesai".
String formatWaitRemaining(DateTime endsAt, DateTime now) {
  final remaining = endsAt.difference(now);
  if (remaining.isNegative || remaining == Duration.zero) {
    return AppStrings.waitExpired;
  }
  if (remaining.inHours >= 24) {
    final days = remaining.inHours ~/ 24;
    return '$days ${AppStrings.waitRemainingDays}';
  }
  final h = remaining.inHours.toString().padLeft(2, '0');
  final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
  final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Teks "Menunggu X" ringkas untuk kartu (jam/hari).
String formatWaitShort(DateTime endsAt, DateTime now) {
  final remaining = endsAt.difference(now);
  if (remaining.isNegative || remaining == Duration.zero) {
    return AppStrings.waitExpired;
  }
  if (remaining.inHours >= 24) {
    return 'Menunggu ${remaining.inHours ~/ 24} hari';
  }
  return 'Menunggu ${remaining.inHours} jam';
}
