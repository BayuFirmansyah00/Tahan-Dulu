import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/monthly_report.dart';
import '../../../../data/providers/reports_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../widgets/report_charts.dart';
import '../widgets/report_widgets.dart';

/// Tabungan & Investasi: progres, histori 6 bulan, insight alokasi.
class ReportSavingsScreen extends ConsumerWidget {
  const ReportSavingsScreen({super.key});

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
      appBar: AppBar(title: const Text(AppStrings.savingsInvestTitle)),
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

  double _progress(double saved, double target) =>
      target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final allocated = report.savingsMonth + report.investmentMonth;
    final hasHistory = report.lastSix.any(
      (p) => p.savings > 0 || p.investment > 0,
    );

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
          _PlanCard(
            asset: AppAssets.txSavings,
            fallbackIcon: Icons.savings_outlined,
            foreground: AppColors.primary,
            background: AppColors.primarySoft,
            title: AppStrings.legendSavings,
            subtitle: AppStrings.savedThisMonth,
            monthAmount: report.savingsMonth,
            target: report.savingsTarget,
            saved: report.savingsSaved,
            progress: _progress(report.savingsSaved, report.savingsTarget),
          ),
          const SizedBox(height: 10),
          _PlanCard(
            asset: AppAssets.txInvestment,
            fallbackIcon: Icons.show_chart_outlined,
            foreground: AppColors.secondary,
            background: AppColors.secondarySoft,
            title: AppStrings.legendInvestment,
            subtitle: AppStrings.investedThisMonth,
            monthAmount: report.investmentMonth,
            target: report.investmentTarget,
            saved: report.investmentSaved,
            progress: _progress(
              report.investmentSaved,
              report.investmentTarget,
            ),
          ),
          const SizedBox(height: 16),
          const ReportSectionTitle(AppStrings.lastSixTitle),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _LegendDot(
                      color: AppColors.primary,
                      label: AppStrings.legendSavings,
                    ),
                    SizedBox(width: 16),
                    _LegendDot(
                      color: AppColors.secondary,
                      label: AppStrings.legendInvestment,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasHistory)
                  SavingsBars(
                    savings: [
                      for (final p in report.lastSix) p.savings,
                    ],
                    investments: [
                      for (final p in report.lastSix) p.investment,
                    ],
                    labels: [
                      for (final p in report.lastSix)
                        shortMonthLabel(p.month),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      AppStrings.emptyChartData,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InsightCard(
            icon: Icons.trending_up_outlined,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primarySoft,
            title: AppStrings.savingsInvestTitle,
            body: allocated > 0
                ? '${AppStrings.allocationInsightPrefix} '
                    '${CurrencyFormatter.formatCompact(allocated)} '
                    '${AppStrings.allocationInsightSuffix}'
                : AppStrings.noAllocationYet,
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.reportsHealth),
              child: Text(
                '${AppStrings.healthTitle} >',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.asset,
    required this.fallbackIcon,
    required this.foreground,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.monthAmount,
    required this.target,
    required this.saved,
    required this.progress,
  });

  final String asset;
  final IconData fallbackIcon;
  final Color foreground;
  final Color background;
  final String title;
  final String subtitle;
  final double monthAmount;
  final double target;
  final double saved;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.goals),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      asset,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(
                        fallbackIcon,
                        color: foreground,
                        size: 20,
                      ),
                    ),
                  ),
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
                        ),
                      ),
                      Text(subtitle, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.formatCompact(monthAmount),
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFEEF1F4),
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${CurrencyFormatter.formatCompact(saved)}'
                    ' / ${CurrencyFormatter.formatCompact(target)}',
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
