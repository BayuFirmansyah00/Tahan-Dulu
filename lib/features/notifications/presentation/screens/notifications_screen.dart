import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/app_notification.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/notifications_providers.dart';
import '../utils/notification_ui.dart';

/// Layar Notifikasi: hero mint + tab filter, aksi massal, daftar per hari.
///
/// Tahap 47: redesign premium emerald lokal ([NotifColors]) tanpa
/// mengubah tema global. Filter, status baca, pengelompokan,
/// navigasi item, dan bottom nav global dipertahankan.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _onNav(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.push(AppRoutes.transactions);
      case 2:
        context.push(AppRoutes.transactionRecordMethod);
      case 3:
        context.push(AppRoutes.goals);
      case 4:
        context.push(AppRoutes.settings);
    }
  }

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(notificationsControllerProvider.notifier)
        .markAllAsRead();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? AppStrings.notifAllMarkedRead : AppStrings.savingSaveFailed,
        ),
      ),
    );
  }

  Future<void> _openItem(
    BuildContext context,
    WidgetRef ref,
    AppNotification item,
  ) async {
    if (!item.isRead) {
      await ref
          .read(notificationsControllerProvider.notifier)
          .markAsRead(item.id);
    }
    if (!context.mounted) return;
    final route = item.targetRoute;
    if (route != null && route.isNotEmpty) {
      try {
        context.push(route);
      } catch (_) {
        // Fallback navigasi aman bila target route tidak terdaftar di router
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(notificationFilterProvider);
    final list = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: NotifColors.background,
      appBar: AppBar(
        backgroundColor: NotifColors.background,
        title: const Text(AppStrings.notificationsTitle),
        titleSpacing: 20,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) async {
              if (value == 'read-all') {
                await _markAll(context, ref);
              } else if (value == 'settings') {
                if (context.mounted) {
                  context.push(AppRoutes.notificationSettings);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'read-all',
                child: Text(AppStrings.notifMenuMarkAll),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text(AppStrings.notifMenuSettings),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(onTap: (i) => _onNav(i, context)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const _HeroBanner(),
                _FilterTabs(
                  filter: filter,
                  onSelect: (f) =>
                      ref.read(notificationFilterProvider.notifier).set(f),
                ),
                _MarkAllRow(onTap: () => _markAll(context, ref)),
                Expanded(
                  child: SingleChildScrollView(
                    child: list.when(
                      data: (items) => items.isEmpty
                          ? _EmptyFor(filter: filter)
                          : _GroupedList(
                              items: items,
                              onTap: (item) => _openItem(context, ref, item),
                            ),
                      loading: () => const AppLoading(),
                      error: (error, _) => AppErrorState(
                        onRetry: () =>
                            ref.invalidate(notificationsListProvider),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero mint: judul + deskripsi + lonceng 3D + badge jumlah aktual.
class _HeroBanner extends ConsumerWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final unreadCount = unread.maybeWhen(
      data: (value) => value,
      orElse: () => 0,
    );
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: NotifColors.hero,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NotifColors.heroBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.notifHeroTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: NotifColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.notifHeroSubtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: NotifColors.slate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _BellBadge(unread: unreadCount),
        ],
      ),
    );
  }
}

/// Lonceng 3D lokal + badge jumlah belum dibaca (data aktual).
class _BellBadge extends StatelessWidget {
  const _BellBadge({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: NotifColors.card,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              NotifAssets.bell,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.notifications_outlined,
                color: NotifColors.primary,
                size: 36,
              ),
            ),
          ),
          if (unread > 0)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NotifColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NotifColors.card, width: 2),
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.filter, required this.onSelect});

  final NotificationFilter filter;
  final ValueChanged<NotificationFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: AppStrings.notifTabAll,
              selected: filter == NotificationFilter.all,
              onTap: () => onSelect(NotificationFilter.all),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tab(
              label: AppStrings.notifTabUnread,
              selected: filter == NotificationFilter.unread,
              onTap: () => onSelect(NotificationFilter.unread),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tab(
              label: AppStrings.notifTabReminder,
              selected: filter == NotificationFilter.reminder,
              onTap: () => onSelect(NotificationFilter.reminder),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? NotifColors.primary : NotifColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? NotifColors.primary : NotifColors.border,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1F0E9F6E),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : NotifColors.navy,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _MarkAllRow extends StatelessWidget {
  const _MarkAllRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: NotifColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NotifColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F102A43),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: NotifColors.chipInactive,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: NotifColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.notifMarkAllRead,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: NotifColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: NotifColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFor extends StatelessWidget {
  const _EmptyFor({required this.filter});

  final NotificationFilter filter;

  @override
  Widget build(BuildContext context) {
    switch (filter) {
      case NotificationFilter.unread:
        return const AppEmptyState(
          title: AppStrings.notifEmptyUnread,
          subtitle: AppStrings.notifEmptyUnreadHint,
          icon: Icons.mark_email_read_outlined,
        );
      case NotificationFilter.reminder:
        return const AppEmptyState(
          title: AppStrings.notifEmptyReminder,
          subtitle: AppStrings.notifEmptyReminderHint,
          icon: Icons.alarm_outlined,
        );
      case NotificationFilter.all:
        return const AppEmptyState(
          title: AppStrings.notifEmpty,
          subtitle: AppStrings.notifEmptyHint,
          icon: Icons.notifications_outlined,
        );
    }
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.items, required this.onTap});

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final List<Widget> children = [];
    DateTime? currentDay;
    for (final item in items) {
      final day = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      if (currentDay == null || !DateFormatter.isSameDay(currentDay, day)) {
        currentDay = day;
        final title = DateFormatter.isSameDay(day, today)
            ? AppStrings.notifToday
            : DateFormatter.isSameDay(day, yesterday)
            ? AppStrings.notifYesterday
            : DateFormatter.weekdayName(day);
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: NotifColors.navy,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    DateFormatter.fullDate(day),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: NotifColors.slate),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      children.add(_NotificationCard(item: item, onTap: () => onTap(item)));
    }

    return Column(children: [...children, const SizedBox(height: 16)]);
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = visualForCategory(item.category);
    final openable = item.targetRoute != null && item.targetRoute!.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: NotifColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead ? NotifColors.border : NotifColors.heroBorder,
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F102A43),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(5),
                child: NotifCategoryIcon(category: item.category, size: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: NotifColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: NotifColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormatter.hourMinute(item.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: NotifColors.slate,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? NotifColors.readDot
                              : NotifColors.unreadDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (openable) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: NotifColors.slate,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
