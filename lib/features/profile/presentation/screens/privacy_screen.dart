import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../utils/account_security_dialogs.dart';
import '../utils/profile_ui.dart';

/// Privasi: kebijakan, penggunaan data, hapus akun permanen terverifikasi.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.privacyTitle),
        flexibleSpace: const AppBarMintCorner(),
      ),
      body: GlassBackdrop(child: SafeArea(
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
                    iconForeground: context.palette.secondary,
                    iconBackground: context.palette.secondaryContainer,
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
                    iconForeground: context.palette.error,
                    iconBackground: context.palette.errorContainer,
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
                    iconForeground: context.palette.error,
                    iconBackground: context.palette.errorContainer,
                    asset: AppAssets.setDeleteAccount,
                    title: AppStrings.privacyDelete,
                    titleColor: context.palette.error,
                    description: AppStrings.privacyDeleteDesc,
                    onTap: () => showDeleteAccountFlow(context, ref),
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
      )),
    );
  }
}
