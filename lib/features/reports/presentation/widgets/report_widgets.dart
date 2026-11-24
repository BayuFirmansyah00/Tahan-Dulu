import 'package:flutter/material.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/utils/date_formatter.dart';

/// Pemilih periode: chevron kiri/kanan + label bulan Indonesia + date picker.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    this.onSelectPeriod,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime>? onSelectPeriod;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: Glass.panel(context, radius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: context.palette.onSurface,
            onPressed: onPrevious,
          ),
          Flexible(
            child: InkWell(
              onTap: onSelectPeriod == null
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: month,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        onSelectPeriod!(picked);
                      }
                    },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        DateFormatter.monthYear(month),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: context.palette.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: context.palette.onSurface,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// Judul seksi tebal gaya laporan.
class ReportSectionTitle extends StatelessWidget {
  const ReportSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// Kartu insight mint/biru muda + ikon.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String body;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(body, style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
