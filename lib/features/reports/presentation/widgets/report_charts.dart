import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// Palet kategori donut (konsisten di seluruh laporan).
const List<Color> reportPalette = [
  AppColors.secondary,
  AppColors.primary,
  AppColors.warning,
  Color(0xFF8B5CF6),
  AppColors.error,
  Color(0xFF14B8A6),
  AppColors.textSecondary,
];

/// Grafik batang Pemasukan vs Pengeluaran + label nilai.
class IncomeExpenseBars extends StatelessWidget {
  const IncomeExpenseBars({
    super.key,
    required this.income,
    required this.expense,
    this.height = 170,
  });

  final double income;
  final double expense;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxValue = [income, expense, 1.0].reduce((a, b) => a > b ? a : b);
    Widget bar(double value, Color color, String label) {
      final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatCompact(value),
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: (height * ratio).clamp(4.0, height),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: textTheme.labelSmall),
          ],
        ),
      );
    }

    return SizedBox(
      height: height + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bar(income, AppColors.primary, 'Pemasukan'),
          const SizedBox(width: 32),
          bar(expense, const Color(0xFFF87171), 'Pengeluaran'),
        ],
      ),
    );
  }
}

/// Donat pengeluaran per kategori + total di tengah.
/// Data kosong -> cincin abu + tanda '-'.
class ExpenseDonut extends StatelessWidget {
  const ExpenseDonut({
    super.key,
    required this.values,
    required this.total,
    this.size = 150,
  });

  final List<double> values;
  final double total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasData = total > 0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              values: hasData ? values : const [1],
              colors: hasData
                  ? [
                      for (var i = 0; i < values.length; i++)
                        reportPalette[i % reportPalette.length],
                    ]
                  : const [Color(0xFFE5E7EB)],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasData
                    ? CurrencyFormatter.formatCompact(total)
                    : '-',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Total Pengeluaran',
                style: textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    if (total <= 0 || values.isEmpty) {
      paint.color = colors.first;
      canvas.drawCircle(center, radius - 11, paint);
      return;
    }
    var start = -90.0 * 3.1415926535 / 180.0;
    for (var i = 0; i < values.length; i++) {
      final sweep =
          (values[i] / total) * 2 * 3.1415926535;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 11),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values;
}

/// Bar grup 6 bulan (tabungan hijau + investasi biru) + label bulan.
class SavingsBars extends StatelessWidget {
  const SavingsBars({
    super.key,
    required this.savings,
    required this.investments,
    required this.labels,
    this.height = 130,
  });

  final List<double> savings;
  final List<double> investments;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    assert(savings.length == investments.length &&
        savings.length == labels.length);
    final maxValue = [
      ...savings,
      ...investments,
      1.0,
    ].reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < savings.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MiniBar(
                            value: savings[i],
                            max: maxValue,
                            height: height - 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          _MiniBar(
                            value: investments[i],
                            max: maxValue,
                            height: height - 20,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(labels[i], style: textTheme.labelSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.value,
    required this.max,
    required this.height,
    required this.color,
  });

  final double value;
  final double max;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Container(
      width: 10,
      height: (height * ratio).clamp(3.0, height),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Ring skor kesehatan 0..100 (atau '-' bila data tak cukup).
class HealthRing extends StatelessWidget {
  const HealthRing({
    super.key,
    required this.score,
    required this.levelLabel,
    this.size = 150,
  });

  final int? score;
  final String levelLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score == null ? 0 : score! / 100,
              strokeWidth: 14,
              backgroundColor: const Color(0xFFEEF1F4),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score == null ? '-' : '$score / 100',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                levelLabel,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Label bulan pendek untuk sumbu ("Okt").
String shortMonthLabel(DateTime month) =>
    DateFormatter.shortMonth(month.month);
