import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/api_bank.dart';
import '../../../../data/models/api_financial_instrument.dart';
import '../../../../data/providers/app_providers.dart';
import '../providers/accounts_controller.dart';
import '../widgets/admin_fee_form_section.dart';
import '../widgets/bank_logo_badge.dart';
import '../widgets/bank_picker_sheet.dart';

/// Form tambah akun: dropdown instrumen master dari API, nama, institusi, saldo awal.
class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _balanceController = TextEditingController();
  final _feeController = TextEditingController();
  int _feeDay = 15;
  bool _feeEnabled = false;
  int? _selectedInstrumentTypeId;
  ApiBank? _selectedBank;
  bool _attempted = false;
  bool _saving = false;
  bool _loadingInstrumentTypes = true;

  /// Error validasi per field dari backend (status 422).
  Map<String, List<String>>? _fieldErrors;

  List<ApiInstrumentType> _instrumentTypes = [];

  @override
  void initState() {
    super.initState();
    _loadInstrumentTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  String? get _selectedCategoryFilter {
    if (_selectedInstrumentTypeId == null) return null;
    final match =
        _instrumentTypes.where((t) => t.id == _selectedInstrumentTypeId);
    if (match.isEmpty) return null;
    final typeLower =
        match.first.type.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    if (typeLower == 'bank') return 'bank';
    if (typeLower == 'digitalbank') return 'digitalBank';
    if (typeLower == 'ewallet') return 'ewallet';
    return null;
  }

  String get _catalogTitle {
    final cat = _selectedCategoryFilter;
    if (cat == 'digitalBank') return 'Katalog Bank Digital';
    if (cat == 'ewallet') return 'Katalog E-Wallet';
    return 'Katalog Bank';
  }

  String get _catalogActionHint {
    final cat = _selectedCategoryFilter;
    if (cat == 'digitalBank') return 'Pilih dari Katalog Bank Digital';
    if (cat == 'ewallet') return 'Pilih dari Katalog E-Wallet';
    return 'Pilih dari Katalog Bank';
  }

  Future<void> _loadInstrumentTypes() async {
    final types = await ref.read(instrumentTypesProvider.future);
    if (!mounted) return;
    final filtered = types.where((t) {
      final typeLower =
          t.type.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
      if (typeLower == 'cash' ||
          typeLower == 'uangtunai' ||
          typeLower == 'tunai') {
        return false;
      }
      return typeLower == 'bank' ||
          typeLower == 'digitalbank' ||
          typeLower == 'ewallet';
    }).toList();

    setState(() {
      _instrumentTypes = filtered.isNotEmpty ? filtered : types;
      _loadingInstrumentTypes = false;
    });
  }

  Future<void> _pickBank() async {
    final catFilter = _selectedCategoryFilter;
    final title = catFilter == 'digitalBank'
        ? 'Pilih Bank Digital'
        : catFilter == 'ewallet'
            ? 'Pilih E-Wallet'
            : 'Pilih Bank';
    final subtitle = catFilter == 'digitalBank'
        ? 'Bank Jago, Jenius, SeaBank, Blu, Neobank, dll.'
        : catFilter == 'ewallet'
            ? 'GoPay, OVO, DANA, ShopeePay, LinkAja, AstraPay, dll.'
            : 'BCA, Mandiri, BRI, BNI, BSI, CIMB Niaga, dll.';

    final bank = await BankPickerSheet.show(
      context,
      selectedBankId: _selectedBank?.id,
      selectedBankSlug: _selectedBank?.slug,
      categoryFilter: catFilter,
      title: title,
      subtitle: subtitle,
    );
    if (bank != null && mounted) {
      setState(() {
        _selectedBank = bank;
        // Auto-select type jika belum dipilih
        if (_selectedInstrumentTypeId == null && _instrumentTypes.isNotEmpty) {
          final targetTypeStr = bank.category == 'ewallet'
              ? 'ewallet'
              : bank.category == 'digitalBank'
                  ? 'digitalbank'
                  : 'bank';
          final matched = _instrumentTypes.firstWhere(
            (t) =>
                t.type.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '') ==
                targetTypeStr,
            orElse: () => _instrumentTypes.first,
          );
          _selectedInstrumentTypeId = matched.id;
        }
        // Selalu sinkronkan Nama Akun dan Institusi dengan penyedia yang baru dipilih
        _nameController.text = bank.name;
        _institutionController.text = bank.name;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text;
    final balance =
        RupiahInputFormatter.parse(_balanceController.text);
    final nameError = AccountsController.validateName(name) != null;
    final balanceError =
        AccountsController.validateInitialBalance(balance) != null;
    if (nameError || balanceError) {
      setState(() {
        _attempted = true;
        _fieldErrors = null;
      });
      return;
    }
    // Auto-select kategori jika bank/e-wallet sudah dipilih dari katalog
    if (_selectedInstrumentTypeId == null &&
        _selectedBank != null &&
        _instrumentTypes.isNotEmpty) {
      final targetTypeStr = _selectedBank!.category == 'ewallet'
          ? 'ewallet'
          : _selectedBank!.category == 'digitalBank'
              ? 'digitalbank'
              : 'bank';
      final matched = _instrumentTypes.firstWhere(
        (t) =>
            t.type.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '') ==
            targetTypeStr,
        orElse: () => _instrumentTypes.first,
      );
      _selectedInstrumentTypeId = matched.id;
    }
    if (_selectedInstrumentTypeId == null) {
      setState(() {
        _attempted = true;
        _fieldErrors = null;
      });
      return;
    }
    final isBankOrDigital = _selectedCategoryFilter == 'bank' ||
        _selectedCategoryFilter == 'digitalBank';
    final feeAmount = (isBankOrDigital && _feeEnabled)
        ? RupiahInputFormatter.parse(_feeController.text)
        : 0.0;
    final feeDay = (isBankOrDigital && _feeEnabled) ? _feeDay : 15;
    final feeEnabled = isBankOrDigital && _feeEnabled && feeAmount > 0;

    setState(() {
      _saving = true;
      _fieldErrors = null;
    });
    try {
      final ok = await ref.read(accountsControllerProvider).addAccount(
            name: name,
            typeId: _selectedInstrumentTypeId,
            initialBalance: balance,
            institutionName: _institutionController.text,
            bankId: _selectedBank?.id,
            bankSlug: _selectedBank?.slug,
            bankName: _selectedBank?.name,
            bankLogoUrl: _selectedBank?.logoUrl,
            monthlyAdminFee: feeAmount,
            adminFeeDay: feeEnabled ? feeDay : null,
            adminFeeEnabled: feeEnabled,
          );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveFailed)),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = e.fieldErrors;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showNameError = _attempted &&
        AccountsController.validateName(_nameController.text) != null;
    final showBalanceError = _attempted &&
        AccountsController.validateInitialBalance(
              RupiahInputFormatter.parse(_balanceController.text),
            ) !=
            null;
    final showTypeError = _attempted && _selectedInstrumentTypeId == null;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.addAccountTitle),
      ),
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
                        Text(
                          AppStrings.chooseInstrumentType,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_loadingInstrumentTypes)
                          const SizedBox(
                            height: 56,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                        else if (_instrumentTypes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppStrings.instrumentTypeEmpty,
                              style: textTheme.bodyMedium,
                            ),
                          )
                        else
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _selectedInstrumentTypeId,
                            hint: const Text('Pilih kategori instrumen...'),
                            items: _instrumentTypes
                                .map((type) => DropdownMenuItem<int>(
                                      value: type.id,
                                      child: Text(
                                        type.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedInstrumentTypeId = v;
                                if (_selectedBank != null) {
                                  final cat = _selectedCategoryFilter;
                                  final bankCat = _selectedBank!.category;
                                  final isMatch = (cat == 'bank' &&
                                          (bankCat == 'bank' ||
                                              bankCat == 'bank-logo')) ||
                                      (cat == 'digitalBank' &&
                                          bankCat == 'digitalBank') ||
                                      (cat == 'ewallet' &&
                                          bankCat == 'ewallet');
                                  if (!isMatch) {
                                    _selectedBank = null;
                                  }
                                }
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        if (showTypeError) ...[
                          const SizedBox(height: 6),
                          _FieldError(
                              text: AppStrings.instrumentTypeRequired),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          _catalogTitle,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickBank,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedBank != null
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: _selectedBank != null ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (_selectedBank != null) ...[
                                  BankLogoBadge(
                                    bankName: _selectedBank!.name,
                                    bankSlug: _selectedBank!.slug,
                                    bankLogoUrl: _selectedBank!.logoUrl,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedBank!.name,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          _selectedBank!.aliases.isNotEmpty
                                              ? _selectedBank!.aliases.join(' • ')
                                              : _selectedBank!.slug.toUpperCase(),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () => setState(() {
                                      if (_nameController.text == _selectedBank?.name) {
                                        _nameController.clear();
                                      }
                                      if (_institutionController.text == _selectedBank?.name) {
                                        _institutionController.clear();
                                      }
                                      _selectedBank = null;
                                    }),
                                  ),
                                ] else ...[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondarySoft,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _selectedCategoryFilter == 'ewallet'
                                            ? Icons.account_balance_wallet_outlined
                                            : (_selectedCategoryFilter == 'digitalBank'
                                                ? Icons.smartphone_outlined
                                                : Icons.account_balance_outlined),
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _catalogActionHint,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _selectedCategoryFilter == 'ewallet'
                                              ? '17 e-wallet resmi berizin Bank Indonesia'
                                              : (_selectedCategoryFilter == 'digitalBank'
                                                  ? '16 bank digital terverifikasi OJK'
                                                  : '140+ bank resmi Indonesia'),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const AppImageIcon(
                                    assetPath: AppAssets.navForward,
                                    size: 20,
                                    fallbackIcon: Icons.chevron_right,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _nameController,
                          label: AppStrings.accountName,
                          hint: AppStrings.accountNameHint,
                        ),
                        if (showNameError) ...[
                          const SizedBox(height: 6),
                          _FieldError(
                            text: AppStrings.accountNameRequired,
                          ),
                        ],
                        if (_fieldErrors != null &&
                            _fieldErrors!['name'] != null) ...[
                          const SizedBox(height: 6),
                          _FieldError(
                              text: _fieldErrors!['name']!.first),
                        ],
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _institutionController,
                          label: AppStrings.institutionName,
                          hint: AppStrings.institutionHint,
                        ),
                        const SizedBox(height: 12),
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
                          _FieldError(
                            text: AppStrings.balanceRequired,
                          ),
                        ],
                        if (_fieldErrors != null &&
                            _fieldErrors!['balance'] != null) ...[
                          const SizedBox(height: 6),
                          _FieldError(
                              text: _fieldErrors!['balance']!.first),
                        ],
                        if (_selectedCategoryFilter == 'bank' ||
                            _selectedCategoryFilter == 'digitalBank') ...[
                          const SizedBox(height: 16),
                          AdminFeeFormSection(
                            enabled: _feeEnabled,
                            onEnabledChanged: (val) =>
                                setState(() => _feeEnabled = val),
                            feeController: _feeController,
                            feeDay: _feeDay,
                            onDayChanged: (day) =>
                                setState(() => _feeDay = day),
                            fieldError:
                                _fieldErrors?['monthly_admin_fee']?.first,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _InfoBanner(text: AppStrings.accountSavedHint),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AppButton(
                    label: AppStrings.saveAccount,
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppImageIcon(
            assetPath: AppAssets.statusInfo,
            size: 18,
            fallbackIcon: Icons.info_outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError({required this.text});

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
