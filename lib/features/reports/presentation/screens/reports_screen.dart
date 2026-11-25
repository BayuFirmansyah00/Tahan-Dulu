import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/monthly_report.dart';
import '../../../../data/providers/reports_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../widgets/report_charts.dart';
import '../widgets/report_widgets.dart';

/// Laporan Keuangan: ringkasan + grafik + tombol detail.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(reportMonthProvider);
    final report = ref.watch(monthlyReportProvider(month));
    final period = ref.read(reportMonthProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reportsTitle)),
      bottomNavigationBar: DashboardBottomNav(
        onTap: (i) => _onNav(i, context),
      ),
      body: GlassBackdrop(child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: report.when(
              data: (r) => _Body(
                month: month,
                report: r,
                onPrevious: period.previous,
                onNext: period.next,
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(monthlyReportProvider(month))),
            ),
          ),
        ),
      )),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.month,
    required this.report,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final MonthlyReport report;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiReport = ref.watch(apiFinancialReportProvider(month)).asData?.value;
    final periodMode = ref.watch(reportPeriodModeProvider);
    final savedAmount = apiReport?.summary.savedImpulseAmount ?? 0.0;
    final savedCount = apiReport?.summary.savedImpulseCount ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodSelector(
            month: month,
            onPrevious: onPrevious,
            onNext: onNext,
            onSelectPeriod: (picked) {
              ref.read(reportPeriodModeProvider.notifier).setMode('monthly');
              ref.read(reportMonthProvider.notifier).setMonth(picked);
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PeriodChip(
                  label: 'Bulan Ini',
                  isSelected: periodMode == 'monthly' &&
                      month.year == DateTime.now().year &&
                      month.month == DateTime.now().month,
                  onTap: () {
                    ref.read(reportPeriodModeProvider.notifier).setMode('monthly');
                    ref.read(reportMonthProvider.notifier).setThisMonth();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Bulan Lalu',
                  isSelected: periodMode == 'monthly' &&
                      month.year ==
                          (DateTime.now().month == 1
                              ? DateTime.now().year - 1
                              : DateTime.now().year) &&
                      month.month ==
                          (DateTime.now().month == 1
                              ? 12
                              : DateTime.now().month - 1),
                  onTap: () {
                    ref.read(reportPeriodModeProvider.notifier).setMode('monthly');
                    ref.read(reportMonthProvider.notifier).setLastMonth();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Kuartal Ini',
                  isSelected: periodMode == 'quarter',
                  onTap: () {
                    ref.read(reportPeriodModeProvider.notifier).setMode('quarter');
                    ref.read(reportMonthProvider.notifier).setQuarter();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Pilih Tanggal',
                  isSelected: false,
                  icon: Icons.calendar_month_outlined,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: month,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      ref.read(reportPeriodModeProvider.notifier).setMode('monthly');
                      ref
                          .read(reportMonthProvider.notifier)
                          .setMonth(picked);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.arrow_downward,
                  foreground: context.palette.primary,
                  background: context.palette.primaryContainer,
                  label: AppStrings.reportsIncomeLabel,
                  value: report.income,
                  previous: report.prevIncome,
                  goodWhenUp: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.arrow_upward,
                  foreground: context.palette.error,
                  background: context.palette.errorContainer,
                  label: AppStrings.reportsExpenseLabel,
                  value: report.expense,
                  previous: report.prevExpense,
                  goodWhenUp: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PlainCard(
                  icon: Icons.savings_outlined,
                  foreground: context.warningInk,
                  background: context.warningFill,
                  label: AppStrings.reportsSavedLabel,
                  value: report.savingsMonth,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlainCard(
                  icon: Icons.show_chart_outlined,
                  foreground: context.palette.secondary,
                  background: context.palette.secondaryContainer,
                  label: AppStrings.reportsInvestedLabel,
                  value: report.investmentMonth,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RemainingCard(net: report.net),
          if (savedAmount > 0) ...[
            const SizedBox(height: 10),
            _SavedImpulseCard(
              amount: savedAmount,
              count: savedCount,
            ),
          ],
          const SizedBox(height: 16),
          const ReportSectionTitle(AppStrings.reportsVsTitle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
            child: IncomeExpenseBars(
              income: report.income,
              expense: report.expense,
            ),
          ),
          const SizedBox(height: 16),
          InsightCard(
            icon: Icons.spa_outlined,
            iconColor: context.palette.primary,
            iconBackground: context.palette.primaryContainer,
            title: apiReport != null && apiReport.summary.healthScore > 0
                ? 'Skor Kesehatan: ${apiReport.summary.healthScore}/100'
                : AppStrings.reportsMonthSummary,
            body: apiReport != null && apiReport.summary.healthScore > 0
                ? apiReport.summary.healthLabel
                : (report.expense <= report.income
                    ? AppStrings.reportsWithinBudget
                    : AppStrings.reportsOverBudget),
            trailing: Icon(
              Icons.chevron_right,
              color: context.palette.onSurfaceVariant,
            ),
            onTap: () => context.push(AppRoutes.reportsHealth),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: AppStrings.seeExpenseDetail,
            onPressed: () =>
                context.push(AppRoutes.reportsExpenses),
          ),
          const SizedBox(height: 10),
          AppOutlineButton(
            label: AppStrings.exportPdf,
            icon: Icons.download_outlined,
            onPressed: () => context.push(AppRoutes.reportsExport),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.label,
    required this.value,
    required this.previous,
    required this.goodWhenUp,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final String label;
  final double value;
  final double? previous;
  final bool goodWhenUp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final change = previous == null || previous! <= 0
        ? null
        : (value - previous!) / previous!;
    final good =
        change == null ? null : (goodWhenUp ? change >= 0 : change <= 0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: foreground, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatCompact(value),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: 2),
            Text(
              '${change >= 0 ? '+' : ''}${(change * 100).round()}% '
              '${AppStrings.fromLastMonth}',
              style: textTheme.labelSmall?.copyWith(
                color: good! ? context.palette.primary : context.palette.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: foreground, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatCompact(value),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingCard extends StatelessWidget {
  const _RemainingCard({required this.net});

  final double net;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.palette.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: context.palette.secondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.reportsRemainingLabel,
              style: textTheme.bodyMedium,
            ),
          ),
          Text(
            CurrencyFormatter.formatCompact(net),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: context.palette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedImpulseCard extends StatelessWidget {
  const _SavedImpulseCard({
    required this.amount,
    required this.count,
  });

  final double amount;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.palette.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              color: context.palette.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dana Terselamatkan (Tahan Dulu)',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$count godaan impulsif ditahan (estimasi hemat)',
                  style: textTheme.labelSmall?.copyWith(
                    color: context.palette.primary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: context.palette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? context.palette.primaryContainer
              : context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? context.palette.primary
                : context.palette.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? context.palette.primary
                    : context.palette.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? context.palette.primary
                    : context.palette.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
