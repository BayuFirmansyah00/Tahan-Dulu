import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../data/models/app_preferences.dart';
import '../providers/profile_providers.dart';
import '../utils/profile_ui.dart';

/// Pengaturan Aplikasi: tema, bahasa, mata uang, pengalaman pengguna.
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final notifier = ref.read(appPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.appSettingsTitle),
      ),
      body: GlassBackdrop(child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ProfileSectionHeader(
                    title: AppStrings.appSettingsExperience,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AppThemeChoice>(
                    initialValue: prefs.theme,
                    key: ValueKey(prefs.theme),
                    decoration: const InputDecoration(labelText: 'Tema tampilan'),
                    items: const [
                      DropdownMenuItem(value: AppThemeChoice.system, child: Text('Ikuti sistem')),
                      DropdownMenuItem(value: AppThemeChoice.light, child: Text('Terang')),
                      DropdownMenuItem(value: AppThemeChoice.dark, child: Text('Gelap')),
                    ],
                    onChanged: (value) { if (value != null) notifier.setTheme(value); },
                  ),
                  const SizedBox(height: 12),
                  _SwitchRow(
                    icon: Icons.animation_outlined,
                    iconForeground: context.palette.secondary,
                    iconBackground: context.palette.secondaryContainer,
                    title: AppStrings.appSettingsMotion,
                    description: AppStrings.appSettingsMotionDesc,
                    value: prefs.reduceMotion,
                    onChanged: notifier.setReduceMotion,
                  ),
                  const SizedBox(height: 8),
                  _SwitchRow(
                    assetPath: AppAssets.setNotif,
                    icon: Icons.notifications_outlined,
                    iconForeground: context.palette.secondary,
                    iconBackground: context.palette.secondaryContainer,
                    title: AppStrings.appSettingsInAppNotif,
                    description: AppStrings.appSettingsInAppNotifDesc,
                    value: prefs.showInAppNotifications,
                    onChanged: notifier.setShowInAppNotifications,
                  ),
                  const SizedBox(height: 8),
                  _SwitchRow(
                    assetPath: AppAssets.statusInfo,
                    icon: Icons.lightbulb_outline,
                    iconForeground: context.palette.primary,
                    iconBackground: context.palette.primaryContainer,
                    title: AppStrings.appSettingsTips,
                    description: AppStrings.appSettingsTipsDesc,
                    value: prefs.showTips,
                    onChanged: notifier.setShowTips,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.palette.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.palette.secondary
                            .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppImageIcon(
                          assetPath: AppAssets.statusInfo,
                          size: 20,
                          fallbackIcon: Icons.info,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.appSettingsSessionNote,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 20),
                    const ProfileSectionHeader(
                      title: 'Pengembang (Debug Only)',
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.palette.outlineVariant),
                        ),
                        child: ListTile(
                          key: const Key('dev_glass_poc_tile'),
                          leading: const Icon(Icons.lens_blur, color: AppColors.primary),
                          title: const Text(
                            'True Clear Liquid Glass POC',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text('Komparasi optical refraction & shader tuning'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => context.push(AppRoutes.devGlassPoc),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    this.icon,
    this.assetPath,
    this.iconForeground = AppColors.secondary,
    this.iconBackground = AppColors.secondarySoft,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData? icon;
  final String? assetPath;
  final Color iconForeground;
  final Color iconBackground;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: context.palette.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (assetPath != null && assetPath!.isNotEmpty)
            AppImageIcon(
              assetPath: assetPath!,
              size: 40,
              fallbackIcon: icon ?? Icons.tune_outlined,
            )
          else
            ProfileIconContainer(
              icon: icon ?? Icons.tune_outlined,
              foreground: iconForeground,
              background: iconBackground,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: context.palette.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
