import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_settings.dart';
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
    final confirmed = await showDialog<bool>(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
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
              backgroundColor: ok ? AppColors.success : AppColors.error,
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

    return showModalBottomSheet<_TransitionConfirmationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                      color: AppColors.fieldBorder,
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
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.primary,
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
                              color: AppColors.textSecondary,
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
                    color: AppColors.backgroundWarm,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.fieldBorder),
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
                              '${info.transitionDays} hari (${info.transitionStart} s.d. ${info.transitionEnd})',
                          valueColor: AppColors.warning,
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
                      color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nominal ini adalah batas belanja terencana selama ${info.transitionDays} hari masa transisi, BUKAN pemotongan atau penambahan saldo rekening bank Anda.',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF92400E),
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
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Histori budget periode saat ini dan saldo rekening Anda tetap aman dan tidak berubah.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
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
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Pengaturan Keuangan'),
        elevation: 0,
      ),
      body: SafeArea(
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

                        // Card 2: Pending Change (jika ada)
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
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
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
                  color: AppColors.primarySoft,
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
                        color: AppColors.textSecondary,
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_alt, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    'Masa Penyesuaian Anggaran (Transisi)',
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF92400E),
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
                  '${active.periodStart ?? '-'} s.d. ${active.periodEnd ?? '-'} (${active.daysRemaining} hari tersisa)',
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.shield_outlined,
              label: 'Batas Belanja Harian',
              value:
                  'Rp ${RupiahInputFormatter.format(active.safeDailySpending)} / hari',
              valueColor: AppColors.primary,
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
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule_outlined,
                  color: Color(0xFFD97706),
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
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    Text(
                      'Mulai berlaku: ${pending.effectiveDateFormatted ?? pending.effectiveDate}',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB45309),
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
                color: const Color(0xFF78350F),
              ),
            ),
          ],
          if (pending.pendingSalaryDay != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tanggal Gajian Baru: Tanggal ${pending.pendingSalaryDay}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF78350F),
              ),
            ),
          ],
          if (pending.transitionBudget != null) ...[
            const SizedBox(height: 4),
            Text(
              'Batas Anggaran Transisi: ${pending.transitionBudgetFormatted ?? 'Rp ${RupiahInputFormatter.format(pending.transitionBudget!)}'}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF78350F),
              ),
            ),
          ],
          if (pending.transitionInfo != null &&
              pending.transitionInfo!.hasTransition) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                pending.transitionInfo!.note,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF92400E),
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Batalkan Perubahan'),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
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
                color: AppColors.textSecondary,
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.fieldFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedSalaryDay,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  items: List.generate(31, (index) {
                    final day = index + 1;
                    return DropdownMenuItem<int>(
                      value: day,
                      child: Text(
                        'Tanggal $day',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
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
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Perubahan ini tidak membuat transaksi pemasukan baru dan tidak memodifikasi saldo rekening Anda. Rencana baru aktif otomatis pada periode berikutnya.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
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
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
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
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

