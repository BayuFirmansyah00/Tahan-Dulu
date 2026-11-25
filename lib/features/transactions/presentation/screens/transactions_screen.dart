import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/transaction_model.dart';
import '../providers/transactions_controller.dart';
import '../widgets/transaction_detail_sheet.dart';
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
    if (widget.accountId != null) {
      Future.microtask(() {
        ref.read(paginatedTransactionsProvider.notifier).setFilter(
              accountId: widget.accountId,
            );
      });
    }
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
    final paginated = ref.watch(paginatedTransactionsProvider);

    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);

    return Scaffold(
      extendBody: useDarkGlass,
      appBar: AppBar(
        title: const Text(AppStrings.transactionsTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppAdaptiveIconButton(
              icon: const Icon(Icons.add),
              tooltip: AppStrings.addTransaction,
              onPressed: _openAdd,
            ),
          ),
        ],
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 1,
        onTap: _onNav,
      ),
      body: GlassBackdrop(
        child: SafeArea(
          bottom: !useDarkGlass,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: paginated.isLoadingInitial && paginated.items.isEmpty
                  ? const AppLoading()
                  : paginated.errorMessage != null && paginated.items.isEmpty
                      ? AppErrorState(
                          onRetry: () => ref
                              .read(paginatedTransactionsProvider.notifier)
                              .loadInitial(),
                        )
                      : _List(
                          items: paginated.items,
                          filter: _filter,
                          accountFilter: _accountFilter,
                          query: _query,
                          searchController: _searchController,
                          onFilter: (f) => setState(() => _filter = f),
                          onQuery: (q) => setState(() => _query = q),
                          onClearAccount: () => setState(() => _accountFilter = null),
                          onAdd: _openAdd,
                          onRefresh: () => ref
                              .read(paginatedTransactionsProvider.notifier)
                              .refresh(),
                          onLoadMore: () => ref
                              .read(paginatedTransactionsProvider.notifier)
                              .loadMore(),
                          isLoadingMore: paginated.isLoadingMore,
                          loadMoreErrorMessage: paginated.loadMoreErrorMessage,
                          hasNextPage: paginated.hasNextPage,
                          onRetryLoadMore: () => ref
                              .read(paginatedTransactionsProvider.notifier)
                              .loadMore(),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _List extends StatefulWidget {
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
    required this.onRefresh,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.loadMoreErrorMessage,
    required this.hasNextPage,
    required this.onRetryLoadMore,
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
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final bool hasNextPage;
  final VoidCallback onRetryLoadMore;

  @override
  State<_List> createState() => _ListState();
}

class _ListState extends State<_List> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  List<AppTransaction> get _filtered {
    final q = widget.query.trim().toLowerCase();
    final byAccount = widget.accountFilter == null
        ? widget.items
        : widget.items.where((e) => e.accountId == widget.accountFilter).toList();
    final byQuery = q.isEmpty
        ? byAccount
        : byAccount.where((e) {
            final haystack =
                '${e.title} ${e.category ?? ''} ${e.note ?? ''}'
                    .toLowerCase();
            return haystack.contains(q);
          }).toList();
    switch (widget.filter) {
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
                controller: widget.searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
                  prefixIcon: const Icon(Icons.search_outlined),
                  suffixIcon: widget.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_outlined),
                          tooltip: AppStrings.searchClear,
                          onPressed: () {
                            widget.searchController.clear();
                            widget.onQuery('');
                          },
                        ),
                ),
                onChanged: widget.onQuery,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: AppStrings.filterAll,
                      selected: widget.filter == _Filter.all,
                      onTap: () => widget.onFilter(_Filter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppStrings.filterIncome,
                      selected: widget.filter == _Filter.income,
                      onTap: () => widget.onFilter(_Filter.income),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppStrings.filterExpense,
                      selected: widget.filter == _Filter.expense,
                      onTap: () => widget.onFilter(_Filter.expense),
                    ),
                    if (widget.accountFilter != null) ...[
                      const SizedBox(width: 8),
                      _AccountChip(
                        accountId: widget.accountFilter!,
                        onClear: widget.onClearAccount,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.items.isEmpty
              ? _EmptyAll(onAdd: widget.onAdd)
              : filtered.isEmpty
                  ? _EmptyFiltered(
                      filter: widget.filter,
                      hasQuery: widget.query.trim().isNotEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      child: _GroupedList(
                        items: filtered,
                        scrollController: _scrollController,
                        isLoadingMore: widget.isLoadingMore,
                        loadMoreErrorMessage: widget.loadMoreErrorMessage,
                        hasNextPage: widget.hasNextPage,
                        onRetryLoadMore: widget.onRetryLoadMore,
                      ),
                    ),
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
    return AppAdaptiveFilterChip(
      label: label,
      selected: selected,
      onTap: onTap,
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
          color: context.palette.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.palette.secondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.accountFilterPrefix} ${names[accountId] ?? accountId}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.palette.secondary,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.close,
              size: 16,
              color: context.palette.secondary,
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
  const _GroupedList({
    required this.items,
    required this.scrollController,
    required this.isLoadingMore,
    required this.loadMoreErrorMessage,
    required this.hasNextPage,
    required this.onRetryLoadMore,
  });

  final List<AppTransaction> items;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final String? loadMoreErrorMessage;
  final bool hasNextPage;
  final VoidCallback onRetryLoadMore;

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

    // Indikator status paginasi di akhir daftar (F06B)
    if (isLoadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    } else if (loadMoreErrorMessage != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                'Gagal memuat transaksi berikutnya',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.palette.error,
                    ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: onRetryLoadMore,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    } else if (!hasNextPage && items.length >= 10) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'Semua transaksi telah dimuat',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      key: const PageStorageKey('transactions_list_view'),
      padding: EdgeInsets.only(
        bottom: GlassDesignTokens.isDarkGlass(context) ? 100 : 16,
      ),
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
    final color = isIncome ? context.palette.primary : context.palette.error;
    final sign = isIncome ? '+' : '-';
    final detail = [
      if (item.category?.isNotEmpty ?? false) item.category,
      accountName,
    ].whereType<String>().join(' • ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showTransactionDetailSheet(
            context,
            item,
            accountName: accountName,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                          color: context.palette.onSurface,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: context.palette.onSurfaceVariant,
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
          ),
        ),
      ),
    );
  }
}
