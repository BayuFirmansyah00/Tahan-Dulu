import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_icons.dart';
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
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.historyTitle),
      ),
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: 3,
        onTap: (i) => goalsBottomNavTap(context, i),
      ),
      body: GlassBackdrop(child: SafeArea(
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
      )),
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
        deposits.fold<double>(0, (sum, e) => sum + e.signedAmount);
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
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: CustomPaint(
        painter: _LinePainter(points: points, labels: labels, scheme: context.palette),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.points, required this.labels, required this.scheme});

  final ColorScheme scheme;

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
      ..color = scheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = scheme.primary;
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
        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
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
      oldDelegate.points != points || oldDelegate.labels != labels || oldDelegate.scheme != scheme;
}

class _DepositRow extends ConsumerWidget {
  const _DepositRow({required this.deposit});

  final GoalDeposit deposit;

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    deposit.isWithdraw ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
                    color: deposit.isWithdraw
                        ? Theme.of(sheetContext).colorScheme.error
                        : sheetContext.palette.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    deposit.isWithdraw ? 'Pencairan Target' : 'Setoran Target',
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailItem(
                label: 'Nominal',
                value: '${deposit.isWithdraw ? '-' : '+'}${CurrencyFormatter.format(deposit.amount)}',
                valueColor: deposit.isWithdraw
                    ? Theme.of(sheetContext).colorScheme.error
                    : sheetContext.palette.primary,
              ),
              _DetailItem(
                label: 'Tanggal',
                value: DateFormatter.dayMonthYear(deposit.date),
              ),
              Consumer(
                builder: (context, cRef, _) {
                  final data = cRef.watch(onboardingRepositoryProvider).getOnboardingData();
                  final names = {
                    for (final e in data?.financialInstruments ?? const []) e.id: e.name,
                  };
                  final source = deposit.accountId == null ? null : names[deposit.accountId];
                  if (source == null) return const SizedBox.shrink();
                  return _DetailItem(
                    label: deposit.isWithdraw ? 'Tujuan Pencairan' : 'Sumber Rekening',
                    value: source,
                  );
                },
              ),
              if (deposit.note != null && deposit.note!.isNotEmpty)
                _DetailItem(
                  label: 'Catatan',
                  value: deposit.note!,
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Edit Catatan'),
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        final noteController = TextEditingController(text: deposit.note ?? '');
                        final newNote = await showDialog<String>(
                          context: context,
                          builder: (dlgContext) => AlertDialog(
                            title: const Text('Ubah Catatan'),
                            content: TextField(
                              controller: noteController,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan catatan transaksi...',
                              ),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dlgContext).pop(),
                                child: const Text(AppStrings.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(dlgContext).pop(noteController.text.trim()),
                                child: const Text('Simpan'),
                              ),
                            ],
                          ),
                        );
                        if (newNote != null && context.mounted) {
                          try {
                            await ref.read(goalsControllerProvider.notifier).updateGoalTransaction(
                                  deposit: deposit.copyWith(note: newNote),
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Catatan berhasil diperbarui.')),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal memperbarui catatan.')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(sheetContext).colorScheme.error,
                        foregroundColor: Theme.of(sheetContext).colorScheme.onError,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: const Text('Hapus'),
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dlgContext) => AlertDialog(
                            title: const Text('Hapus Transaksi?'),
                            content: Text(
                              deposit.isWithdraw
                                  ? 'Penarikan sebesar ${CurrencyFormatter.format(deposit.amount)} akan dibatalkan dan saldo target akan bertambah kembali.'
                                  : 'Setoran sebesar ${CurrencyFormatter.format(deposit.amount)} akan dihapus dan akumulasi target akan berkurang.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dlgContext).pop(false),
                                child: const Text(AppStrings.cancel),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(dlgContext).colorScheme.error,
                                  foregroundColor: Theme.of(dlgContext).colorScheme.onError,
                                ),
                                onPressed: () => Navigator.of(dlgContext).pop(true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          try {
                            final ok = await ref.read(goalsControllerProvider.notifier).deleteGoalTransaction(
                                  goalId: deposit.goalId,
                                  depositId: deposit.id,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Transaksi target berhasil dihapus.'
                                      : 'Gagal menghapus transaksi.'),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal menghapus transaksi.')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isWithdraw = deposit.isWithdraw;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailSheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWithdraw
                        ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5)
                        : context.palette.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWithdraw ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
                    size: 18,
                    color: isWithdraw ? Theme.of(context).colorScheme.error : context.palette.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormatter.dayMonthYear(deposit.date),
                        style: textTheme.titleMedium,
                      ),
                      Consumer(
                        builder: (context, cRef, _) {
                          final data = cRef
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
                          final label = isWithdraw ? 'Pencairan' : 'Setoran';
                          final details = source != null ? '$label • $source' : label;
                          return Text(details, style: textTheme.bodyMedium);
                        },
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isWithdraw ? '-' : '+'}${CurrencyFormatter.formatCompact(deposit.amount)}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isWithdraw
                        ? Theme.of(context).colorScheme.error
                        : context.palette.primary,
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

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
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
