import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/reminder_settings.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../../../profile/presentation/utils/profile_ui.dart';
import '../providers/notifications_providers.dart';
import '../utils/notification_ui.dart';

/// Layar Pengaturan Notifikasi: status + 6 toggle pengingat keuangan.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  void _onNav(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
      case 2:
        context.push(AppRoutes.transactions);
      case 3:
        context.push(AppRoutes.goals);
      case 4:
        context.push(AppRoutes.settings);
    }
  }

  String _titleFor(ReminderType type) {
    switch (type) {
      case ReminderType.salary:
        return AppStrings.reminderSalaryTitle;
      case ReminderType.savings:
        return AppStrings.reminderSavingsTitle;
      case ReminderType.bills:
        return AppStrings.reminderBillsTitle;
      case ReminderType.budget:
        return AppStrings.reminderBudgetTitle;
      case ReminderType.tahandulu:
        return AppStrings.reminderTahanDuluTitle;
      case ReminderType.overspending:
        return AppStrings.reminderOverspendTitle;
    }
  }

  String _descFor(ReminderType type) {
    switch (type) {
      case ReminderType.salary:
        return AppStrings.reminderSalaryDesc;
      case ReminderType.savings:
        return AppStrings.reminderSavingsDesc;
      case ReminderType.bills:
        return AppStrings.reminderBillsDesc;
      case ReminderType.budget:
        return AppStrings.reminderBudgetDesc;
      case ReminderType.tahandulu:
        return AppStrings.reminderTahanDuluDesc;
      case ReminderType.overspending:
        return AppStrings.reminderOverspendDesc;
    }
  }

  void _onRowTap(BuildContext context, ReminderType type) {
    // Hanya Pengingat Menabung yang punya halaman detail nyata.
    if (type == ReminderType.savings) {
      context.push(AppRoutes.notificationSavings);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.reminderDetailComingSoon)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(reminderPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: const Text(AppStrings.notifSettingsTitle),
        flexibleSpace: const AppBarMintCorner(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: AppStrings.notificationsTitle,
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(
        onTap: (i) => _onNav(i, context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: prefs.when(
              data: (items) => _Body(
                prefs: items,
                titleFor: _titleFor,
                descFor: _descFor,
                onToggle: (type, value) => ref
                    .read(reminderPrefsControllerProvider.notifier)
                    .setEnabled(type, value),
                onRowTap: (type) => _onRowTap(context, type),
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(reminderPreferencesProvider)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.prefs,
    required this.titleFor,
    required this.descFor,
    required this.onToggle,
    required this.onRowTap,
  });

  final List<ReminderPreference> prefs;
  final String Function(ReminderType) titleFor;
  final String Function(ReminderType) descFor;
  final Future<bool> Function(ReminderType, bool) onToggle;
  final ValueChanged<ReminderType> onRowTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsBanner(
            asset: AppAssets.illNotifActive,
            semanticLabel: 'Notifikasi Aktif',
            fallbackIcon: Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.notifFinanceSection,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final pref in prefs) ...[
            _ReminderRow(
              pref: pref,
              asset: reminderAssetFor(pref.type),
              title: titleFor(pref.type),
              description: descFor(pref.type),
              onToggle: (value) => onToggle(pref.type, value),
              onTap: () => onRowTap(pref.type),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFFE),
              borderRadius: BorderRadius.circular(14),
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
                    AppStrings.notifInfo,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.pref,
    required this.asset,
    required this.title,
    required this.description,
    required this.onToggle,
    required this.onTap,
  });

  final ReminderPreference pref;
  final String asset;
  final String title;
  final String description;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = visualForReminder(pref.type);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardLarge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardLarge,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Image.asset(
              asset,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: visual.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  visual.icon,
                  color: visual.foreground,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Switch(
              value: pref.enabled,
              activeTrackColor: AppColors.primary,
              onChanged: onToggle,
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
