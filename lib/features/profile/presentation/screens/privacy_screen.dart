import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../utils/profile_ui.dart';

/// Privasi: kebijakan, penggunaan data, hapus akun (konfirmasi jujur).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      assetPath: AppAssets.setDeleteAccount,
      icon: Icons.delete_outline,
      iconForeground: AppColors.error,
      iconBackground: const Color(0xFFFEE2E2),
      title: AppStrings.deleteDialogTitle,
      message: AppStrings.deleteDialogBody,
      cancelLabel: AppStrings.logoutCancel,
      confirmLabel: AppStrings.deleteConfirm,
    );
    if (!confirmed || !context.mounted) return;
    // Backend belum tersedia: jangan mengklaim penghapusan berhasil.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.privacyDeleteUnavailable),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.privacyTitle),
        flexibleSpace: const AppBarMintCorner(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SettingsBanner(
                    asset: AppAssets.illPrivacy,
                    semanticLabel: 'Privasi Kamu Penting',
                    fallbackIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 16),
                  const ProfileSectionHeader(
                    title: AppStrings.privacyDataSection,
                  ),
                  const SizedBox(height: 8),
                  SettingsMenuRow(
                    iconForeground: AppColors.secondary,
                    iconBackground: AppColors.secondarySoft,
                    asset: AppAssets.setPrivacyPolicy,
                    title: AppStrings.privacyPolicy,
                    description: AppStrings.privacyPolicyDesc,
                    onTap: () => showInfoDialog(
                      context: context,
                      title: AppStrings.privacyPolicy,
                      body: AppStrings.privacyPolicyBody,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingsMenuRow(
                    iconForeground: AppColors.error,
                    iconBackground: const Color(0xFFFEE2E2),
                    asset: AppAssets.setDataUsage,
                    title: AppStrings.privacyDataUsage,
                    description: AppStrings.privacyDataUsageDesc,
                    onTap: () => showInfoDialog(
                      context: context,
                      title: AppStrings.privacyDataUsage,
                      body: AppStrings.privacyDataUsageBody,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingsMenuRow(
                    iconForeground: AppColors.error,
                    iconBackground: const Color(0xFFFEE2E2),
                    asset: AppAssets.setDeleteAccount,
                    title: AppStrings.privacyDelete,
                    titleColor: AppColors.error,
                    description: AppStrings.privacyDeleteDesc,
                    onTap: () => _confirmDelete(context),
                  ),
                  const SizedBox(height: 12),
                  const SettingsBanner(
                    asset: AppAssets.illPrivacyDataSafe,
                    semanticLabel: 'Data kamu aman bersama kami',
                    fallbackIcon: Icons.verified_user_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
