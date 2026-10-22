import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_health.dart';
import '../../../../data/providers/reports_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../../../goals/presentation/providers/goals_controller.dart'
    show goalsListProvider;
import '../widgets/report_charts.dart';
import '../widgets/report_widgets.dart';

/// Kesehatan Keuangan: skor transparan + indikator + rekomendasi aturan.
class ReportHealthScreen extends ConsumerWidget {
  const ReportHealthScreen({super.key});

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
      appBar: AppBar(title: const Text(AppStrings.healthTitle)),
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
                onPrevious: period.previous,
                onNext: period.next,
                income: r.income,
                expense: r.expense,
                savingsTarget: r.savingsTarget,
                savingsSaved: r.savingsSaved,
                remaining: r.net,
                goalProgress: _averageGoalProgress(ref),
              ),
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(monthlyReportProvider(month))),
            ),
          ),
        ),
      ),
    );
  }

  /// Progres rata-rata semua goals (null bila tanpa goals).
  double? _averageGoalProgress(WidgetRef ref) {
    final goals = ref.watch(goalsListProvider).value;
    if (goals == null || goals.isEmpty) return null;
    final sum = goals.fold<double>(0, (s, g) => s + g.progress);
    return sum / goals.length;
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.income,
    required this.expense,
    required this.savingsTarget,
    required this.savingsSaved,
    required this.remaining,
    required this.goalProgress,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final double income;
  final double expense;
  final double savingsTarget;
  final double savingsSaved;
  final double remaining;
  final double? goalProgress;

  @override
  Widget build(BuildContext context) {
    final health = evaluateFinancialHealth(
      monthIncome: income,
      monthExpense: expense,
      savingsProgress:
          savingsTarget > 0 ? savingsSaved / savingsTarget : null,
      remaining: remaining,
      goalProgress: goalProgress,
    );
    final insufficient = health.level == HealthLevel.insufficient;

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
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HealthRing(
                score: insufficient ? null : health.score,
                levelLabel: healthLevelLabel(health.level),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Image.asset(
                  AppAssets.headerKesehatanKeuangan,
                  height: 150,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 150),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InsightCard(
            icon: Icons.spa_outlined,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primarySoft,
            title: healthLevelLabel(health.level),
            body: insufficient
                ? AppStrings.healthInsufficientHint
                : AppStrings.healthGoodBody,
          ),
          const SizedBox(height: 12),
          for (final indicator in health.indicators)
            _IndicatorRow(indicator: indicator),
          const SizedBox(height: 12),
          InsightCard(
            icon: Icons.lightbulb_outline,
            iconColor: AppColors.secondary,
            iconBackground: AppColors.secondarySoft,
            title: AppStrings.healthInsightTitle,
            body: _insightBody(health),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              builder: (context) => _RecommendationsSheet(
                health: health,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: AppStrings.seeRecommendations,
            onPressed: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              builder: (context) => _RecommendationsSheet(
                health: health,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _insightBody(HealthScore health) {
    if (health.level == HealthLevel.insufficient) {
      return AppStrings.healthInsufficientHint;
    }
    return AppStrings.healthGoodBody;
  }
}

class _IndicatorRow extends StatelessWidget {
  const _IndicatorRow({required this.indicator});

  final HealthIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ok = (indicator.score ?? 0) >= 50;
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ok ? AppColors.primarySoft : const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              ok ? Icons.check : Icons.priority_high,
              color: ok ? AppColors.primary : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicator.title,
                  style: textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                Text(indicator.detail, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsSheet extends StatelessWidget {
  const _RecommendationsSheet({required this.health});

  final HealthScore health;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.recommendationsTitle,
              style: textTheme.headlineMedium?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.recommendationsNote,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            for (final indicator in health.indicators)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      (indicator.score ?? 0) >= 50
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      size: 18,
                      color: (indicator.score ?? 0) >= 50
                          ? AppColors.primary
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            indicator.title,
                            style: textTheme.titleMedium
                                ?.copyWith(fontSize: 14),
                          ),
                          Text(
                            indicator.detail,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
