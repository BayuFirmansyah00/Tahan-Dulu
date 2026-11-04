import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/providers/app_providers.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Masa TahanDulu: pilih durasi, countdown dari timestamp, refleksi.
/// Simpan & Tunggu menulis wait eksplisit (tanpa notifikasi otomatis).
///
/// Tahap 46: ringkasan 3D, opsi periode kuning aktif, kartu refleksi
/// nyaman, CTA kuning. Opsi periode, pertanyaan, dan mekanisme
/// reminder tidak diubah (tanpa janji notifikasi baru).
class TahanDuluWaitScreen extends ConsumerStatefulWidget {
  const TahanDuluWaitScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<TahanDuluWaitScreen> createState() =>
      _TahanDuluWaitScreenState();
}

class _TahanDuluWaitScreenState extends ConsumerState<TahanDuluWaitScreen> {
  int _hours = 24;
  final Map<String, bool?> _reflections = {};
  String? _frequency;
  bool _saving = false;

  Future<void> _save(String id) async {
    setState(() => _saving = true);
    try {
      final ok = await ref
          .read(tahanDuluControllerProvider.notifier)
          .startWait(id, _hours);
      if (!mounted) return;
      if (ok) {
        context.go(AppRoutes.tahanDulu);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.saveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(considerationsProvider);
    final exists = items.value?.any((e) => e.id == widget.itemId) ?? false;
    final textTheme = Theme.of(context).textTheme;

    return TahanDuluScaffold(
      title: AppStrings.waitDurationLabel,
      bottomButton: AppButton(
        label: AppStrings.saveAndWaitAction,
        backgroundColor: TdColors.primary,
        foregroundColor: TdColors.navy,
        isLoading: _saving,
        onPressed: _saving || !exists ? null : () => _save(widget.itemId),
      ),
      child: items.when(
        data: (all) {
          final matches = all.where((e) => e.id == widget.itemId);
          if (matches.isEmpty) {
            return const Center(child: Text(AppStrings.accountNotFound));
          }
          final item = matches.first;
          final now = DateTime.now();
          final active = item.isWaitingAt(now);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: TdHeroImage(
                    asset: TdHeaderArt.wait,
                    fallbackAsset:
                        'assets/illustrations/illustration_masa_tunggu.png',
                    height: 120,
                    width: 210,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.waitTitle,
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    color: TdColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.waitSubtitle,
                  style: textTheme.bodyMedium?.copyWith(color: TdColors.slate),
                ),
                const SizedBox(height: 12),
                TdCard(
                  child: Row(
                    children: [
                      TdCategoryIcon(category: item.category, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: TdColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatCompact(item.price),
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: TdColors.navy,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: TdColors.highlight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                productCategoryLabel(item.category),
                                style: textTheme.labelSmall?.copyWith(
                                  color: TdColors.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih periode masa tunggu',
                  style: textTheme.titleMedium?.copyWith(
                    color: TdColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < waitOptionsHours.length; i++) ...[
                      Expanded(
                        child: _DurationChip(
                          label: waitHoursLabel(waitOptionsHours[i]),
                          selected: _hours == waitOptionsHours[i],
                          onTap: () =>
                              setState(() => _hours = waitOptionsHours[i]),
                        ),
                      ),
                      if (i < waitOptionsHours.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (active) ...[
                  _CountdownCard(endsAt: item.waitEndsAt!),
                  const SizedBox(height: 12),
                ],
                Text(
                  AppStrings.waitReflectTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: TdColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _ReflectCard(
                  assetPath: AppAssets.txInvestment,
                  icon: Icons.eco_outlined,
                  question: AppStrings.waitReflectQ1,
                  value: _reflections['q1'],
                  onPick: (v) => setState(() => _reflections['q1'] = v),
                ),
                const SizedBox(height: 8),
                _ReflectCard(
                  assetPath: AppAssets.goalHouse,
                  icon: Icons.home_outlined,
                  question: AppStrings.waitReflectQ2,
                  value: _reflections['q2'],
                  onPick: (v) => setState(() => _reflections['q2'] = v),
                ),
                const SizedBox(height: 8),
                TdCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppImageIcon(
                            assetPath: AppAssets.dashChart,
                            size: 22,
                            fallbackIcon: Icons.bar_chart_outlined,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.waitFrequencyLabel,
                              style: textTheme.bodyMedium?.copyWith(
                                color: TdColors.navy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _frequency,
                        hint: const Text(AppStrings.waitFrequencyDaily),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Setiap hari'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Setiap minggu'),
                          ),
                          DropdownMenuItem(
                            value: 'rarely',
                            child: Text('Jarang'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _frequency = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppImageIcon(
                      assetPath: AppAssets.statusInfo,
                      size: 16,
                      fallbackIcon: Icons.info_outline,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppStrings.waitNotifyNote,
                        style: textTheme.bodyMedium?.copyWith(
                          color: TdColors.slate,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (error, _) => AppErrorState(
          onRetry: () => ref.invalidate(considerationsProvider),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
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
          color: selected ? TdColors.primary : TdColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? TdColors.primary : TdColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: TdColors.navy,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.endsAt});

  final DateTime endsAt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TdColors.highlight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TdColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppImageIcon(
                assetPath: AppAssets.actionCalendar,
                size: 20,
                fallbackIcon: Icons.access_time,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.waitCountdownTitle,
                style: textTheme.titleMedium?.copyWith(
                  color: TdColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatWaitRemaining(endsAt, DateTime.now()),
            style: textTheme.headlineMedium?.copyWith(
              color: TdColors.navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu refleksi: ikon + pertanyaan + pil Ya/Tidak.
class _ReflectCard extends StatelessWidget {
  const _ReflectCard({
    this.icon,
    this.assetPath,
    required this.question,
    required this.value,
    required this.onPick,
  });

  final IconData? icon;
  final String? assetPath;
  final String question;
  final bool? value;
  final ValueChanged<bool> onPick;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, bool picked, bool pickValue) {
      return Expanded(
        child: GestureDetector(
          onTap: () => onPick(pickValue),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: picked ? TdColors.primary : TdColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: picked ? TdColors.primary : TdColors.border,
                width: picked ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TdColors.navy,
                fontWeight: picked ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return TdCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: TdColors.successBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: assetPath != null
                  ? AppImageIcon(
                      assetPath: assetPath!,
                      size: 22,
                      fallbackIcon: icon ?? Icons.eco_outlined,
                    )
                  : Icon(icon, color: TdColors.success, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TdColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    pill('Ya', value == true, true),
                    const SizedBox(width: 8),
                    pill('Tidak', value == false, false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
