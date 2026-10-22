import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_instrument.dart';
import '../providers/instruments_controller.dart';

/// Visual per tipe instrumen: aset 3D lokal + fallback outline + tint.
/// Bank: kartu bank generik (tanpa logo resmi). Bank Digital: panah
/// transfer. E-Wallet: dompet. Semua terverifikasi visual di disk.
({String asset, IconData icon, Color foreground, Color background})
    _visualOf(
  InstrumentType type,
) {
  switch (type) {
    case InstrumentType.bank:
      return (
        asset: AppAssets.obBank,
        icon: Icons.account_balance_outlined,
        foreground: AppColors.secondary,
        background: AppColors.secondarySoft,
      );
    case InstrumentType.digitalBank:
      return (
        asset: AppAssets.obDigitalBank,
        icon: Icons.smartphone_outlined,
        foreground: AppColors.primary,
        background: AppColors.primarySoft,
      );
    case InstrumentType.ewallet:
      return (
        asset: AppAssets.obEWallet,
        icon: Icons.account_balance_wallet_outlined,
        foreground: const Color(0xFF8B5CF6),
        background: const Color(0xFFEEE9FE),
      );
  }
}

String _typeLabel(InstrumentType type) {
  switch (type) {
    case InstrumentType.bank:
      return AppStrings.typeBank;
    case InstrumentType.digitalBank:
      return AppStrings.typeDigitalBank;
    case InstrumentType.ewallet:
      return AppStrings.typeEWallet;
  }
}

