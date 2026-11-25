import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/profile_providers.dart';
import '../utils/profile_ui.dart';

/// Profil Utama: kartu pengguna, ringkasan, 7 menu, keluar akun.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
    final user = ref.watch(profileUserProvider);
    final prefs = ref.watch(appPreferencesProvider);

    return Scaffold(
      backgroundColor: context.canvasColor,
      extendBody: true,
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 4,
        onTap: (i) => profileOnNav(i, context),
      ),
      body: GlassBackdrop(child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: user.when(
              data: (u) => _Body(
                user: u,
                showTips: prefs.showTips,
                onLogout: () => _confirmLogout(context, ref),
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(
                onRetry: () => ref.invalidate(profileUserProvider),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

/// Tombol kembali header Pengaturan Akun: pop bila ada riwayat,
/// jika tidak kembali ke dashboard agar tak pernah menjadi tombol mati.
class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton();

  @override
  Widget build(BuildContext context) {
    return AppBackButton(
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.dashboard);
        }
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.user,
    required this.showTips,
    required this.onLogout,
  });

  final UserModel user;
  final bool showTips;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      key: const PageStorageKey('profile_scroll_view'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _HeaderBackButton(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.profileTitle,
                      style: textTheme.headlineMedium?.copyWith(fontSize: 24),
                    ),
                    Text(
                      AppStrings.profileSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProfileCard(user: user),
          if (showTips) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: context.palette.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.palette.secondary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppImageIcon(
                    assetPath: AppAssets.statusInfo,
                    size: 18,
                    fallbackIcon: Icons.lightbulb_outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.profileTipsTitle,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          AppStrings.profileTipsBody,
                          style: textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const ProfileSectionHeader(
            title: 'Keuangan',
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.palette.primary,
            iconBackground: context.palette.primaryContainer,
            asset: AppAssets.ntfBudget,
            title: 'Rencana Keuangan',
            description: 'Gaji terencana, tanggal gajian, dan siklus anggaran',
            onTap: () => context.push(AppRoutes.financialSettings),
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.palette.primary,
            iconBackground: context.palette.primaryContainer,
            asset: AppAssets.actionAddMoney,
            title: AppStrings.recurringIncomesTitle,
            description: 'Kelola gaji dan pemasukan berkala',
            onTap: () => context.push(AppRoutes.recurringIncomes),
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.palette.error,
            iconBackground: context.palette.errorContainer,
            asset: AppAssets.actionHistory,
            title: AppStrings.recurringExpensesTitle,
            description: 'Kelola tagihan, langganan, dan pengeluaran rutin',
            onTap: () => context.push(AppRoutes.recurringExpenses),
          ),
          const SizedBox(height: 20),
          const ProfileSectionHeader(
            title: 'Akun & Preferensi',
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.palette.secondary,
            iconBackground: context.palette.secondaryContainer,
            asset: AppAssets.setProfile,
            title: AppStrings.profileMenuInfo,
            description: AppStrings.profileMenuInfoDesc,
            onTap: () => context.push(AppRoutes.profileEdit),
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.palette.primary,
            iconBackground: context.palette.primaryContainer,
            asset: AppAssets.setApp,
            title: AppStrings.profileMenuApp,
            description: AppStrings.profileMenuAppDesc,
            onTap: () => context.push(AppRoutes.profileApp),
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.warningInk,
            iconBackground: context.warningFill,
            asset: AppAssets.setNotif,
            title: AppStrings.profileMenuNotif,
            description: AppStrings.profileMenuNotifDesc,
            onTap: () =>
                context.push(AppRoutes.notificationSettings),
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.palette.secondary,
            iconBackground: context.palette.secondaryContainer,
            asset: AppAssets.setSecurity,
            title: AppStrings.profileMenuSecurity,
            description: AppStrings.profileMenuSecurityDesc,
            onTap: () => context.push(AppRoutes.profileSecurity),
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.palette.primary,
            iconBackground: context.palette.primaryContainer,
            asset: AppAssets.setPrivacy,
            title: AppStrings.profileMenuPrivacy,
            description: AppStrings.profileMenuPrivacyDesc,
            onTap: () => context.push(AppRoutes.profilePrivacy),
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.warningInk,
            iconBackground: context.warningFill,
            asset: AppAssets.setHelp,
            title: AppStrings.profileMenuHelp,
            description: AppStrings.profileMenuHelpDesc,
            onTap: () => context.push(AppRoutes.profileHelp),
          ),
          const SizedBox(height: 8),
          SettingsMenuRow(
            iconForeground: context.palette.secondary,
            iconBackground: context.palette.secondaryContainer,
            asset: AppAssets.setAbout,
            title: AppStrings.profileMenuAbout,
            description: AppStrings.profileMenuAboutDesc,
            onTap: () => context.push(AppRoutes.profileAbout),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.palette.error,
                side: BorderSide(color: context.palette.error),
              ),
              onPressed: onLogout,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppImageIcon(
                    assetPath: AppAssets.setLogoutIcon,
                    size: 18,
                    fallbackIcon: Icons.logout_outlined,
                  ),
                  SizedBox(width: 8),
                  Text(AppStrings.profileLogoutAction),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: Glass.panel(context, radius: BorderRadius.circular(20)),
      child: Row(
        children: [
          AppAvatar(
            name: user.name,
            avatarUrl: user.avatarUrl,
            radius: 28,
            onTap: () => context.push(AppRoutes.profileEdit),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  user.email ?? AppStrings.profileEmailUnavailable,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                ),
                if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: context.palette.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppImageIcon(
                        assetPath: AppAssets.statusSuccess,
                        size: 14,
                        fallbackIcon: Icons.verified_outlined,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          AppStrings.profileBadge,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: context.palette.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onPressed: () => context.push(AppRoutes.profileEdit),
            child: const Text(
              AppStrings.profileEditAction,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

