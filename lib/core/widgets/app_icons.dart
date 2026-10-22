import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../../data/models/financial_account.dart';
import '../../data/models/financial_goal.dart';
import '../../data/models/transaction_model.dart';

/// Aset ikon 3D per kategori transaksi (enum).
/// String kosong berarti tidak ada aset khusus -> fallback outline.
String txIconForCategory(TransactionCategory category) {
  switch (category) {
    case TransactionCategory.food:
      return AppAssets.txFood;
    case TransactionCategory.transport:
      return AppAssets.txTransport;
    case TransactionCategory.shopping:
      return AppAssets.txShopping;
    case TransactionCategory.entertainment:
      return AppAssets.txEntertainment;
    case TransactionCategory.bills:
      return AppAssets.txBills;
    case TransactionCategory.education:
      return AppAssets.txEducation;
    case TransactionCategory.salary:
      return AppAssets.txArrowUp;
    case TransactionCategory.bonus:
      return AppAssets.txGift;
    case TransactionCategory.others:
      return '';
  }
}

/// Aset ikon 3D per label kategori string (data lama/seed).
/// Fallback panah arah sesuai jenis bila label tak dikenal.
String txIconForLabel(String? label, TransactionType type) {
  final text = (label ?? '').toLowerCase();
  if (text.contains('makan') || text.contains('food')) {
    return AppAssets.txFood;
  }
  if (text.contains('belanja') ||
      text.contains('shopping') ||
      text.contains('kebutuhan')) {
    return AppAssets.txShopping;
  }
  if (text.contains('transport')) return AppAssets.txTransport;
  if (text.contains('hibur') || text.contains('entertain')) {
    return AppAssets.txEntertainment;
  }
  if (text.contains('tagih') || text.contains('bill')) {
    return AppAssets.txBills;
  }
  if (text.contains('pendidik') || text.contains('educat')) {
    return AppAssets.txEducation;
  }
  if (text.contains('sehat') || text.contains('health')) {
    return AppAssets.txHealth;
  }
  if (text.contains('invest')) return AppAssets.txInvestment;
  if (text.contains('tabung') || text.contains('saving')) {
    return AppAssets.txSavings;
  }
  return type == TransactionType.income
      ? AppAssets.txArrowUp
      : AppAssets.txArrowDown;
}

/// Aset ikon 3D per kategori target.
String goalIconForCategory(GoalCategory category) {
  switch (category) {
    case GoalCategory.investment:
      return AppAssets.goalPiggy;
    case GoalCategory.savings:
      return AppAssets.goalSavings;
    case GoalCategory.house:
      return AppAssets.goalHouse;
    case GoalCategory.vehicle:
      return AppAssets.goalVehicle;
    case GoalCategory.education:
      return AppAssets.goalEducation;
    case GoalCategory.gadget:
      return AppAssets.goalGadget;
    case GoalCategory.holiday:
      return AppAssets.goalHoliday;
    case GoalCategory.emergency:
      return AppAssets.goalEmergency;
    case GoalCategory.others:
      return AppAssets.goalOthers;
  }
}

/// Aset placeholder per jenis akun (pengganti sementara logo resmi
/// penyedia; lihat [AccountProviderIcon]). Siap dipetakan ke katalog
/// logo BCA/BRI/Jago/DANA/dll saat aset valid tersedia.
String accountIconForType(AccountType type) {
  switch (type) {
    case AccountType.bank:
      return AppAssets.txBills;
    case AccountType.digitalBank:
      return AppAssets.txArrowTransfer;
    case AccountType.ewallet:
      return AppAssets.txWallet;
  }
}

/// Fallback outline standar bila aset tidak cocok/tidak termuat.
class AppIconFallback extends StatelessWidget {
  const AppIconFallback({
    super.key,
    this.icon = Icons.category_outlined,
    this.foreground = AppColors.secondary,
    this.background = AppColors.secondarySoft,
    this.size = 44,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: foreground, size: size * 0.5),
    );
  }
}

/// Ikon kategori transaksi 3D + fallback outline.
/// Aset PNG transparan ditampilkan utuh (contain, tanpa crop).
class CategoryIcon extends StatelessWidget {
  const CategoryIcon._({
    required this.asset,
    required this.fallbackIcon,
    this.size = 44,
  });

  factory CategoryIcon.forCategory(
    TransactionCategory category, {
    double size = 44,
  }) {
    return CategoryIcon._(
      asset: txIconForCategory(category),
      fallbackIcon: Icons.category_outlined,
      size: size,
    );
  }

  factory CategoryIcon.forLabel(
    String? label,
    TransactionType type, {
    double size = 44,
  }) {
    return CategoryIcon._(
      asset: txIconForLabel(label, type),
      fallbackIcon: type == TransactionType.income
          ? Icons.arrow_upward
          : Icons.arrow_downward,
      size: size,
    );
  }

  factory CategoryIcon.forGoal(
    GoalCategory category, {
    double size = 52,
  }) {
    return CategoryIcon._(
      asset: goalIconForCategory(category),
      fallbackIcon: Icons.flag_outlined,
      size: size,
    );
  }

  final String asset;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (asset.isEmpty) {
      return AppIconFallback(icon: fallbackIcon, size: size);
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          AppIconFallback(icon: fallbackIcon, size: size),
    );
  }
}

/// Panah arah pemasukan/pengeluaran 3D.
class TransactionTypeIcon extends StatelessWidget {
  const TransactionTypeIcon({
    super.key,
    required this.type,
    this.size = 44,
  });

  final TransactionType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      type == TransactionType.income
          ? AppAssets.txArrowUp
          : AppAssets.txArrowDown,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => AppIconFallback(
        icon: type == TransactionType.income
            ? Icons.arrow_upward
            : Icons.arrow_downward,
        foreground: type == TransactionType.income
            ? AppColors.primary
            : AppColors.error,
        background: type == TransactionType.income
            ? AppColors.primarySoft
            : AppColors.dangerSoft,
        size: size,
      ),
    );
  }
}

/// Logo penyedia rekening: placeholder terstruktur per jenis akun.
/// BUKAN logo resmi — diganti katalog logo valid bila tersedia.
class AccountProviderIcon extends StatelessWidget {
  const AccountProviderIcon({
    super.key,
    required this.type,
    this.institutionName,
    this.size = 44,
  });

  final AccountType type;
  final String? institutionName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      accountIconForType(type),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          AppIconFallback(size: size),
    );
  }
}
