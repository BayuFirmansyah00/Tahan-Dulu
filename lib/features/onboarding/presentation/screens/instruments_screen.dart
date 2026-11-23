import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/api_bank.dart';
import '../../../../data/models/api_financial_instrument.dart';
import '../../../../data/models/financial_instrument.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../accounts/presentation/widgets/admin_fee_form_section.dart';
import '../../../accounts/presentation/widgets/bank_logo_badge.dart';
import '../../../accounts/presentation/widgets/bank_picker_sheet.dart';
import '../providers/instruments_controller.dart';

/// Visual per tipe instrumen: aset 3D lokal + fallback outline + tint.
/// Bank: kartu bank generik (tanpa logo resmi). Bank Digital: panah
/// transfer. E-Wallet: dompet. Uang Tunai: kas fisik.
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
    case InstrumentType.cash:
      return (
        asset: AppAssets.instCash,
        icon: Icons.payments_outlined,
        foreground: const Color(0xFF10B981),
        background: const Color(0xFFD1FAE5),
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
    case InstrumentType.cash:
      return AppStrings.typeCash;
  }
}

/// Tahap 2 — Pilih instrumen keuangan: daftar, pilih, tambah, detail fee.
/// Sukses simpan -> tahap 3 (/onboarding/budget).
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

  void _skip() {
    context.push(AppRoutes.onboardingBudget);
  }

  Future<void> _addInstrument() async {
    final instrument = await showGlassSheet<FinancialInstrument>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddInstrumentSheet(),
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
      body: GlassBackdrop(child: SafeArea(
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
                                child: LinearProgressIndicator(
                                  value: 0.5,
                                  minHeight: 8,
                                  backgroundColor: context.palette.primaryContainer,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.palette.primary,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.selected.isNotEmpty) ...[
                        AppButton(
                          label: AppStrings.continueButton,
                          isLoading: state.isSaving,
                          onPressed: state.canContinue ? _continue : null,
                        ),
                        const SizedBox(height: 12),
                        AppOutlineButton(
                          label: AppStrings.setupLater,
                          onPressed: state.isSaving ? null : _skip,
                        ),
                      ] else ...[
                        AppButton(
                          label: AppStrings.setupLater,
                          onPressed: state.isSaving ? null : _skip,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
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
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? context.palette.primary : context.palette.outlineVariant,
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
                  if (instrument.type == InstrumentType.bank ||
                      instrument.type == InstrumentType.digitalBank) ...[
                    const SizedBox(height: 2),
                    Text(
                      instrument.adminFeeEnabled && instrument.monthlyAdminFee > 0
                          ? 'Biaya admin: ${CurrencyFormatter.formatCompact(instrument.monthlyAdminFee)}/bln (tgl ${instrument.adminFeeDay})'
                          : 'Bebas biaya admin',
                      style: textTheme.bodySmall?.copyWith(
                        color: instrument.adminFeeEnabled && instrument.monthlyAdminFee > 0
                            ? context.palette.primary
                            : context.palette.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.palette.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Icon(
                Icons.chevron_right,
                color: context.palette.onSurfaceVariant,
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

    final isBankOrDigital = focused.type == InstrumentType.bank ||
        focused.type == InstrumentType.digitalBank;
    if (!isBankOrDigital) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.instrumentDetail} — ${focused.name}',
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        AdminFeeFormSection(
          enabled: focused.adminFeeEnabled,
          onEnabledChanged: (val) {
            notifier.updateAdminFeeEnabled(focused.id, val);
          },
          feeController: _feeController,
          feeDay: focused.adminFeeDay,
          onDayChanged: (day) => notifier.updateAdminFeeDay(focused.id, day),
        ),
      ],
    );
  }
}

/// Modal bottom sheet untuk menambah instrumen keuangan onboarding.
/// Alur modern 2 tahap:
/// 1. Pilih kategori: Bank, Bank Digital, E-Wallet, Uang Tunai.
/// 2. Lengkapi detail: pilih provider resmi (untuk Bank/E-Wallet) dan saldo awal.
class _AddInstrumentSheet extends ConsumerStatefulWidget {
  const _AddInstrumentSheet();

  @override
  ConsumerState<_AddInstrumentSheet> createState() => _AddInstrumentSheetState();
}

class _AddInstrumentSheetState extends ConsumerState<_AddInstrumentSheet> {
  InstrumentType? _selectedCategory;
  ApiBank? _selectedBank;
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _feeController = TextEditingController();
  int _feeDay = 15;
  bool _feeEnabled = false;
  bool _attempted = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _selectCategory(InstrumentType category) async {
    final categoryFilter = category == InstrumentType.bank
        ? 'bank'
        : category == InstrumentType.digitalBank
            ? 'digitalBank'
            : 'ewallet';

    final title = category == InstrumentType.bank
        ? 'Pilih Bank'
        : category == InstrumentType.digitalBank
            ? 'Pilih Bank Digital'
            : 'Pilih E-Wallet';

    final subtitle = category == InstrumentType.bank
        ? 'BCA, Mandiri, BRI, BNI, BSI, CIMB Niaga, dll.'
        : category == InstrumentType.digitalBank
            ? 'Bank Jago, Jenius, SeaBank, Blu, Neobank, dll.'
            : 'GoPay, OVO, DANA, ShopeePay, LinkAja, AstraPay, dll.';

    final bank = await BankPickerSheet.show(
      context,
      categoryFilter: categoryFilter,
      title: title,
      subtitle: subtitle,
    );

    if (bank != null && mounted) {
      setState(() {
        _selectedCategory = category;
        _selectedBank = bank;
        _nameController.text = bank.name;
        _balanceController.clear();
      });
    }
  }

  Future<void> _changeProvider() async {
    if (_selectedCategory == null) return;

    final categoryFilter = _selectedCategory == InstrumentType.bank
        ? 'bank'
        : _selectedCategory == InstrumentType.digitalBank
            ? 'digitalBank'
            : 'ewallet';

    final title = _selectedCategory == InstrumentType.bank
        ? 'Pilih Bank'
        : _selectedCategory == InstrumentType.digitalBank
            ? 'Pilih Bank Digital'
            : 'Pilih E-Wallet';

    final subtitle = _selectedCategory == InstrumentType.bank
        ? 'BCA, Mandiri, BRI, BNI, BSI, CIMB Niaga, dll.'
        : _selectedCategory == InstrumentType.digitalBank
            ? 'Bank Jago, Jenius, SeaBank, Blu, Neobank, dll.'
            : 'GoPay, OVO, DANA, ShopeePay, LinkAja, AstraPay, dll.';

    final bank = await BankPickerSheet.show(
      context,
      selectedBankId: _selectedBank?.id,
      selectedBankSlug: _selectedBank?.slug,
      categoryFilter: categoryFilter,
      title: title,
      subtitle: subtitle,
    );

    if (bank != null && mounted) {
      setState(() {
        _selectedBank = bank;
        _nameController.text = bank.name;
      });
    }
  }

  int _resolveTypeId(InstrumentType category, List<ApiInstrumentType>? types) {
    if (types != null && types.isNotEmpty) {
      for (final t in types) {
        final slug = t.type.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
        if (category == InstrumentType.bank && (slug == 'bank' || slug == 'bankkonvensional')) return t.id;
        if (category == InstrumentType.digitalBank && (slug == 'digitalbank' || slug == 'bankdigital')) return t.id;
        if (category == InstrumentType.ewallet && (slug == 'ewallet' || slug == 'dompetdigital')) return t.id;
        if (category == InstrumentType.cash && (slug == 'cash' || slug == 'uangtunai' || slug == 'tunai')) return t.id;
      }
    }
    switch (category) {
      case InstrumentType.bank:
        return 1;
      case InstrumentType.digitalBank:
        return 2;
      case InstrumentType.ewallet:
        return 3;
      case InstrumentType.cash:
        return 4;
    }
  }

  void _save(List<ApiInstrumentType>? types) {
    if (_saving) return;
    setState(() => _attempted = true);

    if (_selectedCategory == null) return;
    final isCash = _selectedCategory == InstrumentType.cash;
    if (!isCash && _selectedBank == null) return;

    final balance = RupiahInputFormatter.parse(_balanceController.text);
    if (balance <= 0) return;

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (isCash ? AppStrings.cashDefaultName : (_selectedBank?.name ?? 'Instrumen'));

    final isBankOrDigital = _selectedCategory == InstrumentType.bank ||
        _selectedCategory == InstrumentType.digitalBank;
    final typeId = _resolveTypeId(_selectedCategory!, types);

    final feeAmount = (isBankOrDigital && _feeEnabled)
        ? RupiahInputFormatter.parse(_feeController.text)
        : 0.0;
    final feeDay = (isBankOrDigital && _feeEnabled) ? _feeDay : 15;
    final feeEnabled = isBankOrDigital && _feeEnabled && feeAmount > 0;

    setState(() => _saving = true);

    Navigator.of(context).pop(
      FinancialInstrument(
        id: 'inst-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: _selectedCategory!,
        typeId: typeId,
        bankId: _selectedBank != null && _selectedBank!.id > 0 ? _selectedBank!.id : null,
        bankSlug: _selectedBank?.slug,
        initialBalance: balance,
        institutionName: isCash ? AppStrings.typeCash : (_selectedBank?.name ?? name),
        monthlyAdminFee: feeAmount,
        adminFeeDay: feeDay,
        adminFeeEnabled: feeEnabled,
        isSelected: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final typesAsync = ref.watch(instrumentTypesProvider);
    final types = typesAsync.asData?.value;

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Material(
      color: context.palette.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.palette.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    if (_selectedCategory != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setState(() {
                          _selectedCategory = null;
                          _selectedBank = null;
                          _attempted = false;
                        }),
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategory == null
                                ? AppStrings.selectCategory
                                : (_selectedCategory == InstrumentType.cash
                                    ? AppStrings.typeCash
                                    : _typeLabel(_selectedCategory!)),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.palette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedCategory == null
                                ? 'Pilih jenis instrumen keuangan kamu'
                                : 'Lengkapi detail saldo dan informasi rekening',
                            style: textTheme.bodySmall?.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: context.palette.outlineVariant),

              // Konten: Langkah 1 (Kategori) atau Langkah 2 (Detail)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: _selectedCategory == null
                      ? _buildCategorySelection(context)
                      : _buildDetailForm(context, types),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelection(BuildContext context) {
    return Column(
      children: [
        _CategoryOptionTile(
          title: AppStrings.typeBank,
          subtitle: 'BCA, Mandiri, BRI, BNI, BSI, CIMB Niaga, dll.',
          visual: _visualOf(InstrumentType.bank),
          onTap: () => _selectCategory(InstrumentType.bank),
        ),
        const SizedBox(height: 12),
        _CategoryOptionTile(
          title: AppStrings.typeDigitalBank,
          subtitle: 'Bank Jago, Jenius, SeaBank, Blu, Neobank, dll.',
          visual: _visualOf(InstrumentType.digitalBank),
          onTap: () => _selectCategory(InstrumentType.digitalBank),
        ),
        const SizedBox(height: 12),
        _CategoryOptionTile(
          title: AppStrings.typeEWallet,
          subtitle: 'GoPay, OVO, DANA, ShopeePay, LinkAja, AstraPay, dll.',
          visual: _visualOf(InstrumentType.ewallet),
          onTap: () => _selectCategory(InstrumentType.ewallet),
        ),
      ],
    );
  }

  Widget _buildDetailForm(BuildContext context, List<ApiInstrumentType>? types) {
    final textTheme = Theme.of(context).textTheme;
    final isCash = _selectedCategory == InstrumentType.cash;

    final balance = RupiahInputFormatter.parse(_balanceController.text);
    final showBalanceError = _attempted && balance <= 0;
    final showProviderError = _attempted && !isCash && _selectedBank == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCash) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.palette.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: context.palette.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Uang tunai dicatat sebagai kas fisik tanpa biaya admin bulanan.',
                    style: textTheme.bodySmall?.copyWith(
                      color: context.palette.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _nameController,
            label: 'Nama Dompet / Kas',
            hint: AppStrings.cashDefaultName,
          ),
        ] else ...[
          Text(AppStrings.selectProvider, style: textTheme.labelLarge),
          const SizedBox(height: 8),
          if (_selectedBank == null)
            InkWell(
              onTap: _changeProvider,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.palette.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: showProviderError
                        ? Theme.of(context).colorScheme.error
                        : context.palette.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: context.palette.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.searchProviderHint,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.palette.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: context.palette.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: Glass.panel(context, radius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  BankLogoBadge(
                    bankName: _selectedBank!.name,
                    bankSlug: _selectedBank!.slug,
                    bankLogoUrl: _selectedBank!.logoUrl,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedBank!.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_selectedBank!.aliases.isNotEmpty)
                          Text(
                            _selectedBank!.aliases.join(' • '),
                            style: textTheme.bodySmall?.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _changeProvider,
                    child: const Text('Ganti'),
                  ),
                ],
              ),
            ),
          if (showProviderError) ...[
            const SizedBox(height: 6),
            const _DialogError(text: AppStrings.instrumentTypeRequired),
          ],
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
          const _DialogError(text: AppStrings.balanceRequired),
        ],

        if (_selectedCategory == InstrumentType.bank ||
            _selectedCategory == InstrumentType.digitalBank) ...[
          const SizedBox(height: 16),
          AdminFeeFormSection(
            enabled: _feeEnabled,
            onEnabledChanged: (val) => setState(() => _feeEnabled = val),
            feeController: _feeController,
            feeDay: _feeDay,
            onDayChanged: (day) => setState(() => _feeDay = day),
          ),
        ],

        const SizedBox(height: 24),
        AppButton(
          label: AppStrings.save,
          isLoading: _saving,
          onPressed: _saving ? null : () => _save(types),
        ),
      ],
    );
  }
}

class _CategoryOptionTile extends StatelessWidget {
  const _CategoryOptionTile({
    required this.title,
    required this.subtitle,
    required this.visual,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final ({String asset, IconData icon, Color foreground, Color background}) visual;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: visual.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.asset(
                visual.asset,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  visual.icon,
                  color: visual.foreground,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.palette.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: context.palette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.palette.onSurfaceVariant,
              size: 20,
            ),
          ],
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
