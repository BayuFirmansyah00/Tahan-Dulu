import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    hide GlassQuality;

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/api_bank.dart';
import '../../../../data/models/api_financial_instrument.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/accounts_controller.dart';
import '../utils/account_ui.dart';
import '../widgets/admin_fee_form_section.dart';
import '../widgets/bank_logo_badge.dart';
import '../widgets/bank_picker_sheet.dart';

/// Edit akun: nama, jenis, institusi, saldo tercatat + hapus (berkebijakan).
/// Penyesuaian saldo implisit tidak dibuat (gap terdokumentasi):
/// ubah "Saldo Tercatat" hanya sebagai koreksi eksplisit.
class EditAccountScreen extends ConsumerStatefulWidget {
  const EditAccountScreen({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _balanceController = TextEditingController();
  final _feeController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  int _feeDay = 15;
  bool _feeEnabled = false;
  bool _isActive = true;
  String _budgetFrequency = 'monthly';
  AccountType? _type;
  String? _typeId;
  List<ApiInstrumentType> _instrumentTypes = const [];
  ApiBank? _selectedBank;
  bool _initialized = false;
  bool _attempted = false;
  bool _saving = false;

  /// Error validasi per field dari backend (status 422).
  Map<String, List<String>>? _fieldErrors;

  @override
  void initState() {
    super.initState();
    _loadInstrumentTypes();
  }

  Future<void> _loadInstrumentTypes() async {
    try {
      final types = await ref.read(instrumentTypesProvider.future);
      if (!mounted) return;
      setState(() {
        _instrumentTypes = types;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    _feeController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _initFrom(FinancialAccount account) {
    _nameController.text = account.name;
    _institutionController.text = account.institutionName ?? '';
    _balanceController.text =
        RupiahInputFormatter.format(account.balance);
    _type = account.type;
    _typeId = account.typeId;
    _feeEnabled = account.adminFeeEnabled;
    _feeDay = account.adminFeeDay ?? 15;
    _feeController.text = account.monthlyAdminFee > 0
        ? RupiahInputFormatter.format(account.monthlyAdminFee)
        : '';
    _isActive = account.isActive;
    _maxBudgetController.text = account.maxBudget != null && account.maxBudget! > 0
        ? RupiahInputFormatter.format(account.maxBudget!)
        : '';
    _budgetFrequency = account.budgetFrequency ?? 'monthly';
    if (account.bankName != null ||
        account.bankSlug != null ||
        account.bankId != null) {
      _selectedBank = ApiBank(
        id: account.bankId ?? 0,
        slug: account.bankSlug ?? '',
        name: account.bankName ?? account.name,
        aliases: const [],
        category: account.type == AccountType.ewallet
            ? 'ewallet'
            : (account.type == AccountType.digitalBank
                ? 'digitalBank'
                : 'bank'),
        logoUrl: account.bankLogoUrl,
        isActive: true,
      );
    } else {
      _selectedBank = null;
    }
    _initialized = true;
  }

  Future<void> _pickBank() async {
    final catFilter = _type == AccountType.bank
        ? 'bank'
        : _type == AccountType.digitalBank
            ? 'digitalBank'
            : 'ewallet';
    final title = _type == AccountType.bank
        ? 'Pilih Bank'
        : _type == AccountType.digitalBank
            ? 'Pilih Bank Digital'
            : 'Pilih E-Wallet';
    final subtitle = _type == AccountType.bank
        ? 'BCA, Mandiri, BRI, BNI, BSI, CIMB Niaga, dll.'
        : _type == AccountType.digitalBank
            ? 'Bank Jago, Jenius, SeaBank, Blu, Neobank, dll.'
            : 'GoPay, OVO, DANA, ShopeePay, LinkAja, AstraPay, dll.';

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
        _nameController.text = bank.name;
        _institutionController.text = bank.name;
      });
    }
  }

  void _onNav(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.push(AppRoutes.transactions);
      case 2:
        context.push(AppRoutes.transactionRecordMethod);
      case 3:
        context.push(AppRoutes.goals);
      case 4:
        context.push(AppRoutes.settings);
    }
  }

  Future<void> _save(String id) async {
    if (_saving) return;
    final balance =
        RupiahInputFormatter.parse(_balanceController.text);
    if (AccountsController.validateName(_nameController.text) != null ||
        AccountsController.validateInitialBalance(balance) != null ||
        _type == null) {
      setState(() {
        _attempted = true;
        _fieldErrors = null;
      });
      return;
    }
    final isBankOrDigital =
        _type == AccountType.bank || _type == AccountType.digitalBank;
    final feeAmount = (isBankOrDigital && _feeEnabled)
        ? RupiahInputFormatter.parse(_feeController.text)
        : 0.0;
    final feeDay = (isBankOrDigital && _feeEnabled) ? _feeDay : 15;
    final feeEnabled = isBankOrDigital && _feeEnabled && feeAmount > 0;
    final maxBudgetValue = _maxBudgetController.text.trim().isNotEmpty
        ? RupiahInputFormatter.parse(_maxBudgetController.text)
        : null;

    setState(() {
      _saving = true;
      _fieldErrors = null;
    });
    try {
      final ok =
          await ref.read(accountsControllerProvider).updateAccount(
                id: id,
                name: _nameController.text,
                type: _type!,
                typeId: _typeId,
                initialBalance: balance,
                institutionName: _institutionController.text,
                bankId: _selectedBank?.id,
                bankSlug: _selectedBank?.slug,
                bankName: _selectedBank?.name,
                bankLogoUrl: _selectedBank?.logoUrl,
                monthlyAdminFee: feeAmount,
                adminFeeDay: feeEnabled ? feeDay : null,
                adminFeeEnabled: feeEnabled,
                isActive: _isActive,
                maxBudget: maxBudgetValue,
                budgetFrequency: maxBudgetValue != null ? _budgetFrequency : null,
              );
      if (!mounted) return;
      if (ok) {
        context.pop();
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FinancialAccount account,
  ) async {
    final message = '“${account.name}” akan dihapus dari daftar akun.';
    final confirmed = GlassDesignTokens.isDarkGlass(context)
        ? await GlassDialog.show<bool>(
            context: context,
            title: AppStrings.deleteAccountTitle,
            message: message,
            settings: GlassDesignTokens.darkOverlaySettings(context),
            actions: [
              GlassDialogAction(
                label: AppStrings.cancel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
              GlassDialogAction(
                label: AppStrings.deleteAccount,
                isDestructive: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          )
        : await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(AppStrings.deleteAccountTitle),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(AppStrings.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text(AppStrings.deleteAccount),
                ),
              ],
            ),
          );
    if (confirmed != true || !context.mounted) return;
    try {
      final ok = await ref
          .read(accountsControllerProvider)
          .deleteAccount(account.id);
      if (!context.mounted) return;
      if (ok) {
        context.go(AppRoutes.accounts);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.deleteAccountBlocked),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message.isNotEmpty ? e.message : AppStrings.deleteAccountBlocked),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsOverviewProvider);

    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);

    return Scaffold(
      extendBody: useDarkGlass,
      extendBodyBehindAppBar: useDarkGlass,
      appBar: AppAdaptiveAppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.editAccountTitle),
      ),
      bottomNavigationBar: DashboardBottomNav(onTap: _onNav),
      body: GlassBackdrop(child: SafeArea(
        bottom: !useDarkGlass,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: accounts.when(
              data: (items) {
                final matches = items.where(
                  (e) => e.account.id == widget.accountId,
                );
                if (matches.isEmpty) {
                  return const Center(
                    child: Text(AppStrings.accountNotFound),
                  );
                }
                final account = matches.first.account;
                if (!_initialized) _initFrom(account);
                return _Form(
                  attempted: _attempted,
                  saving: _saving,
                  type: _type ?? account.type,
                  selectedBank: _selectedBank,
                  nameController: _nameController,
                  institutionController: _institutionController,
                  balanceController: _balanceController,
                  feeController: _feeController,
                  feeDay: _feeDay,
                  feeEnabled: _feeEnabled,
                  onFeeEnabledChanged: (val) =>
                      setState(() => _feeEnabled = val),
                  onFeeDayChanged: (day) => setState(() => _feeDay = day),
                  isActive: _isActive,
                  onIsActiveChanged: (val) => setState(() => _isActive = val),
                  maxBudgetController: _maxBudgetController,
                  budgetFrequency: _budgetFrequency,
                  onBudgetFrequencyChanged: (freq) =>
                      setState(() => _budgetFrequency = freq),
                  fieldErrors: _fieldErrors,
                  onType: (t) => setState(() {
                    _type = t;
                    if (_instrumentTypes.isNotEmpty) {
                      final targetSlug = t == AccountType.ewallet
                          ? 'ewallet'
                          : (t == AccountType.digitalBank ? 'digitalbank' : 'bank');
                      final matched = _instrumentTypes.where(
                        (it) => it.type.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '') == targetSlug,
                      );
                      if (matched.isNotEmpty) {
                        _typeId = matched.first.id;
                      }
                    }
                    if (_selectedBank != null) {
                      final cat = _selectedBank!.category;
                      final isMatch = (t == AccountType.bank &&
                              (cat == 'bank' || cat == 'bank-logo')) ||
                          (t == AccountType.digitalBank &&
                              cat == 'digitalBank') ||
                          (t == AccountType.ewallet && cat == 'ewallet');
                      if (!isMatch) {
                        _selectedBank = null;
                      }
                    }
                  }),
                  onPickBank: _pickBank,
                  onClearBank: () => setState(() {
                    if (_nameController.text == _selectedBank?.name) {
                      _nameController.clear();
                    }
                    if (_institutionController.text == _selectedBank?.name) {
                      _institutionController.clear();
                    }
                    _selectedBank = null;
                  }),
                  onSave: () => _save(account.id),
                  onDelete: () =>
                      _confirmDelete(context, ref, account),
                );
              },
              loading: () => const AppLoading(),
              error: (error, _) => AppErrorState(onRetry: () => ref.invalidate(accountsOverviewProvider)),
            ),
          ),
        ),
      )),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.attempted,
    required this.saving,
    required this.type,
    this.selectedBank,
    required this.nameController,
    required this.institutionController,
    required this.balanceController,
    required this.feeController,
    required this.feeDay,
    required this.feeEnabled,
    required this.onFeeEnabledChanged,
    required this.onFeeDayChanged,
    required this.isActive,
    required this.onIsActiveChanged,
    required this.maxBudgetController,
    required this.budgetFrequency,
    required this.onBudgetFrequencyChanged,
    this.fieldErrors,
    required this.onType,
    required this.onPickBank,
    required this.onClearBank,
    required this.onSave,
    required this.onDelete,
  });

  final bool attempted;
  final bool saving;
  final AccountType type;
  final ApiBank? selectedBank;
  final TextEditingController nameController;
  final TextEditingController institutionController;
  final TextEditingController balanceController;
  final TextEditingController feeController;
  final TextEditingController maxBudgetController;
  final int feeDay;
  final bool feeEnabled;
  final bool isActive;
  final String budgetFrequency;
  final ValueChanged<bool> onFeeEnabledChanged;
  final ValueChanged<int> onFeeDayChanged;
  final ValueChanged<bool> onIsActiveChanged;
  final ValueChanged<String> onBudgetFrequencyChanged;
  final Map<String, List<String>>? fieldErrors;
  final ValueChanged<AccountType> onType;
  final VoidCallback onPickBank;
  final VoidCallback onClearBank;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showNameError = attempted &&
        AccountsController.validateName(nameController.text) != null;
    final showBalanceError = attempted &&
        AccountsController.validateInitialBalance(
              RupiahInputFormatter.parse(balanceController.text),
            ) !=
            null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: nameController,
                  label: AppStrings.accountName,
                  hint: AppStrings.accountNameHint,
                ),
                if (showNameError) ...[
                  const SizedBox(height: 6),
                  _FieldError(text: AppStrings.accountNameRequired),
                ],
                if (fieldErrors?['name'] != null) ...[
                  const SizedBox(height: 6),
                  _FieldError(text: fieldErrors!['name']!.first),
                ],
                const SizedBox(height: 12),
                Text(
                  AppStrings.accountTypeLabel,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AppAdaptiveDropdown<AccountType>(
                  value: type,
                  items: [
                    for (final t in AccountType.values)
                      DropdownMenuItem(
                        value: t,
                        child: Text(accountTypeLabel(t)),
                      ),
                  ],
                  onChanged: (t) {
                    if (t != null) onType(t);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  type == AccountType.digitalBank
                      ? 'Katalog Bank Digital'
                      : (type == AccountType.ewallet
                          ? 'Katalog E-Wallet'
                          : 'Katalog Bank'),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onPickBank,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedBank != null
                            ? context.palette.primary
                            : context.palette.outlineVariant,
                        width: selectedBank != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (selectedBank != null) ...[
                          BankLogoBadge(
                            bankName: selectedBank!.name,
                            bankSlug: selectedBank!.slug,
                            bankLogoUrl: selectedBank!.logoUrl,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedBank!.name,
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  selectedBank!.aliases.isNotEmpty
                                      ? selectedBank!.aliases.join(' • ')
                                      : selectedBank!.slug.toUpperCase(),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: context.palette.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: onClearBank,
                          ),
                        ] else ...[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.palette.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                type == AccountType.ewallet
                                    ? Icons.account_balance_wallet_outlined
                                    : (type == AccountType.digitalBank
                                        ? Icons.smartphone_outlined
                                        : Icons.account_balance_outlined),
                                color: context.palette.primary,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type == AccountType.digitalBank
                                      ? 'Pilih dari Katalog Bank Digital'
                                      : (type == AccountType.ewallet
                                          ? 'Pilih dari Katalog E-Wallet'
                                          : 'Pilih dari Katalog Bank'),
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  type == AccountType.ewallet
                                      ? '17 e-wallet resmi berizin Bank Indonesia'
                                      : (type == AccountType.digitalBank
                                          ? '16 bank digital terverifikasi OJK'
                                          : '140+ bank resmi Indonesia'),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: context.palette.onSurfaceVariant,
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
                const SizedBox(height: 12),
                AppTextField(
                  controller: institutionController,
                  label: AppStrings.institutionName,
                  hint: AppStrings.institutionHint,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: balanceController,
                  label: AppStrings.recordedBalance,
                  hint: '0',
                  prefixText: 'Rp ',
                  keyboardType: TextInputType.number,
                  inputFormatters: [RupiahInputFormatter()],
                ),
                if (showBalanceError) ...[
                  const SizedBox(height: 6),
                  _FieldError(text: AppStrings.balanceRequired),
                ],
                if (fieldErrors?['balance'] != null) ...[
                  const SizedBox(height: 6),
                  _FieldError(text: fieldErrors!['balance']!.first),
                ],
                if (type == AccountType.bank ||
                    type == AccountType.digitalBank) ...[
                  const SizedBox(height: 16),
                  AdminFeeFormSection(
                    enabled: feeEnabled,
                    onEnabledChanged: onFeeEnabledChanged,
                    feeController: feeController,
                    feeDay: feeDay,
                    onDayChanged: onFeeDayChanged,
                    fieldError: fieldErrors?['monthly_admin_fee']?.first,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.palette.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batas Anggaran Akun (Opsional)',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tentukan limit pengeluaran untuk akun ini',
                        style: textTheme.bodySmall?.copyWith(
                          color: context.palette.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: maxBudgetController,
                        label: 'Maksimal Anggaran',
                        hint: 'Tanpa batas',
                        prefixText: 'Rp ',
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                      ),
                      const SizedBox(height: 12),
                      AppAdaptiveDropdown<String>(
                        value: budgetFrequency,
                        labelText: 'Frekuensi Anggaran',
                        decoration: const InputDecoration(
                          labelText: 'Frekuensi Anggaran',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Harian')),
                          DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                          DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                        ],
                        onChanged: (val) {
                          if (val != null) onBudgetFrequencyChanged(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppAdaptiveSwitchTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Status Akun Aktif', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Akun nonaktif tidak dapat digunakan untuk mutasi baru. Saldo historis tetap terjaga.',
                    style: textTheme.bodySmall?.copyWith(color: context.palette.onSurfaceVariant),
                  ),
                  value: isActive,
                  onChanged: onIsActiveChanged,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: AppButton(
            label: AppStrings.saveChanges,
            isLoading: saving,
            onPressed: saving ? null : onSave,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            GlassDesignTokens.isDarkGlass(context) ? 100 : 24,
          ),
          child: SizedBox(
            width: double.infinity,
            child: AppAdaptiveOutlinedButton(
              icon: const AppImageIcon(
                assetPath: AppAssets.actionDelete,
                size: 20,
                fallbackIcon: Icons.delete_outline,
              ),
              label: AppStrings.deleteAccount,
              foregroundColor: Theme.of(context).colorScheme.error,
              borderColor: Theme.of(context).colorScheme.error,
              height: 52,
              borderRadius: 16,
              onPressed: onDelete,
            ),
          ),
        ),
      ],
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
