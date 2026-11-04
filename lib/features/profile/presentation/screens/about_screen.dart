import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../utils/profile_ui.dart';

/// Tentang TahanDulu: branding, versi, dokumen, lisensi.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.aboutTitle),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5EC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      AppAssets.illAboutApp,
                      height: 128,
                      fit: BoxFit.contain,
                      semanticLabel: 'TahanDulu',
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(
                        AppAssets.logo,
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          AppAssets.logo,
                          height: 72,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.appName,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          AppStrings.aboutTagline,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${AppStrings.aboutVersionPrefix} '
                            '${AppConstants.appVersion}',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary
                              .withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      AppStrings.aboutDescription,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    iconForeground: AppColors.secondary,
                    iconBackground: AppColors.secondarySoft,
                    asset: AppAssets.setTerms,
                    title: AppStrings.aboutTerms,
                    description: AppStrings.privacyPolicyDesc,
                    onTap: () => showInfoDialog(
                      context: context,
                      title: AppStrings.aboutTerms,
                      body: AppStrings.aboutTermsBody,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingsMenuRow(
                    iconForeground: AppColors.primary,
                    iconBackground: AppColors.primarySoft,
                    asset: AppAssets.setOpenSource,
                    title: AppStrings.aboutLicenses,
                    description: AppStrings.aboutLicensesDesc,
                    onTap: () => showInfoDialog(
                      context: context,
                      title: AppStrings.aboutLicenses,
                      body: AppStrings.aboutLicensesBody,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${AppStrings.aboutCopyright}\nSemua hak dilindungi.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
