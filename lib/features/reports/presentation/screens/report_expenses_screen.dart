import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/models/monthly_report.dart';
import '../../../../data/providers/reports_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../widgets/report_charts.dart';
import '../widgets/report_widgets.dart';

/// Detail Pengeluaran: total, tab kategori, donat, top list, insight.
class ReportExpensesScreen extends ConsumerStatefulWidget {
  const ReportExpensesScreen({super.key});

  @override
  ConsumerState<ReportExpensesScreen> createState() =>
      _ReportExpensesScreenState();
}

class _ReportExpensesScreenState
    extends ConsumerState<ReportExpensesScreen> {
  bool _needsTab = true;

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
    final month = ref.watch(reportMonthProvider);
    final report = ref.watch(monthlyReportProvider(month));
    final period = ref.read(reportMonthProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.expense)),
      bottomNavigationBar: DashboardBottomNav(
        onTap: _onNav,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: report.when(
              data: (r) => _Body(
                month: month,
                report: r,
                needsTab: _needsTab,
                onTab: (v) => setState(() => _needsTab = v),
                onPrevious: period.previous,
                onNext: period.next,
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(monthlyReportProvider(month))),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.month,
    required this.report,
    required this.needsTab,
    required this.onTab,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final MonthlyReport report;
  final bool needsTab;
  final ValueChanged<bool> onTab;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final change = report.prevExpense == null || report.prevExpense! <= 0
        ? null
        : (report.expense - report.prevExpense!) / report.prevExpense!;
    final top = report.categories.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodSelector(
            month: month,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  AppAssets.headerPengeluaran,
                  width: 104,
                  height: 104,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(width: 104, height: 104),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.totalExpenseLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.formatCompact(
                            report.expense,
                          ),
                          style: textTheme.headlineMedium?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (change != null)
                        Text(
                          '${change >= 0 ? '+' : ''}${(change * 100).round()}% '
                          '${AppStrings.fromLastMonth}',
                          style: textTheme.labelSmall?.copyWith(
                            color: change > 0
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: AppStrings.tabCategory,
                  selected: needsTab,
                  onTap: () => onTab(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TabButton(
                  label: AppStrings.tabNeedsWants,
                  selected: !needsTab,
                  onTap: () => onTab(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (needsTab) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExpenseDonut(
                  values: [
                    for (final c in report.categories) c.amount,
                  ],
                  total: report.expense,
                  size: 140,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < report.categories.length;
                          i++)
                        _LegendRow(
                          color: reportPalette[
                              i % reportPalette.length],
                          label: report.categories[i].label,
                          amount: report.categories[i].amount,
                          share: report.categories[i].share,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (report.categories.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppStrings.emptyChartData,
                  style: textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 16),
            const ReportSectionTitle(AppStrings.topExpensesTitle),
            const SizedBox(height: 8),
            for (var i = 0; i < top.length; i++)
              _TopRow(
                rank: i + 1,
                label: top[i].label,
                amount: top[i].amount,
                share: top[i].share,
              ),
            const SizedBox(height: 12),
            InsightCard(
              icon: Icons.lightbulb_outline,
              iconColor: AppColors.warning,
              iconBackground: const Color(0xFFFEF3C7),
              title: top.isEmpty
                  ? AppStrings.emptyChartData
                  : '${top.first.label} terbesar',
              body: top.isEmpty
                  ? AppStrings.emptyChartData
                  : 'Pengeluaran terbesar bulan ini berasal dari ${top.first.label.toLowerCase()} utama.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    label: AppStrings.legendSavings,
                    onPressed: () =>
                        context.push(AppRoutes.reportsSavings),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppOutlineButton(
                    label: AppStrings.healthTitle,
                    onPressed: () =>
                        context.push(AppRoutes.reportsHealth),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.needsWantsUnavailableTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.needsWantsUnavailableBody,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.share,
  });

  final Color color;
  final String label;
  final double amount;
  final double share;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.bodyMedium),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(share * 100).round()}%',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.rank,
    required this.label,
    required this.amount,
    required this.share,
  });

  final int rank;
  final String label;
  final double amount;
  final double share;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconAsset = txIconForLabel(label, TransactionType.expense);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Image.asset(
            iconAsset,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.category_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.titleMedium),
                Text(
                  CurrencyFormatter.formatCompact(amount),
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(share * 100).round()}%',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
