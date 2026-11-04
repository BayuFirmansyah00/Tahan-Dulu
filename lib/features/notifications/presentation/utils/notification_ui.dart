import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../data/models/app_notification.dart';
import '../../../../data/models/reminder_settings.dart';

/// Palet lokal halaman Notifikasi (Tahap 47).
///
/// Sengaja TIDAK mengubah [AppColors] global: emerald dipakai sebagai
/// identitas halaman ini saja agar tema kuning TahanDulu dan halaman
/// lain tidak terpengaruh.
abstract final class NotifColors {
  /// Background off-white bernuansa mint sangat lembut.
  static const Color background = Color(0xFFF4FAF6);

  /// Hero banner mint lembut.
  static const Color hero = Color(0xFFDFF3E8);
  static const Color heroBorder = Color(0xFFC9E9D6);

  /// Identitas halaman: emerald + navy.
  static const Color primary = Color(0xFF0E9F6E);
  static const Color primaryDark = Color(0xFF0B7A55);
  static const Color navy = Color(0xFF102A43);
  static const Color slate = Color(0xFF5B6B82);

  /// Kartu putih + border mint + shadow lembut.
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDDEEE5);
  static const Color chipInactive = Color(0xFFEAF5EF);

  /// Indikator baca.
  static const Color unreadDot = Color(0xFF0E9F6E);
  static const Color readDot = Color(0xFFCBD5E1);
}

/// Ikon lonceng 3D untuk hero (aset lokal terverifikasi ada di disk).
/// [NotifBellIcon] menyediakan fallback vektor bila berkas gagal muat.
abstract final class NotifAssets {
  static const String bell = AppAssets.setNotif;
}

/// Ikon kategori 3D notifikasi (audit alpha 15/10/2026: sudut
/// transparan, aman di atas tile pastel/putih).
/// Nama file aktual di `assets/icons/`; fallback Material memakai
/// [visualForCategory] bila berkas gagal dimuat.
String notificationCategoryAsset(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.salary:
      return AppAssets.ntfSalary;
    case NotificationCategory.savingsGoal:
      return AppAssets.ntfGoal;
    case NotificationCategory.tahandulu:
      return AppAssets.ntfBag;
    case NotificationCategory.savingsReminder:
      return AppAssets.ntfPiggy;
    case NotificationCategory.budget:
      return AppAssets.ntfBudget;
    case NotificationCategory.overspending:
      return AppAssets.ntfOverspend;
  }
}

/// Ikon kategori 3D dengan fallback ikon Material.
///
/// Selalu `Image.asset(..., BoxFit.contain)`; bila berkas gagal
/// dimuat, tampilkan ikon pastel dari [visualForCategory].
class NotifCategoryIcon extends StatelessWidget {
  const NotifCategoryIcon({super.key, required this.category, this.size = 46});

  final NotificationCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = visualForCategory(category);
    return AppImageIcon(
      assetPath: notificationCategoryAsset(category),
      size: size,
      fallbackIcon: visual.icon,
    );
  }
}

/// Pemetaan visual kategori notifikasi -> ikon + warna pastel.
class NotificationVisual {
  const NotificationVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}

NotificationVisual visualForCategory(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.salary:
      return const NotificationVisual(
        icon: Icons.account_balance_wallet_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case NotificationCategory.savingsGoal:
      return const NotificationVisual(
        icon: Icons.track_changes_outlined,
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      );
    case NotificationCategory.tahandulu:
      return const NotificationVisual(
        icon: Icons.shopping_bag_outlined,
        foreground: AppColors.error,
        background: Color(0xFFFEE2E2),
      );
    case NotificationCategory.savingsReminder:
      return const NotificationVisual(
        icon: Icons.savings_outlined,
        foreground: AppColors.warning,
        background: Color(0xFFFEF3C7),
      );
    case NotificationCategory.budget:
    case NotificationCategory.overspending:
      return const NotificationVisual(
        icon: Icons.warning_amber_outlined,
        foreground: AppColors.warning,
        background: Color(0xFFFEF3C7),
      );
  }
}

/// Pemetaan visual jenis pengingat -> ikon + warna pastel.
class ReminderVisual {
  const ReminderVisual({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}

ReminderVisual visualForReminder(ReminderType type) {
  switch (type) {
    case ReminderType.salary:
      return const ReminderVisual(
        icon: Icons.account_balance_wallet_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case ReminderType.savings:
      return const ReminderVisual(
        icon: Icons.savings_outlined,
        foreground: AppColors.warning,
        background: Color(0xFFFEF3C7),
      );
    case ReminderType.bills:
      return const ReminderVisual(
        icon: Icons.receipt_long_outlined,
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      );
    case ReminderType.budget:
      return const ReminderVisual(
        icon: Icons.monitor_heart_outlined,
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      );
    case ReminderType.tahandulu:
      return const ReminderVisual(
        icon: Icons.shopping_bag_outlined,
        foreground: AppColors.error,
        background: Color(0xFFFEE2E2),
      );
    case ReminderType.overspending:
      return const ReminderVisual(
        icon: Icons.warning_amber_outlined,
        foreground: AppColors.warning,
        background: Color(0xFFFEF3C7),
      );
  }
}

/// Aset ikon 3D per jenis pengingat (terverifikasi visual, latar putih).
/// Dipakai di atas kartu putih; fallback outline memakai [ReminderVisual].
String reminderAssetFor(ReminderType type) {
  switch (type) {
    case ReminderType.salary:
      return AppAssets.setWallet;
    case ReminderType.savings:
      return AppAssets.setSavingsPig;
    case ReminderType.bills:
      return AppAssets.setBills;
    case ReminderType.budget:
      return AppAssets.setBudget;
    case ReminderType.tahandulu:
      return AppAssets.setBag;
    case ReminderType.overspending:
      return AppAssets.setOverspend;
  }
}
