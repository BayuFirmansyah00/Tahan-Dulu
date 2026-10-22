import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(title: const Text(AppStrings.appSettingsTitle)),
      body: SafeArea(
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
                  _SwitchRow(
                    icon: Icons.animation_outlined,
                    iconForeground: AppColors.secondary,
                    iconBackground: AppColors.secondarySoft,
                    title: AppStrings.appSettingsMotion,
                    description: AppStrings.appSettingsMotionDesc,
                    value: prefs.reduceMotion,
                    onChanged: notifier.setReduceMotion,
                  ),
                  const SizedBox(height: 8),
                  _SwitchRow(
                    icon: Icons.notifications_outlined,
                    iconForeground: AppColors.secondary,
                    iconBackground: AppColors.secondarySoft,
                    title: AppStrings.appSettingsInAppNotif,
                    description: AppStrings.appSettingsInAppNotifDesc,
                    value: prefs.showInAppNotifications,
                    onChanged: notifier.setShowInAppNotifications,
                  ),
                  const SizedBox(height: 8),
                  _SwitchRow(
                    icon: Icons.lightbulb_outline,
                    iconForeground: AppColors.primary,
                    iconBackground: AppColors.primarySoft,
                    title: AppStrings.appSettingsTips,
                    description: AppStrings.appSettingsTipsDesc,
                    value: prefs.showTips,
                    onChanged: notifier.setShowTips,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFFE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondary
                            .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info,
                          color: AppColors.secondary,
                          size: 20,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconForeground,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ProfileIconContainer(
            icon: icon,
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
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
