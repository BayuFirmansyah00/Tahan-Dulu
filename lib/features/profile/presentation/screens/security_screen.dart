import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../utils/account_security_dialogs.dart';
import '../utils/profile_ui.dart';

/// Keamanan Akun: metode login aktual sesi, ubah sandi, sesi, keluar.
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      assetPath: AppAssets.setLogoutIcon,
      icon: Icons.logout_outlined,
      iconForeground: context.palette.error,
      iconBackground: context.palette.errorContainer,
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
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.securityTitle),
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
                      decoration: Glass.panel(context, radius: AppRadius.cardLarge),
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
                      iconForeground: context.palette.secondary,
                      iconBackground: context.palette.secondaryContainer,
                      asset: method == 'google' ? AppAssets.setGoogle : null,
                      title: method == 'google'
                          ? AppStrings.securityLoginGoogle
                          : AppStrings.securityLoginEmail,
                      description: email ?? AppStrings.profileEmailUnavailable,
                      badge: AppStrings.securityActiveBadge,
                      badgeColor: context.palette.primary,
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
                        asset: AppAssets.setSecurity,
                        icon: Icons.lock_outline,
                        iconForeground: context.warningInk,
                        iconBackground: context.warningFill,
                        title: AppStrings.securityChangePassword,
                        description: AppStrings.securityChangePasswordDesc,
                        onTap: () => showChangePasswordBottomSheet(context, ref),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: Glass.panel(context, radius: AppRadius.cardLarge),
                        child: Text(
                          AppStrings.securityGooglePasswordNote,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    const SizedBox(height: 8),
                    SettingsMenuRow(
                      asset: AppAssets.setSession,
                      icon: Icons.devices_outlined,
                      iconForeground: context.palette.secondary,
                      iconBackground: context.palette.secondaryContainer,
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
                    iconForeground: context.palette.error,
                    iconBackground: context.palette.errorContainer,
                    asset: AppAssets.setLogoutIcon,
                    title: AppStrings.securityLogout,
                    titleColor: context.palette.error,
                    description: AppStrings.securityLogoutDesc,
                    onTap: () => _confirmLogout(context, ref),
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
                    asset: AppAssets.illSecurityTips,
                    semanticLabel: 'Tips Keamanan',
                    fallbackIcon: Icons.lightbulb_outline,
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
