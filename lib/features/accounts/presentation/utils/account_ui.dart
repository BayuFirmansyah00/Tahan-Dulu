import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/financial_account.dart';

/// Label jenis akun (Bahasa Indonesia).
String accountTypeLabel(AccountType type) {
  switch (type) {
    case AccountType.bank:
      return AppStrings.typeBank;
    case AccountType.digitalBank:
      return AppStrings.typeDigitalBank;
    case AccountType.ewallet:
      return AppStrings.typeEWallet;
  }
}

/// Visual per jenis akun (Aset PNG 3D + Material Icons fallback).
/// Bank: gedung/pembayaran bank. Bank Digital: transfer/ponsel. E-Wallet: dompet digital.
({IconData icon, String assetPath, Color foreground, Color background}) accountVisual(
  AccountType type,
) {
  switch (type) {
    case AccountType.bank:
      return (
        icon: Icons.account_balance_outlined,
        assetPath: AppAssets.instBank,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case AccountType.digitalBank:
      return (
        icon: Icons.smartphone_outlined,
        assetPath: AppAssets.txTransfer,
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      );
    case AccountType.ewallet:
      return (
        icon: Icons.account_balance_wallet_outlined,
        assetPath: AppAssets.instEwallet,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
  }
}
