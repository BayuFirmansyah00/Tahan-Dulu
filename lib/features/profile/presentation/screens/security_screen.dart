import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../utils/profile_ui.dart';

/// Keamanan Akun: metode login aktual sesi, ubah sandi, sesi, keluar.
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      icon: Icons.logout_outlined,
      iconForeground: AppColors.error,
      iconBackground: const Color(0xFFFEE2E2),
      title: AppStrings.logoutDialogTitle,
      message: AppStrings.logoutDialogBody,
      cancelLabel: AppStrings.logoutCancel,
      confirmLabel: AppStrings.logoutConfirm,
    );
    if (!confirmed) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final method = auth.loginMethod;
    final email = auth.user?.email;

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text(AppStrings.securityTitle),
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
                    asset: AppAssets.illAccountSecurity,
                    semanticLabel: 'Akun Kamu Aman',
                    fallbackIcon: Icons.shield_outlined,
                  ),
                  const SizedBox(height: 16),
                  const ProfileSectionHeader(
                    title: AppStrings.securityLoginSection,
                  ),
                  const SizedBox(height: 8),
                  if (method == null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.cardLarge,
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.securityNoSessionTitle,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.securityNoSessionDesc,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: const Text(
                              AppStrings.securityLoginAction,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SettingsMenuRow(
                      icon: method == 'google'
                          ? Icons.g_mobiledata_outlined
                          : Icons.email_outlined,
                      iconForeground: AppColors.secondary,
                      iconBackground: AppColors.secondarySoft,
                      asset: method == 'google' ? AppAssets.setGoogle : null,
                      title: method == 'google'
                          ? AppStrings.securityLoginGoogle
                          : AppStrings.securityLoginEmail,
                      description: email ?? AppStrings.profileEmailUnavailable,
                      badge: AppStrings.securityActiveBadge,
                      badgeColor: AppColors.primary,
                      onTap: () => showInfoDialog(
                        context: context,
                        title: method == 'google'
                            ? AppStrings.securityLoginGoogle
                            : AppStrings.securityLoginEmail,
                        body: AppStrings.securityMethodInfoBody,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (method == 'email')
                      SettingsMenuRow(
                        icon: Icons.lock_outline,
                        iconForeground: AppColors.warning,
                        iconBackground: const Color(0xFFFEF3C7),
                        title: AppStrings.securityChangePassword,
                        description: AppStrings.securityChangePasswordDesc,
                        onTap: () => showInfoDialog(
                          context: context,
                          title: AppStrings
                              .securityPasswordUnavailableTitle,
                          body: AppStrings.securityPasswordUnavailableBody,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.cardLarge,
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: Text(
                          AppStrings.securityGooglePasswordNote,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 8),
                    SettingsMenuRow(
                      icon: Icons.devices_outlined,
                      iconForeground: AppColors.secondary,
                      iconBackground: AppColors.secondarySoft,
                      title: AppStrings.securitySessions,
                      description: AppStrings.securitySessionsDesc,
                      badge: AppStrings.appSettingsSoonBadge,
                      onTap: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text(AppStrings.securitySessionsSoon),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const ProfileSectionHeader(
                    title: AppStrings.securityAccountSection,
                  ),
                  const SizedBox(height: 8),
                  SettingsMenuRow(
                    icon: Icons.logout_outlined,
                    iconForeground: AppColors.error,
                    iconBackground: const Color(0xFFFEE2E2),
                    asset: AppAssets.setLogoutIcon,
                    title: AppStrings.securityLogout,
                    titleColor: AppColors.error,
                    description: AppStrings.securityLogoutDesc,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                  const SizedBox(height: 12),
                  const SettingsBanner(
                    asset: AppAssets.illSecurityTips,
                    semanticLabel: 'Tips Keamanan',
                    fallbackIcon: Icons.lightbulb_outline,
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
