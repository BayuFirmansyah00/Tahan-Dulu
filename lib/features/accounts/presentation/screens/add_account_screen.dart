import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_account.dart';
import '../providers/accounts_controller.dart';
import '../utils/account_ui.dart';

/// Form tambah akun: jenis (grid), nama, institusi, saldo awal.
class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  AccountType _type = AccountType.bank;
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _balanceController = TextEditingController();
  bool _attempted = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text;
    final balance =
        RupiahInputFormatter.parse(_balanceController.text);
    final nameError = AccountsController.validateName(name) != null;
    final balanceError =
        AccountsController.validateInitialBalance(balance) != null;
    if (nameError || balanceError) {
      setState(() => _attempted = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await ref.read(accountsControllerProvider).addAccount(
            name: name,
            type: _type,
            initialBalance: balance,
            institutionName: _institutionController.text,
          );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addAccountTitle)),
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
                          AppStrings.chooseAccountType,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final type in AccountType.values)
                              _TypeCard(
                                type: type,
                                selected: _type == type,
                                onTap: () =>
                                    setState(() => _type = type),
                              ),
                          ],
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final AccountType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = accountVisual(type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(visual.icon, color: visual.foreground, size: 26),
            const SizedBox(height: 4),
            Text(
              accountTypeLabel(type),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
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
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.secondary,
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
