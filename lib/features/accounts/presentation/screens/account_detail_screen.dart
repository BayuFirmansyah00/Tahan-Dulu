import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import '../utils/account_ui.dart';

/// Detail akun: identitas, saldo saat ini (engine), transaksi terkait.
/// Transfer belum didukung model -> tombol memberi info tahap berikut.
class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  bool _obscured = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      bottomNavigationBar: DashboardBottomNav(onTap: _onNav),
      body: GlassBackdrop(child: SafeArea(
        child: _Body(
          accountId: widget.accountId,
          obscured: _obscured,
          onToggleObscure: () => setState(() => _obscured = !_obscured),
        ),
      )),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.accountId,
    required this.obscured,
    required this.onToggleObscure,
  });

  final String accountId;
  final bool obscured;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(accountsOverviewProvider);
    final transactions = ref.watch(transactionsProvider);

    if (overview is AsyncLoading || transactions is AsyncLoading) {
      return const AppLoading();
    }
    final overviewError = overview is AsyncError ? overview : null;
    final transactionsError = transactions is AsyncError ? transactions : null;
    if (overviewError != null) {
      return AppErrorState(
        onRetry: () => ref.invalidate(accountsOverviewProvider),
      );
    }
    if (transactionsError != null) {
      return AppErrorState(onRetry: () => ref.invalidate(transactionsProvider));
    }
    final matches =
        overview.value?.where((e) => e.account.id == accountId) ?? const [];
    if (matches.isEmpty) {
      return const Center(child: Text(AppStrings.accountNotFound));
    }
    final item = matches.first;
    final txs =
        transactions.value?.where((t) => t.accountId == accountId).toList() ??
        const [];
    final textTheme = Theme.of(context).textTheme;
    final account = item.account;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AccountProviderIcon(
                    type: account.type,
                    institutionName: account.institutionName,
                    bankName: account.bankName,
                    bankSlug: account.bankSlug,
                    bankLogoUrl: account.bankLogoUrl,
                    size: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name, style: textTheme.headlineMedium),
                        Text(
                          account.type == AccountType.legacyCash
                              ? 'Uang Tunai — Akun Lama'
                              : (account.bankName != null
                                  ? '${account.bankName} • ${accountTypeLabel(account.type)}'
                                  : accountTypeLabel(account.type)),
                          style: textTheme.bodyMedium?.copyWith(
                            color: account.type == AccountType.legacyCash
                                ? context.warningInk
                                : null,
                            fontWeight: account.type == AccountType.legacyCash
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (account.type != AccountType.legacyCash)
                    IconButton(
                      icon: const AppImageIcon(
                        assetPath: AppAssets.actionEdit,
                        size: 20,
                        fallbackIcon: Icons.edit_outlined,
                      ),
                      color: context.palette.primary,
                      onPressed: () =>
                          context.push('${AppRoutes.accounts}/$accountId/edit'),
                    ),
                ],
              ),
              if (account.type == AccountType.legacyCash) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.warningFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.warningFill),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: context.warningInk, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Uang Tunai — Akun Lama',
                              style: textTheme.labelLarge?.copyWith(
                                color: context.warningInk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Akun ini dipertahankan untuk menjaga saldo dan riwayat pencatatan sebelumnya. Akun Uang Tunai baru tidak lagi didukung.',
                              style: textTheme.bodySmall?.copyWith(
                                color: context.warningInk,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!account.isActive) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pause_circle_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Akun ini sedang dinonaktifkan. Saldo dan riwayat transaksi tetap tersimpan, namun akun tidak dapat digunakan untuk mutasi baru.',
                          style: textTheme.bodySmall?.copyWith(color: Colors.amber[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (account.institutionName != null &&
                  account.institutionName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(account.institutionName!, style: textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.currentBalanceLabel,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onToggleObscure,
                    child: Icon(
                      obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: context.palette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                obscured
                    ? 'Rp••••••'
                    : CurrencyFormatter.formatCompact(item.currentBalance),
                style: textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              Text(
                AppStrings.recordedBalanceHint,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (account.type == AccountType.legacyCash) ...[
                if (item.currentBalance > 0)
                  AppButton(
                    label: 'Rekonsiliasi Saldo ke Rekening',
                    icon: Icons.account_balance,
                    onPressed: () => _showReconciliationSheet(
                      context,
                      ref,
                      account,
                      item.currentBalance,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.palette.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Seluruh saldo tunai telah direkonsiliasi (Rp0)',
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.palette.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: AppStrings.transferAction,
                        assetPath: AppAssets.txTransfer,
                        icon: Icons.arrow_outward,
                        onPressed: () => context.push(
                          '${AppRoutes.accountTransfer}?from=$accountId',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppOutlineButton(
                        label: AppStrings.editAccountTitle,
                        assetPath: AppAssets.actionEdit,
                        icon: Icons.edit_outlined,
                        onPressed: () =>
                            context.push('${AppRoutes.accounts}/$accountId/edit'),
                      ),
                    ),
                  ],
                ),
              ],
              if (account.type == AccountType.bank ||
                  account.type == AccountType.digitalBank) ...[
                const SizedBox(height: 16),
                _AdminFeeCard(account: account),
              ],
              if (account.maxBudget != null && account.maxBudget! > 0) ...[
                const SizedBox(height: 16),
                _BudgetLimitCard(account: account),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.recentTransactionsTitle,
                      style: textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => context.push(
                        '${AppRoutes.transactions}?account=$accountId',
                      ),
                      child: Text(
                        AppStrings.seeAllAction,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.palette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    AppStrings.emptyAccountTransactions,
                    style: textTheme.bodyMedium,
                  ),
                )
              else
                for (final t in txs.take(5)) _TxRow(transaction: t),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.transaction});

  final AppTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? context.palette.primary : context.palette.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: textTheme.titleMedium),
                Text(
                  DateFormatter.dayMonthYear(transaction.date),
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}'
            '${CurrencyFormatter.formatCompact(transaction.amount)}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminFeeCard extends StatelessWidget {
  const _AdminFeeCard({required this.account});

  final FinancialAccount account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasFee = account.adminFeeEnabled && account.monthlyAdminFee > 0;
    final nextDate = account.getNextAdminFeeDate();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFee ? context.palette.surface : context.palette.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFee ? context.palette.outlineVariant : context.palette.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasFee
                      ? context.palette.primary.withValues(alpha: 0.1)
                      : context.palette.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFee
                      ? Icons.calendar_month_outlined
                      : Icons.check_circle_outline,
                  color: hasFee ? context.palette.primary : context.palette.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biaya Administrasi Bulanan',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      hasFee
                          ? '${CurrencyFormatter.formatCompact(account.monthlyAdminFee)} / bulan'
                          : 'Bebas biaya bulanan (Rp0)',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            hasFee ? context.palette.onSurface : context.palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasFee && account.adminFeeDay != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jadwal Pemotongan',
                    style: textTheme.bodyMedium?.copyWith(
                      color: context.palette.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  'Setiap tanggal ${account.adminFeeDay}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (nextDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Estimasi Berikutnya',
                      style: textTheme.bodyMedium?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    DateFormatter.dayMonthYear(nextDate),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.palette.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Biaya ini adalah rencana terjadwal dan tidak memotong saldo secara otomatis.',
              style: textTheme.bodySmall?.copyWith(
                color: context.palette.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ] else if (!hasFee) ...[
            const SizedBox(height: 6),
            Text(
              'Rekening ini tidak memiliki jadwal biaya administrasi rutin.',
              style: textTheme.bodySmall?.copyWith(
                color: context.palette.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetLimitCard extends StatelessWidget {
  const _BudgetLimitCard({required this.account});

  final FinancialAccount account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxBudget = account.maxBudget ?? 0;
    final frequency = account.budgetFrequency ?? 'monthly';
    final freqLabel = frequency == 'weekly'
        ? 'minggu'
        : (frequency == 'yearly' ? 'tahun' : 'bulan');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.palette.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.palette.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: context.palette.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batas Anggaran Akun',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(maxBudget)} / $freqLabel',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.palette.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Batas anggaran maksimum yang dialokasikan untuk instrumen ini.',
            style: textTheme.bodySmall?.copyWith(
              color: context.palette.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

void _showReconciliationSheet(
  BuildContext context,
  WidgetRef ref,
  FinancialAccount cashAccount,
  double currentBalance,
) {
  showGlassSheet<void>(
    context: context,
    isScrollControlled: true,
      builder: (ctx) => _ReconcileLegacyCashSheet(
      cashAccount: cashAccount,
      currentBalance: currentBalance,
    ),
  );
}

class _ReconcileLegacyCashSheet extends ConsumerStatefulWidget {
  const _ReconcileLegacyCashSheet({
    required this.cashAccount,
    required this.currentBalance,
  });

  final FinancialAccount cashAccount;
  final double currentBalance;

  @override
  ConsumerState<_ReconcileLegacyCashSheet> createState() =>
      _ReconcileLegacyCashSheetState();
}

class _ReconcileLegacyCashSheetState
    extends ConsumerState<_ReconcileLegacyCashSheet> {
  late final TextEditingController _amountController;
  String? _selectedToAccountId;
  bool _confirmed = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currentBalance > 0
          ? widget.currentBalance.toInt().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<AccountOverview> availableAccounts) async {
    setState(() => _error = null);

    if (_selectedToAccountId == null) {
      setState(() => _error = 'Pilih rekening bank atau e-wallet tujuan');
      return;
    }

    final rawAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (rawAmount <= 0) {
      setState(() => _error = 'Nominal rekonsiliasi harus lebih dari 0');
      return;
    }
    if (rawAmount > widget.currentBalance) {
      setState(() => _error =
          'Nominal tidak boleh melebihi sisa saldo tunai (${CurrencyFormatter.formatCompact(widget.currentBalance)})');
      return;
    }

    if (!_confirmed) {
      setState(() => _error = 'Harap centang konfirmasi penyetoran fisik');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(accountRepositoryProvider);
      await repo.reconcileLegacyCash(
        fromId: widget.cashAccount.id,
        toId: _selectedToAccountId!,
        amount: rawAmount,
        notes: 'Rekonsiliasi tunai ke rekening aktif',
      );

      ref.invalidate(accountsOverviewProvider);
      ref.invalidate(accountsTotalProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(transactionsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil merekonsiliasi ${CurrencyFormatter.formatCompact(rawAmount)} ke rekening tujuan.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final overview = ref.watch(accountsOverviewProvider);
    final availableAccounts = overview.maybeWhen(
      data: (items) => items
          .where((i) =>
              i.account.id != widget.cashAccount.id &&
              i.account.type != AccountType.legacyCash)
          .toList(),
      orElse: () => <AccountOverview>[],
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rekonsiliasi Saldo Tunai',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pindahkan catatan saldo uang tunai lama ke rekening bank atau e-wallet yang telah menerima setoran tunai riil.',
            style: textTheme.bodySmall?.copyWith(color: context.palette.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (availableAccounts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Tidak ada rekening bank atau e-wallet aktif. Silakan tambahkan rekening tujuan terlebih dahulu.',
                style: TextStyle(color: context.palette.onSurfaceVariant),
              ),
            ),
          ] else ...[
            Text('Rekening Tujuan', style: textTheme.labelMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedToAccountId,
              hint: const Text('Pilih rekening tujuan'),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.palette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.palette.outlineVariant),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: availableAccounts.map((item) {
                return DropdownMenuItem<String>(
                  value: item.account.id,
                  child: Text(
                    '${item.account.name} (${item.account.bankName ?? accountTypeLabel(item.account.type)})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedToAccountId = val),
            ),
            const SizedBox(height: 14),
            Text('Nominal Rekonsiliasi (Rp)', style: textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
                filled: true,
                fillColor: context.palette.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.palette.outlineVariant),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Maksimal saldo tunai: ${CurrencyFormatter.formatCompact(widget.currentBalance)}',
              style: textTheme.bodySmall
                  ?.copyWith(color: context.palette.onSurfaceVariant, fontSize: 11),
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              title: Text(
                'Saya mengonfirmasi bahwa uang tunai fisik ini telah disetorkan atau diisi ke rekening tujuan di atas.',
                style:
                    textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(
                    color: context.palette.error, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: _isSubmitting ? 'Memproses...' : 'Rekonsiliasi Sekarang',
              icon: Icons.check_circle_outline,
              onPressed:
                  _isSubmitting ? null : () => _submit(availableAccounts),
            ),
          ],
        ],
      ),
    );
  }
}
