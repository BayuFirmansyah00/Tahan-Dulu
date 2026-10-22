import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
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
        context.push(AppRoutes.transactions);
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
      body: SafeArea(
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
      ),
    );
  }
}

class _Body extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.arrow_downward,
                  foreground: AppColors.primary,
                  background: AppColors.primarySoft,
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
                  foreground: AppColors.error,
                  background: AppColors.dangerSoft,
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
                  foreground: AppColors.warning,
                  background: AppColors.warningSoft,
                  label: AppStrings.reportsSavedLabel,
                  value: report.savingsMonth,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PlainCard(
                  icon: Icons.show_chart_outlined,
                  foreground: AppColors.secondary,
                  background: AppColors.secondarySoft,
                  label: AppStrings.reportsInvestedLabel,
                  value: report.investmentMonth,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RemainingCard(net: report.net),
          const SizedBox(height: 16),
          const ReportSectionTitle(AppStrings.reportsVsTitle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: IncomeExpenseBars(
              income: report.income,
              expense: report.expense,
            ),
          ),
          const SizedBox(height: 16),
          InsightCard(
            icon: Icons.bar_chart_outlined,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primarySoft,
            title: AppStrings.reportsMonthSummary,
            body: report.expense <= report.income
                ? AppStrings.reportsWithinBudget
                : AppStrings.reportsOverBudget,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () => context.push(AppRoutes.reportsExpenses),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
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
                color: good! ? AppColors.primary : AppColors.error,
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.secondarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.secondary,
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
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
