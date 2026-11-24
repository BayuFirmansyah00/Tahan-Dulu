import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../../data/providers/onboarding_providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../onboarding/presentation/providers/budget_controller.dart';
import '../../../onboarding/presentation/providers/expenses_controller.dart';
import '../../../onboarding/presentation/providers/goal_controller.dart';
import '../../../onboarding/presentation/providers/salary_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/onboarding_status_provider.dart';

/// Layar penyelesaian onboarding: ringkasan rencana keuangan + CTA masuk.
/// Menggunakan 3D assets dan kartu minimalis modern sesuai desain resmi.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _hydratePlanData();
      }
    });
  }

  Future<void> _hydratePlanData() async {
    final repo = ref.read(onboardingRepositoryProvider);
    await repo.hydrateAll();
    if (!mounted) return;
    await ref.read(budgetControllerProvider.notifier).loadExisting();
    await ref.read(salaryControllerProvider.notifier).loadExisting();
    await ref.read(expensesControllerProvider.notifier).loadExisting();
    await ref.read(goalControllerProvider.notifier).loadExisting();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(financialPlanProvider);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayGoalAmount = plan.goalMonthlyContribution > 0
        ? plan.goalMonthlyContribution
        : (plan.investasiTabungan > 0 ? plan.investasiTabungan : 2142857.0);

    return Scaffold(
      body: GlassBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  // App Bar / Back Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.palette.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.palette.outlineVariant
                                    .withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: context.palette.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kartu Pemasukan Bulanan
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? const [
                                        Color(0xFF133E35),
                                        Color(0xFF0F2E27),
                                      ]
                                    : const [
                                        Color(0xFFDCFCE7),
                                        Color(0xFFF0FDF4),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E5247)
                                    : const Color(0xFFBBF7D0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF16A34A,
                                  ).withValues(alpha: 0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pemasukan Bulanan',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: isDark
                                              ? const Color(0xFF86EFAC)
                                              : const Color(0xFF166534),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.formatCompact(
                                          plan.monthlyIncome,
                                        ),
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                              fontSize: 24,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Image.asset(
                                  AppAssets.ob3dWallet,
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Header Bagian Alokasi Bulanan
                          Text(
                            'Alokasi Bulanan',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Daftar Alokasi Bulanan (Single Reusable Panel)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: context.palette.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? context.palette.outlineVariant
                                    : const Color(0xFFF1F5F9),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.03,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _AllocationItemRow(
                                  assetPath: AppAssets.ob3dNeeds,
                                  title: 'Kebutuhan',
                                  subtitle:
                                      '${plan.kebutuhanPokokPercent.toStringAsFixed(0)}% dari pemasukan',
                                  percentage: plan.kebutuhanPokokPercent,
                                  amount: plan.kebutuhanPokok,
                                  badgeBgColor: const Color(0xFFDCFCE7),
                                  badgeTextColor: const Color(0xFF16A34A),
                                ),
                                const Divider(height: 18, thickness: 0.8),
                                _AllocationItemRow(
                                  assetPath: AppAssets.ob3dFlexible,
                                  title: 'Pengeluaran Fleksibel',
                                  subtitle:
                                      '${plan.pengeluaranBebasPercent.toStringAsFixed(0)}% dari pemasukan',
                                  percentage: plan.pengeluaranBebasPercent,
                                  amount: plan.pengeluaranBebas,
                                  badgeBgColor: const Color(0xFFFEF3C7),
                                  badgeTextColor: const Color(0xFFD97706),
                                ),
                                const Divider(height: 18, thickness: 0.8),
                                _AllocationItemRow(
                                  assetPath: AppAssets.ob3dInvestment,
                                  title: 'Investasi & Tabungan',
                                  subtitle:
                                      '${plan.investasiTabunganPercent.toStringAsFixed(0)}% dari pemasukan',
                                  percentage: plan.investasiTabunganPercent,
                                  amount: plan.investasiTabungan,
                                  badgeBgColor: const Color(0xFFDBEAFE),
                                  badgeTextColor: const Color(0xFF2563EB),
                                ),
                                const Divider(height: 18, thickness: 0.8),
                                _AllocationItemRow(
                                  assetPath: AppAssets.ob3dEmergency,
                                  title: 'Dana Darurat',
                                  subtitle:
                                      '${plan.danaDaruratPercent.toStringAsFixed(0)}% dari pemasukan',
                                  percentage: plan.danaDaruratPercent,
                                  amount: plan.danaDarurat,
                                  badgeBgColor: const Color(0xFFDCFCE7),
                                  badgeTextColor: const Color(0xFF16A34A),
                                ),
                                if (plan.unallocated > 0) ...[
                                  const Divider(height: 18, thickness: 0.8),
                                  _AllocationItemRow(
                                    assetPath: AppAssets.ob3dFlexible,
                                    title: 'Belum Dialokasikan',
                                    subtitle:
                                        '${plan.unallocatedPercent.toStringAsFixed(0)}% dari pemasukan',
                                    percentage: plan.unallocatedPercent,
                                    amount: plan.unallocated,
                                    badgeBgColor: const Color(0xFFF1F5F9),
                                    badgeTextColor: const Color(0xFF64748B),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Kartu Batas Belanja Harian (Gradient Emerald)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF059669),
                                  Color(0xFF047857),
                                  Color(0xFF065F46),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF047857,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  AppAssets.ob3dDailyBudget,
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Batas Belanja Harian',
                                        style: textTheme.labelMedium?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        CurrencyFormatter.formatCompact(
                                          plan.safePerDay,
                                        ),
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Perkiraan budget belanja yang aman digunakan hari ini. (${plan.daysRemaining} hari tersisa)',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.82,
                                          ),
                                          fontSize: 11,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Kartu Target Dana Darurat
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.palette.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? context.palette.outlineVariant
                                    : const Color(0xFFF1F5F9),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.03,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  AppAssets.ob3dEmergencyTarget,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Target ${plan.goalName.isNotEmpty ? plan.goalName : "Dana Darurat"}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color:
                                              context.palette.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${CurrencyFormatter.formatCompact(displayGoalAmount)} / bulan',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: context.palette.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Kartu Komitmen Pengeluaran Rutin
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.palette.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? context.palette.outlineVariant
                                    : const Color(0xFFF1F5F9),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.03,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  AppAssets.ob3dRecurring,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Komitmen Pengeluaran Rutin',
                                        style: textTheme.bodySmall?.copyWith(
                                          color:
                                              context.palette.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${CurrencyFormatter.formatCompact(plan.recurringExpensesTotal)} / bulan',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Dicatat terpisah dari alokasi anggaran bulanan.',
                                        style: textTheme.bodySmall?.copyWith(
                                          color:
                                              context.palette.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: context.palette.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Informasi Tambahan
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: context.palette.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  AppStrings.planAdjustable,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: context.palette.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Fixed Bottom CTA Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: AppButton(
                      label: 'Mulai gunakan aplikasi →',
                      isLoading: _completing,
                      onPressed: _completing
                          ? null
                          : () async {
                              final router = GoRouter.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _completing = true);
                              try {
                                final salary = ref.read(
                                  salaryControllerProvider,
                                );
                                final saved = await ref
                                    .read(authControllerProvider.notifier)
                                    .updateFinancialInfo(
                                      monthlyIncome: salary.monthlyIncome > 0
                                          ? salary.monthlyIncome.toInt()
                                          : null,
                                      salaryDay: salary.salaryDay,
                                      isOnboarded: true,
                                    );
                                if (!saved) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(AppStrings.saveFailed),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                ref.invalidate(dashboardDataProvider);
                                ref.invalidate(accountsProvider);
                                ref.invalidate(profileUserProvider);
                                ref.invalidate(onboardingStatusProvider);
                                if (!mounted) return;
                                router.go(AppRoutes.dashboard);
                              } catch (_) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(AppStrings.saveFailed),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _completing = false);
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllocationItemRow extends StatelessWidget {
  const _AllocationItemRow({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.percentage,
    required this.amount,
    required this.badgeBgColor,
    required this.badgeTextColor,
  });

  final String assetPath;
  final String title;
  final String subtitle;
  final double percentage;
  final double amount;
  final Color badgeBgColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset(assetPath, width: 38, height: 38, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? badgeTextColor.withValues(alpha: 0.2)
                  : badgeBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
