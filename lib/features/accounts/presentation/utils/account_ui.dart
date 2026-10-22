import 'package:flutter/material.dart';

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

/// Visual per jenis akun (Material Icons, tanpa emoji).
/// Bank: gedung bank. Bank Digital: ponsel. E-Wallet: dompet digital.
({IconData icon, Color foreground, Color background}) accountVisual(
  AccountType type,
) {
  switch (type) {
    case AccountType.bank:
      return (
        icon: Icons.account_balance_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case AccountType.digitalBank:
      return (
        icon: Icons.smartphone_outlined,
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      );
    case AccountType.ewallet:
      return (
        icon: Icons.account_balance_wallet_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
  }
}
