import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/salary_controller.dart';

/// Pilihan hari gajian cepat.
const List<int> _quickDays = [1, 25, 28];

/// No.3 — Input Gaji Bulanan: nominal pemasukan + tanggal gajian.
/// Sukses simpan -> No.4 (/onboarding/instruments).
class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  late final TextEditingController _incomeController;
  bool _incomeTouched = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(salaryControllerProvider).monthlyIncome;
    _incomeController = TextEditingController(
      text: initial > 0 ? RupiahInputFormatter.format(initial) : '',
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final ok = await ref.read(salaryControllerProvider.notifier).save();
    if (ok && mounted) context.push(AppRoutes.onboardingInstruments);
  }

  Future<void> _pickCustomDay(int current) async {
    final day = await showDialog<int>(
      context: context,
      builder: (context) => _CustomDayDialog(initialDay: current),
    );
    if (day != null) {
      ref.read(salaryControllerProvider.notifier).setSalaryDay(day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salaryControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final showIncomeError = _incomeTouched && !state.isIncomeValid;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppStrings.onboardingStep,
                              style: textTheme.labelSmall,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  value: 0.25,
                                  minHeight: 8,
                                  backgroundColor: AppColors.primarySoft,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppStrings.salaryTitle,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.salarySubtitle,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Image.asset(
                            AppAssets.incomeSetupIllustration,
                            height: 170,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.smartphone_outlined,
                              size: 120,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              AppAssets.obSalaryWallet,
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const SizedBox(width: 30, height: 30),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.salaryIncomeQuestion,
                                style: textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _incomeController,
                          hint: '0',
                          prefixText: 'Rp ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [RupiahInputFormatter()],
                          onChanged: (v) {
                            ref
                                .read(salaryControllerProvider.notifier)
                                .setIncome(RupiahInputFormatter.parse(v));
                            if (!_incomeTouched) {
                              setState(() => _incomeTouched = true);
                            }
                          },
                        ),
                        if (showIncomeError) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.incomeRequired,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.salaryDayQuestion,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final day in _quickDays)
                              _DayChip(
                                label: '$day',
                                selected: state.salaryDay == day,
                                onTap: () => ref
                                    .read(salaryControllerProvider.notifier)
                                    .setSalaryDay(day),
                              ),
                            _DayChip(
                              label: _quickDays.contains(state.salaryDay)
                                  ? AppStrings.salaryCustomDay
                                  : '${state.salaryDay}',
                              selected:
                                  !_quickDays.contains(state.salaryDay),
                              onTap: () => _pickCustomDay(state.salaryDay),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.salaryHelper,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.continueButton,
                    isLoading: state.isSaving,
                    onPressed: state.canContinue ? _continue : null,
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

/// Chip hari: terpilih = emerald filled, sisanya outline.
class _DayChip extends StatelessWidget {
  const _DayChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}

/// Dialog tanggal custom 1–31: sederhana, tanpa calendar system.
class _CustomDayDialog extends StatefulWidget {
  const _CustomDayDialog({required this.initialDay});

  final int initialDay;

  @override
  State<_CustomDayDialog> createState() => _CustomDayDialogState();
}

class _CustomDayDialogState extends State<_CustomDayDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _quickDays.contains(widget.initialDay)
          ? ''
          : '${widget.initialDay}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final day = int.tryParse(_controller.text.trim());
    if (day == null || day < 1 || day > 31) {
      setState(() => _error = AppStrings.customDayInvalid);
      return;
    }
    Navigator.of(context).pop(day);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.salaryCustomDayTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _controller,
            hint: AppStrings.salaryCustomDayHint,
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: _save,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
