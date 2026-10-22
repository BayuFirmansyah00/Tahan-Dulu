import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../providers/accounts_controller.dart';
import '../utils/account_ui.dart';

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
  bool _initialized = false;
  bool _attempted = false;
  bool _saving = false;

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
    _initialized = true;
  }

  void _onNav(int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.push(AppRoutes.transactions);
      case 2:
        context.push(AppRoutes.transactions);
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
      setState(() => _attempted = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final ok =
          await ref.read(accountsControllerProvider).updateAccount(
                id: id,
                name: _nameController.text,
                type: _type!,
                initialBalance: balance,
                institutionName: _institutionController.text,
              );
      if (!mounted) return;
      if (ok) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
                  nameController: _nameController,
                  institutionController: _institutionController,
                  balanceController: _balanceController,
                  onType: (t) => setState(() => _type = t),
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
    required this.nameController,
    required this.institutionController,
    required this.balanceController,
    required this.onType,
    required this.onSave,
    required this.onDelete,
  });

  final bool attempted;
  final bool saving;
  final AccountType type;
  final TextEditingController nameController;
  final TextEditingController institutionController;
  final TextEditingController balanceController;
  final ValueChanged<AccountType> onType;
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
