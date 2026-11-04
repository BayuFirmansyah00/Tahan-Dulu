import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/goals_controller.dart';
import '../utils/goal_category_ui.dart';
import '../widgets/goal_widgets.dart';

/// Prioritas Target: susun ulang dengan panah, simpan urutan.
/// Label Tinggi/Sedang/Rendah diturunkan dari posisi (terdokumentasi).
class GoalPriorityScreen extends ConsumerStatefulWidget {
  const GoalPriorityScreen({super.key});

  @override
  ConsumerState<GoalPriorityScreen> createState() =>
      _GoalPriorityScreenState();
}

class _GoalPriorityScreenState extends ConsumerState<GoalPriorityScreen> {
  List<String>? _order;
  bool _saving = false;

  void _move(List<String> order, int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= order.length) return;
    setState(() {
      final ids = List.of(order);
      final moved = ids.removeAt(index);
      ids.insert(next, moved);
      _order = ids;
    });
  }

  Future<void> _save(List<String> order) async {
    setState(() => _saving = true);
    try {
      final ok = await ref
          .read(goalsControllerProvider.notifier)
          .saveOrder(order);
      if (!mounted) return;
      if (ok) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsListProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.priorityTitle),
      ),
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
                if (items.isEmpty) {
                  return const Center(
                    child: Text(AppStrings.historyEmpty),
                  );
                }
                final order =
                    _order ?? [for (final e in items) e.id];
                final byId = {for (final e in items) e.id: e};
                final ordered = [
                  for (final id in order)
                    if (byId.containsKey(id)) byId[id]!,
                ];
                if (_order == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _order == null) {
                      setState(() => _order = order);
                    }
                  });
                }
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: textTheme.headlineMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color:
                                                AppColors.textPrimary,
                                          ),
                                          children: const [
                                            TextSpan(
                                              text: AppStrings
                                                  .priorityQuestionLead,
                                            ),
                                            TextSpan(
                                              text: AppStrings
                                                  .priorityQuestionAccent,
                                              style: TextStyle(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppStrings.priorityHint,
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.asset(
                                  AppAssets.priorityChecklistHeader,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.contain,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) =>
                                      const SizedBox(
                                          width: 110, height: 110),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            for (var i = 0; i < ordered.length; i++)
                              _PriorityCard(
                                goal: ordered[i],
                                index: i,
                                canUp: i > 0,
                                canDown: i < ordered.length - 1,
                                onUp: () => _move(order, i, -1),
                                onDown: () => _move(order, i, 1),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.infoSoft,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const AppImageIcon(
                                    assetPath: AppAssets.statusInfo,
                                    size: 32,
                                    fallbackIcon: Icons.info,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppStrings.priorityInfoTitle,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppStrings.priorityInfoBody,
                                          style: textTheme.bodyMedium
                                              ?.copyWith(fontSize: 12.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: AppButton(
                        label: AppStrings.savePriorityAction,
                        icon: Icons.save_outlined,
                        isLoading: _saving,
                        onPressed:
                            _saving ? null : () => _save(order),
                      ),
                    ),
                  ],
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

/// Kartu peringkat sesuai referensi: highlight mint untuk peringkat
/// pertama, medali/badge PNG, ikon kategori, progres, badge peringkat,
/// dan tombol naik/turun PNG 48px yang benar-benar mengubah urutan.
class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.goal,
    required this.index,
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
  });

  final FinancialGoal goal;
  final int index;
  final bool canUp;
  final bool canDown;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final first = index == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: first ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: first ? AppColors.primary : AppColors.border,
          width: first ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: first
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RankMedal(rank: index + 1),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: GoalIcon(category: goal.category, size: 44),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(goal.progress.clamp(0.0, 1.0) * 100).round()}%',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  goalCategoryLabel(goal.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                GoalLinearProgress(value: goal.progress, height: 6),
                const SizedBox(height: 6),
                _RankBadgeChip(index: index),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MoveButton(up: true, enabled: canUp, onTap: onUp),
              const SizedBox(height: 8),
              _MoveButton(up: false, enabled: canDown, onTap: onDown),
            ],
          ),
        ],
      ),
    );
  }
}

/// Medali/badge peringkat 1–5 dari aset lokal; di atas itu lingkaran
/// angka dinamis agar tidak mengulang angka 5.
class _RankMedal extends StatelessWidget {
  const _RankMedal({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final String? asset;
    switch (rank) {
      case 1:
        asset = AppAssets.rankMedal1;
      case 2:
        asset = AppAssets.rankMedal2;
      case 3:
        asset = AppAssets.rankMedal3;
      case 4:
        asset = AppAssets.rankBadge4;
      case 5:
        asset = AppAssets.rankBadge5;
      default:
        asset = null;
    }
    if (asset == null) return _RankNumber(rank: rank);
    return Image.asset(
      asset,
      width: 54,
      height: 54,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _RankNumber(rank: rank),
    );
  }
}

/// Lingkaran angka peringkat untuk posisi di atas lima.
class _RankNumber extends StatelessWidget {
  const _RankNumber({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
      ),
    );
  }
}

/// Badge peringkat mengikuti urutan aktual (bukan progres).
class _RankBadgeChip extends StatelessWidget {
  const _RankBadgeChip({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color foreground;
    final Color background;
    final String asset;
    final IconData icon;
    switch (index) {
      case 0:
        label = AppStrings.priorityFirst;
        foreground = AppColors.primary;
        background = AppColors.primarySoft;
        asset = AppAssets.rankMedal1;
        icon = Icons.emoji_events_outlined;
      case 1:
        label = AppStrings.prioritySecond;
        foreground = AppColors.secondary;
        background = AppColors.infoSoft;
        asset = AppAssets.rankMedal2;
        icon = Icons.star;
      case 2:
        label = AppStrings.priorityThird;
        foreground = AppColors.warning;
        background = AppColors.warningSoft;
        asset = AppAssets.rankMedal3;
        icon = Icons.flag_outlined;
      default:
        label = AppStrings.priorityOthers;
        foreground = AppColors.accentPurple;
        background = AppColors.accentPurpleSoft;
        asset = AppAssets.rankBadge4;
        icon = Icons.work_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppImageIcon(
            assetPath: asset,
            size: 14,
            fallbackIcon: icon,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol naik/turun 48px dari aset lokal (varian abu bila nonaktif).
class _MoveButton extends StatelessWidget {
  const _MoveButton({
    required this.up,
    required this.enabled,
    required this.onTap,
  });

  final bool up;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String asset;
    if (up) {
      asset = enabled ? AppAssets.moveUp : AppAssets.moveUpDisabled;
    } else {
      asset = enabled ? AppAssets.moveDown : AppAssets.moveDownDisabled;
    }
    return IconButton(
      iconSize: 44,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      tooltip: up
          ? AppStrings.priorityMoveUp
          : AppStrings.priorityMoveDown,
      onPressed: enabled ? onTap : null,
      icon: Image.asset(
        asset,
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            color: enabled
                ? AppColors.primary
                : AppColors.textDisabled,
            size: 24,
          ),
        ),
      ),
    );
  }
}
