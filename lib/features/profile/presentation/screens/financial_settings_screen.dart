import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    hide GlassQuality;

import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/utils/scheduled_cashflow_calculator.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/api_recurring_transaction.dart';
import '../../../../data/models/financial_settings.dart';
import '../../../recurring/presentation/providers/recurring_controller.dart';
import '../providers/financial_settings_controller.dart';

class _TransitionConfirmationResult {
  const _TransitionConfirmationResult({
    required this.confirmed,
    this.transitionBudget,
  });

  final bool confirmed;
  final int? transitionBudget;
}

class FinancialSettingsScreen extends ConsumerStatefulWidget {
  const FinancialSettingsScreen({super.key});

  @override
  ConsumerState<FinancialSettingsScreen> createState() =>
      _FinancialSettingsScreenState();
}

class _FinancialSettingsScreenState
    extends ConsumerState<FinancialSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  int _selectedSalaryDay = 25;
  bool _initialized = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _initFormValues(FinancialSettings data) {
    if (_initialized) return;
    _initialized = true;
    _selectedSalaryDay = data.currentSalaryDay;
    if (data.currentMonthlyIncome > 0) {
      _incomeController.text =
          RupiahInputFormatter.format(data.currentMonthlyIncome);
    }
  }

  Future<void> _handlePreviewAndSubmit(FinancialSettings currentData) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final income = RupiahInputFormatter.parse(_incomeController.text).toInt();
    if (income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penghasilan bulanan harus lebih dari Rp 0'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final transitionInfo = await ref
          .read(financialSettingsControllerProvider.notifier)
          .preview(
            monthlyIncome: income,
            salaryDay: _selectedSalaryDay,
          );

      if (!mounted) return;

      final result = await _showPreviewSheet(context, transitionInfo);
      if (result != null && result.confirmed && mounted) {
        final success = await ref
            .read(financialSettingsControllerProvider.notifier)
            .saveSettings(
              monthlyIncome: income,
              salaryDay: _selectedSalaryDay,
              transitionBudget: result.transitionBudget,
              transitionConfirmed: true,
            );

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Perubahan rencana keuangan berhasil dijadwalkan untuk periode berikutnya!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan perubahan rencana keuangan.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleCancelPending() async {
    final confirmed = GlassDesignTokens.isDarkGlass(context)
        ? await GlassDialog.show<bool>(
            context: context,
            title: 'Batalkan Perubahan Jadwal?',
            message:
                'Perubahan gaji atau tanggal gajian yang tertunda akan dibatalkan. Konfigurasi anggaran periode berjalan tetap dipertahankan.',
            settings: GlassDesignTokens.darkOverlaySettings(context),
            actions: [
              GlassDialogAction(
                label: 'Batal',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              GlassDialogAction(
                label: 'Ya, Batalkan',
                isDestructive: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          )
        : await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Batalkan Perubahan Jadwal?'),
              content: const Text(
                'Perubahan gaji atau tanggal gajian yang tertunda akan dibatalkan. Konfigurasi anggaran periode berjalan tetap dipertahankan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: destructiveButtonStyle(context),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Ya, Batalkan'),
                ),
              ],
            ),
          );

    if (confirmed == true && mounted) {
      setState(() => _isSubmitting = true);
      try {
        final ok = await ref
            .read(financialSettingsControllerProvider.notifier)
            .cancelPending();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? 'Perubahan jadwal berhasil dibatalkan.'
                    : 'Gagal membatalkan jadwal perubahan.',
              ),
              backgroundColor: ok ? context.palette.primary : context.palette.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Future<_TransitionConfirmationResult?> _showPreviewSheet(
    BuildContext context,
    FinancialTransitionInfo info,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final transitionController = TextEditingController(
      text: info.hasTransition
          ? RupiahInputFormatter.format(
              info.suggestedTransitionBudget > 0
                  ? info.suggestedTransitionBudget
                  : 0,
            )
          : '',
    );

    return showGlassSheet<_TransitionConfirmationResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.palette.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.palette.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: context.palette.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Simulasi Siklus Budget Baru',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Berlaku mulai periode berikutnya',
                            style: textTheme.bodySmall?.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.canvasColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.palette.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      _PreviewRow(
                        label: 'Gaji Baru',
                        value:
                            'Rp ${RupiahInputFormatter.format(info.proposedMonthlyIncome)}',
                        highlight: true,
                      ),
                      const Divider(height: 16),
                      _PreviewRow(
                        label: 'Tanggal Gajian Baru',
                        value: 'Tanggal ${info.proposedSalaryDay}',
                      ),
                      const Divider(height: 16),
                      _PreviewRow(
                        label: 'Mulai Berlaku',
                        value: info.effectiveDateFormatted,
                      ),
                      if (info.hasTransition) ...[
                        const Divider(height: 16),
                        _PreviewRow(
                          label: 'Masa Penyesuaian',
                          value:
                              '${info.transitionDays} hari (${DateFormatter.formatIsoRange(info.transitionStart, info.transitionEnd)})',
                          valueColor: context.warningInk,
                        ),
                        const Divider(height: 16),
                        _PreviewRow(
                          label: 'Siklus Penuh Baru',
                          value: info.nextFullPeriodStartFormatted,
                        ),
                      ],
                    ],
                  ),
                ),
                if (info.hasTransition) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Batas Anggaran Masa Transisi (${info.transitionDays} Hari)',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.palette.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: transitionController,
                    prefixText: 'Rp ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    hint: 'Masukkan anggaran transisi',
                  ),
                  if (info.suggestedTransitionBudget > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Saran pro-rata: Rp ${RupiahInputFormatter.format(info.suggestedTransitionBudget)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.warningFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.warningFill),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.warningInk,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nominal ini adalah batas belanja terencana selama ${info.transitionDays} hari masa transisi, BUKAN pemotongan atau penambahan saldo rekening bank Anda.',
                            style: textTheme.bodySmall?.copyWith(
                              color: context.warningInk,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.palette.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.palette.primaryContainer),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: context.palette.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Histori budget periode saat ini dan saldo rekening Anda tetap aman dan tidak berubah.',
                          style: textTheme.bodySmall?.copyWith(
                            color: context.palette.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Konfirmasi & Jadwalkan',
                  onPressed: () {
                    int? parsedBudget;
                    if (info.hasTransition) {
                      parsedBudget = RupiahInputFormatter.parse(transitionController.text).toInt();
                      if (parsedBudget < 0) parsedBudget = 0;
                    }
                    Navigator.of(ctx).pop(
                      _TransitionConfirmationResult(
                        confirmed: true,
                        transitionBudget: parsedBudget,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppOutlineButton(
                  label: 'Batal',
                  onPressed: () => Navigator.of(ctx).pop(
                    const _TransitionConfirmationResult(confirmed: false),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(financialSettingsControllerProvider);

    return Scaffold(
      backgroundColor: context.canvasColor,
      extendBodyBehindAppBar: GlassDesignTokens.isDarkGlass(context),
      appBar: const AppAdaptiveAppBar(
        leading: AppBackButton(),
        title: Text('Rencana Keuangan'),
      ),
      body: GlassBackdrop(child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: settingsAsync.when(
              data: (data) {
                _initFormValues(data);
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(financialSettingsControllerProvider.notifier)
                      .refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card 1: Status Aktif Saat Ini
                        _CurrentStatusCard(data: data),
                        const SizedBox(height: 16),

                        // Card 2: Ringkasan Arus Kas Terjadwal (Pemasukan & Pengeluaran Rutin)
                        _ScheduledCashflowCard(activePeriod: data.activePeriod),
                        const SizedBox(height: 16),

                        // Card 3: Pending Change (jika ada)
                        if (data.hasPendingChange) ...[
                          _PendingBannerCard(
                            pending: data.pendingChange!,
                            onCancel: _isSubmitting ? null : _handleCancelPending,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Card 3: Form Perubahan Rencana
                        _ChangeScheduleCard(
                          formKey: _formKey,
                          incomeController: _incomeController,
                          selectedSalaryDay: _selectedSalaryDay,
                          onSalaryDayChanged: (day) {
                            if (day != null) {
                              setState(() => _selectedSalaryDay = day);
                            }
                          },
                          isSubmitting: _isSubmitting,
                          onSubmit: () => _handlePreviewAndSubmit(data),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const AppLoading(),
              error: (err, _) => AppErrorState(
                message: 'Gagal memuat pengaturan keuangan: $err',
                onRetry: () => ref
                    .read(financialSettingsControllerProvider.notifier)
                    .refresh(),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _ScheduledCashflowCard extends ConsumerWidget {
  const _ScheduledCashflowCard({this.activePeriod});

  final ActivePeriodInfo? activePeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final incomesAsync = ref.watch(recurringIncomesProvider);
    final expensesAsync = ref.watch(recurringExpensesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.palette.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sync_alt_outlined,
                  size: 20,
                  color: context.palette.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Arus Kas Terjadwal',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Pemasukan & pengeluaran berkala aktif periode ini',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Handling Status Loading & Error tanpa menampilkan angka 0 menyesatkan
          if (incomesAsync.isLoading || expensesAsync.isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.palette.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Menghitung arus kas terjadwal...',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (incomesAsync.hasError || expensesAsync.hasError) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.palette.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.palette.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: context.palette.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gagal memuat ringkasan transaksi rutin',
                        style: textTheme.bodySmall?.copyWith(color: context.palette.error),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        ref.invalidate(recurringIncomesProvider);
                        ref.invalidate(recurringExpensesProvider);
                      },
                      child: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildCalculatedCashflowContent(
              context,
              ref,
              textTheme,
              incomes: incomesAsync.value ?? [],
              expenses: expensesAsync.value ?? [],
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppAdaptiveOutlinedButton(
                  height: 36,
                  borderRadius: 18,
                  icon: const Icon(Icons.arrow_upward, size: 14),
                  label: 'Pemasukan Rutin',
                  onPressed: () => context.push(AppRoutes.recurringIncomes),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppAdaptiveOutlinedButton(
                  height: 36,
                  borderRadius: 18,
                  icon: const Icon(Icons.arrow_downward, size: 14),
                  label: 'Pengeluaran Rutin',
                  onPressed: () => context.push(AppRoutes.recurringExpenses),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatedCashflowContent(
    BuildContext context,
    WidgetRef ref,
    TextTheme textTheme, {
    required List<ApiRecurringTransaction> incomes,
    required List<ApiRecurringTransaction> expenses,
  }) {
    DateTime? pStart;
    DateTime? pEnd;

    if (activePeriod?.periodStart != null) {
      pStart = DateTime.tryParse(activePeriod!.periodStart!);
    }
    if (activePeriod?.periodEnd != null) {
      pEnd = DateTime.tryParse(activePeriod!.periodEnd!);
    }

    final summary = ScheduledCashflowCalculator.calculateSummary(
      incomes: incomes,
      expenses: expenses,
      periodStart: pStart,
      periodEnd: pEnd,
    );

    final netCashflow = summary.netCashflow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.palette.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemasukan Rutin',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${RupiahInputFormatter.format(summary.income.totalAmount)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.palette.primary,
                      ),
                    ),
                    Text(
                      '${summary.income.activeCount} jadwal (${summary.income.totalOccurrences}x periode ini)',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.palette.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengeluaran Rutin',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp ${RupiahInputFormatter.format(summary.expense.totalAmount)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.palette.error,
                      ),
                    ),
                    Text(
                      '${summary.expense.activeCount} jadwal (${summary.expense.totalOccurrences}x periode ini)',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Arus Kas Terjadwal Bersih:',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.palette.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${netCashflow >= 0 ? '+' : '-'} Rp ${RupiahInputFormatter.format(netCashflow.abs())}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: netCashflow >= 0 ? context.palette.primary : context.palette.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Dihitung berdasarkan frekuensi jadwal pada periode budget aktif. Tidak mengubah saldo sebelum transaksi dieksekusi.',
          style: textTheme.bodySmall?.copyWith(
            fontSize: 10.5,
            color: context.palette.onSurfaceVariant.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({required this.data});

  final FinancialSettings data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = data.activePeriod;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.palette.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const AppImageIcon(
                  assetPath: AppAssets.ntfBudget,
                  size: 20,
                  fallbackIcon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rencana Keuangan Aktif',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Dasar perhitungan anggaran periode ini',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (active != null && active.isTransition) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.warningFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.warningFill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_alt, size: 14, color: context.warningInk),
                  const SizedBox(width: 6),
                  Text(
                    'Masa Penyesuaian Anggaran (Transisi)',
                    style: textTheme.bodySmall?.copyWith(
                      color: context.warningInk,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Penghasilan Terencana',
            value: data.currentMonthlyIncomeFormatted ??
                'Rp ${RupiahInputFormatter.format(data.currentMonthlyIncome)}',
            valueBold: true,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.event_outlined,
            label: 'Tanggal Gajian',
            value: 'Tanggal ${data.currentSalaryDay} setiap bulan',
          ),
          if (active != null) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.date_range_outlined,
              label: 'Periode Budget',
              value:
                  '${DateFormatter.formatIsoRange(active.periodStart, active.periodEnd)} (${active.daysRemaining} hari tersisa)',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.shield_outlined,
              label: 'Batas Belanja Harian',
              value:
                  'Rp ${RupiahInputFormatter.format(active.safeDailySpending)} / hari',
              valueColor: context.palette.primary,
              valueBold: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingBannerCard extends StatelessWidget {
  const _PendingBannerCard({
    required this.pending,
    required this.onCancel,
  });

  final PendingFinancialChange pending;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.warningFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.warningFill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.warningFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.schedule_outlined,
                  color: context.warningInk,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perubahan Terjadwal',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: context.warningInk,
                      ),
                    ),
                    Text(
                      'Mulai berlaku: ${DateFormatter.formatIsoDate(pending.effectiveDate)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.warningInk,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (pending.pendingMonthlyIncome != null) ...[
            Text(
              'Gaji Baru: ${pending.pendingMonthlyIncomeFormatted ?? 'Rp ${RupiahInputFormatter.format(pending.pendingMonthlyIncome!)}'}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.warningInk,
              ),
            ),
          ],
          if (pending.pendingSalaryDay != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tanggal Gajian Baru: Tanggal ${pending.pendingSalaryDay}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.warningInk,
              ),
            ),
          ],
          if (pending.transitionBudget != null) ...[
            const SizedBox(height: 4),
            Text(
              'Batas Anggaran Transisi: ${pending.transitionBudgetFormatted ?? 'Rp ${RupiahInputFormatter.format(pending.transitionBudget!)}'}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.warningInk,
              ),
            ),
          ],
          if (pending.transitionInfo != null &&
              pending.transitionInfo!.hasTransition) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.palette.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.warningFill),
              ),
              child: Text(
                pending.transitionInfo!.note,
                style: textTheme.bodySmall?.copyWith(
                  color: context.warningInk,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AppAdaptiveOutlinedButton(
              height: 40,
              borderRadius: 12,
              foregroundColor: context.palette.error,
              borderColor: context.palette.error,
              tintColor: context.palette.error.withValues(alpha: 0.14),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: 'Batalkan Perubahan',
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeScheduleCard extends StatelessWidget {
  const _ChangeScheduleCard({
    required this.formKey,
    required this.incomeController,
    required this.selectedSalaryDay,
    required this.onSalaryDayChanged,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController incomeController;
  final int selectedSalaryDay;
  final ValueChanged<int?> onSalaryDayChanged;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Perbarui Rencana Keuangan',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Atur penghasilan bulanan terencana dan tanggal gajian untuk siklus periode berikutnya.',
              style: textTheme.bodySmall?.copyWith(
                color: context.palette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: incomeController,
              label: 'Penghasilan Bulanan Baru',
              hint: '5.000.000',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Penghasilan bulanan wajib diisi';
                }
                if (RupiahInputFormatter.parse(v) <= 0) {
                  return 'Nominal penghasilan harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Tanggal Gajian Baru',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.palette.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            if (GlassDesignTokens.isDarkGlass(context))
              AppAdaptiveDropdown<int>(
                value: selectedSalaryDay,
                isExpanded: true,
                items: List.generate(31, (index) {
                  final day = index + 1;
                  return DropdownMenuItem<int>(
                    value: day,
                    child: Text('Tanggal $day'),
                  );
                }),
                onChanged: onSalaryDayChanged,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.palette.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedSalaryDay,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: context.palette.onSurfaceVariant),
                    items: List.generate(31, (index) {
                      final day = index + 1;
                      return DropdownMenuItem<int>(
                        value: day,
                        child: Text(
                          'Tanggal $day',
                          style: textTheme.bodyMedium?.copyWith(
                            color: context.palette.onSurface,
                          ),
                        ),
                      );
                    }),
                    onChanged: onSalaryDayChanged,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.canvasColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.palette.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: context.palette.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Perubahan ini tidak membuat transaksi pemasukan baru dan tidak memodifikasi saldo rekening Anda. Rencana baru aktif otomatis pada periode berikutnya.',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Simulasi & Simpan Jadwal',
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.palette.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: context.palette.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? context.palette.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: context.palette.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? context.palette.onSurface,
          ),
        ),
      ],
    );
  }
}

