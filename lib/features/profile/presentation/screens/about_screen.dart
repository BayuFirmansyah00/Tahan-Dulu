import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../utils/profile_ui.dart';

/// Tentang TahanDulu: branding, versi, dokumen, lisensi.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: context.canvasColor,
      extendBodyBehindAppBar: GlassDesignTokens.isDarkGlass(context),
      appBar: const AppAdaptiveAppBar(
        leading: AppBackButton(),
        title: Text(AppStrings.aboutTitle),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: context.palette.primaryContainer,
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
                              Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: context.palette.primary,
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
                            color: context.palette.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${AppStrings.aboutVersionPrefix} '
                            '${AppConstants.appVersion}',
                            style: textTheme.labelLarge?.copyWith(
                              color: context.palette.primary,
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
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.palette.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: context.palette.onSurface
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
                    iconForeground: context.palette.secondary,
                    iconBackground: context.palette.secondaryContainer,
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
                    iconForeground: context.palette.primary,
                    iconBackground: context.palette.primaryContainer,
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
                      color: context.palette.onSurfaceVariant,
                    ),
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
