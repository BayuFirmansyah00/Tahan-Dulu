import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/financial_goal.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../../core/widgets/app_icons.dart';
import '../utils/goal_category_ui.dart';

/// Navigasi bawah standar semua layar Goals (tab Target aktif).
void goalsBottomNavTap(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRoutes.dashboard);
    case 1:
    case 2:
      context.push(AppRoutes.transactions);
    case 3:
      break;
    case 4:
      context.push(AppRoutes.settings);
  }
}

/// Progress bar hijau + track abu (satu gaya untuk semua layar Goals).
class GoalLinearProgress extends StatelessWidget {
  const GoalLinearProgress({super.key, required this.value, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: const Color(0xFFEEF1F4),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }
}

/// Ring progres melingkar dengan % di tengah (layar detail).
class GoalCircularProgress extends StatelessWidget {
  const GoalCircularProgress({super.key, required this.progress, this.size = 148});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final percent = '${(progress * 100).round()}%';
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
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 12,
              backgroundColor: const Color(0xFFEEF1F4),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Text(
            percent,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/// Ikon kategori fitur Goals (paket assets/icons + fallback outline).
/// Khusus layar Goals; dashboard & onboarding memakai pemetaan lain.
class GoalIcon extends StatelessWidget {
  const GoalIcon({super.key, required this.category, this.size = 48});

  final GoalCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      goalFeatureIconFor(category),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => AppIconFallback(
        icon: goalCategoryIcon(category),
        size: size,
      ),
    );
  }
}

/// Header ilustrasi besar per kategori (Tahap 32, terpusat).
/// Dipakai di atas layar create/setup/detail/deposit/history/
/// simulate/edit; fallback konsisten tanpa crash bila gagal muat.
class GoalHeader extends StatelessWidget {
  const GoalHeader({
    super.key,
    required this.category,
    this.height = 160,
  });

  final GoalCategory category;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        goalHeaderFor(category),
        height: height,
        fit: BoxFit.contain,
        semanticLabel: goalCategoryLabel(category),
        errorBuilder: (context, error, stackTrace) => AppIconFallback(
          icon: goalCategoryIcon(category),
          size: 72,
        ),
      ),
    );
  }
}

/// Ringkasan target (ikon + nama + nominal + progres) untuk
/// kepala layar deposit/riwayat/simulasi. Satu gaya, satu sumber.
class GoalSummaryHeader extends StatelessWidget {
  const GoalSummaryHeader({super.key, required this.goal});

  final FinancialGoal goal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GoalIcon(category: goal.category, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.formatCompact(goal.currentAmount)}'
                      ' / ${CurrencyFormatter.formatCompact(goal.targetAmount)}',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                '${(goal.progress.clamp(0.0, 1.0) * 100).round()}%',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoalLinearProgress(value: goal.progress, height: 6),
        ],
      ),
    );
  }
}

/// Tile kategori untuk grid (dipakai layar buat target).
class GoalCategoryTile extends StatelessWidget {
  const GoalCategoryTile({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final GoalCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              goalFeatureIconFor(category),
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                goalCategoryIcon(category),
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              goalCategoryLabel(category),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle frekuensi Per bulan / Per minggu.
class FrequencyToggle extends StatelessWidget {
  const FrequencyToggle({
    super.key,
    required this.frequency,
    required this.onChanged,
  });

  final DepositFrequency frequency;
  final ValueChanged<DepositFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget pill(DepositFrequency value, String label) {
      final selected = frequency == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(DepositFrequency.monthly, AppStrings.frequencyMonthly),
        const SizedBox(width: 10),
        pill(DepositFrequency.weekly, AppStrings.frequencyWeekly),
      ],
    );
  }
}

/// Dropdown sumber dana dari instrumen onboarding (opsional).
class GoalAccountDropdown extends ConsumerWidget {
  const GoalAccountDropdown({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data =
        ref.watch(onboardingRepositoryProvider).getOnboardingData();
    final instruments = data?.financialInstruments ?? const [];
    if (instruments.isEmpty) return const SizedBox.shrink();
    final ids = {for (final e in instruments) e.id};
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value != null && ids.contains(value) ? value : null,
      hint: const Text(AppStrings.accountHint),
      items: [
        for (final e in instruments)
          DropdownMenuItem(
            value: e.id,
            child: Text(
              e.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Tampilan pemulihan saat id target tak dikenal di repository.
///
/// Mis. goal onboarding yang diketuk dari Dashboard: id-nya tidak ada di
/// [GoalRepository] sehingga detail tidak bisa dirender. Tampilkan pesan
/// yang benar (bukan "Akun tidak ditemukan") plus jalan kembali ke daftar.
class GoalNotFoundView extends StatelessWidget {
  const GoalNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.flag_outlined,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.goalNotFound,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AppOutlineButton(
              label: AppStrings.goalNotFoundAction,
              onPressed: () => context.go(AppRoutes.goals),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label prioritas berbentuk chip.
class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Badge peringkat bernomor untuk layar prioritas.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Kotak tanggal read-only bergaya input (buka date picker saat diketuk).
class GoalDateBox extends StatelessWidget {
  const GoalDateBox({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
