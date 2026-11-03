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
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/api_financial_instrument.dart';
import '../../../../data/models/financial_instrument.dart';
import '../../../../data/providers/app_providers.dart';
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
class InstrumentsScreen extends ConsumerStatefulWidget {
  const InstrumentsScreen({super.key});

  @override
  ConsumerState<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends ConsumerState<InstrumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(instrumentsControllerProvider.notifier).loadExisting();
      }
    });
  }

  Future<void> _continue() async {
    final ok = await ref.read(instrumentsControllerProvider.notifier).save();
    if (ok && mounted) {
      context.push(AppRoutes.onboardingBudget);
    }
  }

  Future<void> _addInstrument() async {
    final instrument = await showDialog<FinancialInstrument>(
      context: context,
      builder: (context) => const _AddInstrumentDialog(),
    );
    if (instrument != null && mounted) {
      try {
        await ref
            .read(instrumentsControllerProvider.notifier)
            .addInstrument(instrument);
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.saveFailed)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            onPressed: _addInstrument,
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

InstrumentType _mapStringToInstrumentType(String? type) {
  switch (type?.toLowerCase()) {
    case 'bank':
      return InstrumentType.bank;
    case 'digitalbank':
    case 'digital bank':
      return InstrumentType.digitalBank;
    case 'ewallet':
    case 'e-wallet':
    case 'e wallet':
      return InstrumentType.ewallet;
    default:
      return InstrumentType.bank;
  }
}

/// Dialog tambah instrumen: pilih dari dropdown data master admin + saldo awal.
class _AddInstrumentDialog extends ConsumerStatefulWidget {
  const _AddInstrumentDialog();

  @override
  ConsumerState<_AddInstrumentDialog> createState() => _AddInstrumentDialogState();
}

class _AddInstrumentDialogState extends ConsumerState<_AddInstrumentDialog> {
  int? _selectedTypeId;
  final _balanceController = TextEditingController();
  final _feeController = TextEditingController();
  int _feeDay = 15;
  bool _attempted = false;
  bool _saving = false;

  @override
  void dispose() {
    _balanceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _save(List<ApiInstrumentType> types) {
    if (_saving) return;
    final balance = RupiahInputFormatter.parse(_balanceController.text);
    setState(() {
      _attempted = true;
    });

    if (_selectedTypeId == null || balance <= 0) return;

    final selectedType = types.firstWhere((t) => t.id == _selectedTypeId);
    final mappedType = _mapStringToInstrumentType(selectedType.type);
    final isBank = mappedType == InstrumentType.bank;

    setState(() => _saving = true);

    Navigator.of(context).pop(
      FinancialInstrument(
        id: 'inst-${DateTime.now().millisecondsSinceEpoch}',
        name: selectedType.name,
        type: mappedType,
        typeId: selectedType.id,
        initialBalance: balance,
        institutionName: selectedType.name,
        monthlyAdminFee:
            isBank ? RupiahInputFormatter.parse(_feeController.text) : 0,
        adminFeeDay: _feeDay,
        isSelected: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final typesAsync = ref.watch(instrumentTypesProvider);

    return AlertDialog(
      title: const Text(AppStrings.addInstrumentTitle),
      content: SingleChildScrollView(
        child: typesAsync.when(
          loading: () => const SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5),
                  SizedBox(height: 12),
                  Text('Memuat instrumen master...'),
                ],
              ),
            ),
          ),
          error: (err, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gagal memuat tipe instrumen: $err',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(instrumentTypesProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
          data: (types) {
            if (types.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  AppStrings.instrumentTypeEmpty,
                  style: textTheme.bodyMedium,
                ),
              );
            }

            final showTypeError = _attempted && _selectedTypeId == null;
            final balance = RupiahInputFormatter.parse(_balanceController.text);
            final showBalanceError = _attempted && balance <= 0;

            final selectedType = _selectedTypeId != null
                ? types.where((t) => t.id == _selectedTypeId).firstOrNull
                : null;
            final isBank = selectedType != null &&
                _mapStringToInstrumentType(selectedType.type) ==
                    InstrumentType.bank;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.instrumentType, style: textTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _selectedTypeId,
                  hint: const Text('Pilih instrumen...'),
                  items: types
                      .map((t) => DropdownMenuItem<int>(
                            value: t.id,
                            child: Text(t.name),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedTypeId = val);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                if (showTypeError) ...[
                  const SizedBox(height: 6),
                  _DialogError(text: AppStrings.instrumentTypeRequired),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  controller: _balanceController,
                  label: AppStrings.initialBalance,
                  hint: '0',
                  prefixText: 'Rp ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                ),
                if (showBalanceError) ...[
                  const SizedBox(height: 6),
                  _DialogError(text: AppStrings.balanceRequired),
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
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        typesAsync.maybeWhen(
          data: (types) => TextButton(
            onPressed:
                (_saving || types.isEmpty) ? null : () => _save(types),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.save),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
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
