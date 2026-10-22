import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/models/goal_deposit.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../widgets/goal_widgets.dart';

/// Riwayat Setoran: ringkasan + grafik progres nyata + daftar.
/// Grafik hanya dari setoran tercatat (>=2 titik), else empty state.
class GoalHistoryScreen extends ConsumerWidget {
  const GoalHistoryScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsListProvider);
    final deposits = ref.watch(goalDepositsProvider(goalId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historyTitle)),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 3,
        onTap: (i) => goalsBottomNavTap(context, i),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: goals.when(
              data: (items) {
                final matches = items.where((e) => e.id == goalId);
                if (matches.isEmpty) {
                  return const GoalNotFoundView();
                }
                return deposits.when(
                  data: (list) =>
                      _Body(goal: matches.first, deposits: list),
                  loading: () => const AppLoading(),
                  error: (e, _) => Center(
                    child: AppErrorState(
                      onRetry: () =>
                          ref.invalidate(goalDepositsProvider(goalId)),
                    ),
                  ),
                );
              },
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(goalsListProvider)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kelompok setoran per bulan kalender (terbaru dulu).
/// Murni UI grouping dari data tersimpan; tanpa mengubah data.
/// Mengembalikan pasangan (label "Bulan Tahun", daftar setoran).
List<(String label, List<GoalDeposit> items)> groupDepositsByMonth(
  List<GoalDeposit> deposits,
) {
  final groups = <String, List<GoalDeposit>>{};
  final order = <String>[];
  for (final deposit in deposits) {
    final key =
        '${deposit.date.year}-${deposit.date.month.toString().padLeft(2, '0')}';
    if (!groups.containsKey(key)) {
      groups[key] = [];
      order.add(key);
    }
    groups[key]!.add(deposit);
  }
  return [
    for (final key in order)
      (DateFormatter.monthYear(groups[key]!.first.date), groups[key]!),
  ];
}

class _Body extends StatelessWidget {
  const _Body({required this.goal, required this.deposits});

  final FinancialGoal goal;
  final List<GoalDeposit> deposits;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total =
        deposits.fold<double>(0, (sum, e) => sum + e.amount);
    final months = _spanMonths(deposits);
    final average = months <= 0 ? total : total / months;
    final grouped = groupDepositsByMonth(deposits);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalSummaryHeader(goal: goal),
          const SizedBox(height: 16),
          Text(
            AppStrings.historyProgressTitle,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (deposits.length < 2)
            Text(
              AppStrings.historyEmpty,
              style: textTheme.bodyMedium,
            )
          else
            _ProgressChart(deposits: deposits),
          const SizedBox(height: 16),
          Text(
            AppStrings.historyTitle,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (deposits.isEmpty)
            Text(
              AppStrings.historyEmpty,
              style: textTheme.bodyMedium,
            )
          else
            for (final group in grouped) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  group.$1,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final deposit in group.$2)
                _DepositRow(deposit: deposit),
            ],
          const SizedBox(height: 12),
          _TotalRow(
            label: AppStrings.historyTotal,
            value: CurrencyFormatter.formatCompact(total),
          ),
          _TotalRow(
            label: AppStrings.historyAverage,
            value: CurrencyFormatter.formatCompact(average),
          ),
        ],
      ),
    );
  }
}

/// Rentang bulan kalender pertama-terakhir, minimal 1.
int _spanMonths(List<GoalDeposit> deposits) {
  if (deposits.isEmpty) return 1;
  var first = deposits.first.date;
  var last = deposits.first.date;
  for (final d in deposits) {
    if (d.date.isBefore(first)) first = d.date;
    if (d.date.isAfter(last)) last = d.date;
  }
  final span = (last.year - first.year) * 12 + (last.month - first.month) + 1;
  return span < 1 ? 1 : span;
}

/// Grafik garis kumulatif dari setoran nyata (min 2 titik).
class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.deposits});

  final List<GoalDeposit> deposits;

  @override
  Widget build(BuildContext context) {
    final ascending = List.of(deposits)
      ..sort((a, b) => a.date.compareTo(b.date));
    double running = 0;
    final points = <double>[];
    for (final d in ascending) {
      running += d.amount;
      points.add(running);
    }
    final labels = [
      for (final d in ascending)
        DateFormatter.shortMonth(d.date.month),
    ];
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: CustomPaint(
        painter: _LinePainter(points: points, labels: labels),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.points, required this.labels});

  final List<double> points;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final minValue = 0.0;
    final span = (maxValue - minValue) <= 0 ? 1.0 : maxValue - minValue;
    const leftPad = 4.0;
    const bottomPad = 18.0;
    final plotW = size.width - leftPad * 2;
    final plotH = size.height - bottomPad - 4;

    Offset at(int i) {
      final x = leftPad +
          (points.length == 1 ? 0.5 : i / (points.length - 1)) * plotW;
      final y = 4 + plotH * (1 - (points[i] - minValue) / span);
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(at(i), 3, dotPaint);
    }

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    final step = (points.length / 4).ceil().clamp(1, points.length);
    for (var i = 0; i < points.length; i += step) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(at(i).dx - textPainter.width / 2, size.height - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _DepositRow extends StatelessWidget {
  const _DepositRow({required this.deposit});

  final GoalDeposit deposit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.dayMonthYear(deposit.date),
                  style: textTheme.titleMedium,
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final data = ref
                        .watch(onboardingRepositoryProvider)
                        .getOnboardingData();
                    final names = {
                      for (final e
                          in data?.financialInstruments ?? const [])
                        e.id: e.name,
                    };
                    final source = deposit.accountId == null
                        ? null
                        : names[deposit.accountId];
                    if (source == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(source, style: textTheme.bodyMedium);
                  },
                ),
              ],
            ),
          ),
          Text(
            '+${CurrencyFormatter.formatCompact(deposit.amount)}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