/// No.4 — Pilih Instrumen Keuangan: daftar, pilih, tambah, detail fee.
/// Sukses simpan -> No.5 (/onboarding/recurring-expenses).
class InstrumentsScreen extends ConsumerWidget {
  const InstrumentsScreen({super.key});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(instrumentsControllerProvider.notifier).save();
    if (ok && context.mounted) {
      context.push(AppRoutes.onboardingExpenses);
    }
  }

  Future<void> _addInstrument(BuildContext context, WidgetRef ref) async {
    final instrument = await showDialog<FinancialInstrument>(
      context: context,
      builder: (context) => const _AddInstrumentDialog(),
    );
    if (instrument != null) {
      ref.read(instrumentsControllerProvider.notifier).addInstrument(
            instrument,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instrumentsControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final focused = state.focusedBank;

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
                              AppStrings.onboardingStep2,
                              style: textTheme.labelSmall,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  value: 0.5,
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
                          AppStrings.instrumentsTitle,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.instrumentsSubtitle,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        for (final instrument in state.instruments) ...[
                          _InstrumentCard(
                            instrument: instrument,
                            onTap: () => ref
                                .read(instrumentsControllerProvider.notifier)
                                .toggleSelect(instrument.id),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _addInstrument(context, ref),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(AppStrings.addInstrument),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        if (state.selected.isEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.noInstrumentError,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        if (focused != null) ...[
                          const SizedBox(height: 12),
                          _InstrumentDetail(key: ValueKey(focused.id)),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.continueButton,
                    isLoading: state.isSaving,
                    onPressed:
                        state.canContinue ? () => _continue(context, ref) : null,
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

/// Card instrumen: terpilih = border emerald + check, sisanya chevron.
class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard({required this.instrument, required this.onTap});

  final FinancialInstrument instrument;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final visual = _visualOf(instrument.type);
    final selected = instrument.isSelected;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              visual.asset,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(visual.icon, color: visual.foreground, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(instrument.name, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${_typeLabel(instrument.type)} • ${AppStrings.initialBalance}',
                    style: textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatCompact(
                      instrument.initialBalance,
                    ),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
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

/// Panel detail fee milik bank terpilih. Key = id agar controller
/// di-reset saat fokus berpindah instrumen.
class _InstrumentDetail extends ConsumerStatefulWidget {
  const _InstrumentDetail({super.key});

  @override
  ConsumerState<_InstrumentDetail> createState() => _InstrumentDetailState();
}

class _InstrumentDetailState extends ConsumerState<_InstrumentDetail> {
  late final TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    final focused =
        ref.read(instrumentsControllerProvider).focusedBank!;
    _feeController = TextEditingController(
      text: focused.monthlyAdminFee > 0
          ? RupiahInputFormatter.format(focused.monthlyAdminFee)
          : '',
    );
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = ref.watch(instrumentsControllerProvider).focusedBank;
    if (focused == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final notifier = ref.read(instrumentsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.instrumentDetail} — ${focused.name}',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _feeController,
          label: AppStrings.adminFee,
          hint: '0',
          prefixText: 'Rp ',
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahInputFormatter()],
          onChanged: (v) => notifier.updateAdminFee(
            focused.id,
            RupiahInputFormatter.parse(v),
          ),
        ),
        const SizedBox(height: 12),
        Text(AppStrings.feeDay, style: textTheme.labelLarge),
        const SizedBox(height: 8),
        _FeeDayDropdown(
          value: focused.adminFeeDay,
          onChanged: (day) => notifier.updateAdminFeeDay(focused.id, day),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppStrings.feeHelper,
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dropdown tanggal 1–31 dengan suffix "setiap bulan".
class _FeeDayDropdown extends StatelessWidget {
  const _FeeDayDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      items: [
        for (var day = 1; day <= 31; day++)
          DropdownMenuItem(value: day, child: Text('$day')),
      ],
      selectedItemBuilder: (context) => [
        for (var day = 1; day <= 31; day++)
          Text('$day ${AppStrings.feeDaySuffix}'),
      ],
      onChanged: (day) {
        if (day != null) onChanged(day);
      },
    );
  }
}

/// Dialog tambah instrumen: tipe, nama, saldo, (+ fee & tanggal utk Bank).
class _AddInstrumentDialog extends StatefulWidget {
  const _AddInstrumentDialog();

  @override
  State<_AddInstrumentDialog> createState() => _AddInstrumentDialogState();
}

class _AddInstrumentDialogState extends State<_AddInstrumentDialog> {
  InstrumentType _type = InstrumentType.bank;
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _feeController = TextEditingController();
  int _feeDay = 15;
  String? _nameError;
  String? _balanceError;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final balance = RupiahInputFormatter.parse(_balanceController.text);
    setState(() {
      _nameError =
          name.isEmpty ? AppStrings.instrumentNameRequired : null;
      _balanceError =
          balance <= 0 ? AppStrings.balanceRequired : null;
    });
    if (_nameError != null || _balanceError != null) return;

    Navigator.of(context).pop(
      FinancialInstrument(
        id: 'inst-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: _type,
        initialBalance: balance,
        monthlyAdminFee: _type == InstrumentType.bank
            ? RupiahInputFormatter.parse(_feeController.text)
            : 0,
        adminFeeDay: _feeDay,
        isSelected: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isBank = _type == InstrumentType.bank;

    return AlertDialog(
      title: const Text(AppStrings.addInstrumentTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.instrumentType, style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in InstrumentType.values)
                  _TypeChip(
                    label: _typeLabel(type),
                    selected: _type == type,
                    onTap: () => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _nameController,
              label: AppStrings.instrumentName,
              hint: AppStrings.instrumentNameHint,
            ),
            if (_nameError != null) ...[
              const SizedBox(height: 6),
              _DialogError(text: _nameError!),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _balanceController,
              label: AppStrings.initialBalance,
              hint: '0',
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
            ),
            if (_balanceError != null) ...[
              const SizedBox(height: 6),
              _DialogError(text: _balanceError!),
            ],
            if (isBank) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _feeController,
                label: AppStrings.adminFee,
                hint: '0',
                prefixText: 'Rp ',
                keyboardType: TextInputType.number,
                inputFormatters: [RupiahInputFormatter()],
              ),
              const SizedBox(height: 12),
              Text(AppStrings.feeDay, style: textTheme.labelLarge),
              const SizedBox(height: 8),
              _FeeDayDropdown(
                value: _feeDay,
                onChanged: (day) => setState(() => _feeDay = day),
              ),
            ],
          ],
        ),
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
    );
  }
}
