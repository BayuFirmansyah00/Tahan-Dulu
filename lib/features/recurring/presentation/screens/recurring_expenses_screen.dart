import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/api_recurring_transaction.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../../../profile/presentation/utils/profile_ui.dart';
import '../providers/recurring_controller.dart';

/// Daftar pengeluaran rutin & tagihan dengan opsi tambah.
class RecurringExpensesScreen extends ConsumerStatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  ConsumerState<RecurringExpensesScreen> createState() =>
      _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends ConsumerState<RecurringExpensesScreen> {
  void _onNav(int index) {
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

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(recurringExpensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.recurringExpensesTitle)),
      bottomNavigationBar: DashboardBottomNav(onTap: _onNav),
      body: GlassBackdrop(child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: items.when(
              data: (list) => _List(items: list),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(
                onRetry: () => ref.invalidate(recurringExpensesProvider),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});

  final List<ApiRecurringTransaction> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.recurringExpensesSubtitle,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.recurringExpensesListTitle,
                style: textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.recurringExpenseAdd),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.addRecurringExpense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            _EmptyList()
          else
            for (final item in items) ...[
              _RecurringItem(item: item),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _RecurringItem extends ConsumerWidget {
  const _RecurringItem({required this.item});

  final ApiRecurringTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      '${item.category} • ${item.frequency}',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.formatCompact(item.amount.toDouble()),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.palette.error,
                ),
              ),
              AppAdaptiveMenuButton<String>(
                options: [
                  AppMenuOption<String>(
                    value: 'toggle',
                    label: item.isActive ? 'Jeda' : 'Aktifkan',
                    icon: item.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  const AppMenuOption<String>(
                    value: 'delete',
                    label: 'Hapus',
                    icon: Icons.delete_outline,
                    isDestructive: true,
                  ),
                ],
                onSelected: (action) async {
                  final controller = ref.read(recurringControllerProvider);
                  if (action == 'toggle') {
                    await controller.toggleRecurringExpenseStatus(item);
                  } else if (action == 'delete') {
                    final confirm = await showConfirmDialog(
                      context: context,
                      icon: Icons.delete_outline,
                      title: 'Hapus Pengeluaran Rutin?',
                      message: 'Apakah Anda yakin ingin menghapus "${item.title}"?',
                      confirmLabel: 'Hapus',
                    );
                    if (confirm) {
                      await controller.removeRecurringExpense(item.id);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: context.palette.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                item.nextDueDate ?? '-',
                style: textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                item.isActive ? AppStrings.active : AppStrings.inactive,
                style: textTheme.bodySmall?.copyWith(
                  color: item.isActive ? context.palette.primary : context.palette.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppEmptyState(
          title: AppStrings.emptyRecurringExpenses,
          subtitle: AppStrings.emptyRecurringExpensesHint,
          icon: Icons.schedule_outlined,
        ),
        AppButton(
          label: AppStrings.addRecurringExpense,
          icon: Icons.add,
          onPressed: () {},
        ),
      ],
    );
  }
}
