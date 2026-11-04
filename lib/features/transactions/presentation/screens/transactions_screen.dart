import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/app_providers.dart';
import '../providers/transactions_controller.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';

enum _Filter { all, income, expense }

/// Riwayat transaksi: filter, grup tanggal terbaru dulu, empty state.
/// [accountId] opsional dari detail akun (?account=...) dengan chip hapus.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, this.accountId});

  final String? accountId;

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _Filter _filter = _Filter.all;
  String? _accountFilter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _accountFilter = widget.accountId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAdd() {
    ref.read(transactionFormProvider.notifier).reset();
    context.push(AppRoutes.transactionAdd);
  }

  void _onNav(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        break;
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
    final transactions = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transactionsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AppStrings.addTransaction,
            onPressed: _openAdd,
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 1,
        onTap: _onNav,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: transactions.when(
              data: (items) => _List(
                items: items,
                filter: _filter,
                accountFilter: _accountFilter,
                query: _query,
                searchController: _searchController,
                onFilter: (f) => setState(() => _filter = f),
                onQuery: (q) => setState(() => _query = q),
                onClearAccount: () =>
                    setState(() => _accountFilter = null),
                onAdd: _openAdd,
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(transactionsProvider)),
            ),
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.items,
    required this.filter,
    required this.accountFilter,
    required this.query,
    required this.searchController,
    required this.onFilter,
    required this.onQuery,
    required this.onClearAccount,
    required this.onAdd,
  });

  final List<AppTransaction> items;
  final _Filter filter;
  final String? accountFilter;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<_Filter> onFilter;
  final ValueChanged<String> onQuery;
  final VoidCallback onClearAccount;
  final VoidCallback onAdd;

  List<AppTransaction> get _filtered {
    final q = query.trim().toLowerCase();
    final byAccount = accountFilter == null
        ? items
        : items.where((e) => e.accountId == accountFilter).toList();
    final byQuery = q.isEmpty
        ? byAccount
        : byAccount.where((e) {
            final haystack =
                '${e.title} ${e.category ?? ''} ${e.note ?? ''}'
                    .toLowerCase();
            return haystack.contains(q);
          }).toList();
    switch (filter) {
      case _Filter.all:
        return byQuery;
      case _Filter.income:
        return byQuery
            .where((e) => e.type == TransactionType.income)
            .toList();
      case _Filter.expense:
        return byQuery
            .where((e) => e.type == TransactionType.expense)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
                  prefixIcon: const Icon(Icons.search_outlined),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_outlined),
                          tooltip: AppStrings.searchClear,
                          onPressed: () {
                            searchController.clear();
                            onQuery('');
                          },
                        ),
                ),
                onChanged: onQuery,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: AppStrings.filterAll,
                      selected: filter == _Filter.all,
                      onTap: () => onFilter(_Filter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppStrings.filterIncome,
                      selected: filter == _Filter.income,
                      onTap: () => onFilter(_Filter.income),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppStrings.filterExpense,
                      selected: filter == _Filter.expense,
                      onTap: () => onFilter(_Filter.expense),
                    ),
                    if (accountFilter != null) ...[
                      const SizedBox(width: 8),
                      _AccountChip(
                        accountId: accountFilter!,
                        onClear: onClearAccount,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyAll(onAdd: onAdd)
              : filtered.isEmpty
                  ? _EmptyFiltered(filter: filter, hasQuery: query.trim().isNotEmpty)
                  : _GroupedList(items: filtered),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}

class _AccountChip extends ConsumerWidget {
  const _AccountChip({required this.accountId, required this.onClear});

  final String accountId;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        ref.watch(onboardingRepositoryProvider).getOnboardingData();
    final names = {
      for (final e in data?.financialInstruments ?? const []) e.id: e.name,
    };
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondarySoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.accountFilterPrefix} ${names[accountId] ?? accountId}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.secondary,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.close,
              size: 16,
              color: AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
class _EmptyAll extends StatelessWidget {
  const _EmptyAll({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppAssets.transactionEmptyCheck,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(height: 120),
            ),
            const SizedBox(height: 8),
            const AppEmptyState(
              title: AppStrings.emptyTransactions,
              subtitle: AppStrings.emptyTransactionsHint,
              assetPath: AppAssets.setBills,
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 8),
            AppButton(
              label: AppStrings.addTransaction,
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  const _EmptyFiltered({required this.filter, required this.hasQuery});

  final _Filter filter;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    if (hasQuery) {
      return const AppEmptyState(
        title: AppStrings.searchEmptyTitle,
        subtitle: AppStrings.searchEmptySubtitle,
        icon: Icons.search_off_outlined,
      );
    }
    return AppEmptyState(
      title: filter == _Filter.income
          ? AppStrings.emptyFilterIncome
          : AppStrings.emptyFilterExpense,
      subtitle: AppStrings.emptyTransactionsHint,
      assetPath: AppAssets.setBills,
      icon: Icons.receipt_long_outlined,
    );
  }
}

class _GroupedList extends ConsumerWidget {
  const _GroupedList({required this.items});

  final List<AppTransaction> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        ref.watch(onboardingRepositoryProvider).getOnboardingData();
    final accountNames = {
      for (final e in data?.financialInstruments ?? const []) e.id: e.name,
    };
    final now = DateTime.now();

    final List<Widget> children = [];
    DateTime? currentDay;
    for (final item in items) {
      final day = DateTime(item.date.year, item.date.month, item.date.day);
      if (currentDay == null || !DateFormatter.isSameDay(currentDay, day)) {
        currentDay = day;
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Text(
              DateFormatter.isSameDay(day, now)
                  ? AppStrings.todayLabel
                  : DateFormatter.dayMonthYear(item.date),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        );
      }
      children.add(
        _TransactionRow(
          item: item,
          accountName: accountNames[item.accountId],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: children,
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item, required this.accountName});

  final AppTransaction item;
  final String? accountName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = item.type == TransactionType.income;
    final color = isIncome ? AppColors.primary : AppColors.error;
    final sign = isIncome ? '+' : '-';
    final detail = [
      if (item.category?.isNotEmpty ?? false) item.category,
      accountName,
    ].whereType<String>().join(' • ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CategoryIcon.forLabel(item.category, item.type, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$sign${CurrencyFormatter.formatCompact(item.amount)}',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
