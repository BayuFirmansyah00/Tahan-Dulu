import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/api_bank.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/accounts_controller.dart';
import '../utils/account_ui.dart';
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
  AccountType? _type;
  ApiBank? _selectedBank;
  bool _initialized = false;
  bool _attempted = false;
  bool _saving = false;

  /// Error validasi per field dari backend (status 422).
  Map<String, List<String>>? _fieldErrors;

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _initFrom(FinancialAccount account) {
    _nameController.text = account.name;
    _institutionController.text = account.institutionName ?? '';
    _balanceController.text =
        RupiahInputFormatter.format(account.balance);
    _type = account.type;
    final isBank = account.type == AccountType.bank ||
        account.type == AccountType.digitalBank;
    if (isBank &&
        (account.bankName != null ||
            account.bankSlug != null ||
            account.bankId != null)) {
      _selectedBank = ApiBank(
        id: account.bankId ?? 0,
        slug: account.bankSlug ?? '',
        name: account.bankName ?? account.name,
        aliases: const [],
        category: 'bank-logo',
        logoUrl: account.bankLogoUrl,
        isActive: true,
      );
    } else {
      _selectedBank = null;
    }
    _initialized = true;
  }

  Future<void> _pickBank() async {
    final bank = await BankPickerSheet.show(
      context,
      selectedBankId: _selectedBank?.id,
      selectedBankSlug: _selectedBank?.slug,
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
    setState(() {
      _saving = true;
      _fieldErrors = null;
    });
    final isBankCategory =
        _type == AccountType.bank || _type == AccountType.digitalBank;
    try {
      final ok =
          await ref.read(accountsControllerProvider).updateAccount(
                id: id,
                name: _nameController.text,
                type: _type!,
                initialBalance: balance,
                institutionName: _institutionController.text,
                bankId: isBankCategory ? _selectedBank?.id : null,
                bankSlug: isBankCategory ? _selectedBank?.slug : null,
                bankName: isBankCategory ? _selectedBank?.name : null,
                bankLogoUrl: isBankCategory ? _selectedBank?.logoUrl : null,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteAccountTitle),
        content: Text(
          '“${account.name}” akan dihapus dari daftar akun.',
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editAccountTitle)),
      bottomNavigationBar: DashboardBottomNav(onTap: _onNav),
      body: SafeArea(
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
                  fieldErrors: _fieldErrors,
                  onType: (t) => setState(() {
                    _type = t;
                    if (t == AccountType.ewallet) {
                      _selectedBank = null;
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
      ),
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
                DropdownButtonFormField<AccountType>(
                  initialValue: type,
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
                if (type == AccountType.bank ||
                    type == AccountType.digitalBank) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Katalog Bank',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onPickBank,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedBank != null
                              ? AppColors.primary
                              : AppColors.border,
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
                                      color: AppColors.textSecondary,
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
                                color: AppColors.secondarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_outlined,
                                color: AppColors.secondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hubungkan Bank (Opsional)',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Pilih dari 160+ bank resmi Indonesia',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text(AppStrings.deleteAccount),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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
