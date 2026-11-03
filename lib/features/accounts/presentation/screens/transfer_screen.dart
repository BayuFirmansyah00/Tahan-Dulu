import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/providers/account_providers.dart';
import '../providers/accounts_controller.dart';

/// Layar formulir transfer antar-rekening internal pengguna.
///
/// Aturan bisnis:
/// - Dropdown hanya menampilkan akun aktif milik pengguna yang sedang login.
/// - Dilarang menggunakan seluruh katalog bank sebagai tujuan transfer.
/// - Akun tujuan harus berbeda dengan akun sumber.
/// - Nominal transfer harus > 0 dan tidak boleh melebihi saldo akun sumber.
/// - Transfer bersifat net-neutral: tidak mengubah total saldo aset pengguna
///   dan tidak memotong anggaran belanja kebutuhan harian.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({
    super.key,
    this.initialSourceAccountId,
  });

  final String? initialSourceAccountId;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedSourceId;
  String? _selectedDestinationId;
  bool _submitting = false;
  String? _errorMessage;
  String? _transferAttemptKey;

  @override
  void initState() {
    super.initState();
    _selectedSourceId = widget.initialSourceAccountId;
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {
      _errorMessage = null;
      _transferAttemptKey = null; // Operasi nominal baru memerlukan key baru
    });
  }

  void _setAmount(double value) {
    _amountController.text = RupiahInputFormatter.format(value);
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    _transferAttemptKey = null;
  }

  Future<void> _submitTransfer(AccountOverview source, AccountOverview dest, double amount) async {
    if (_submitting) return;

    if (amount <= 0) {
      setState(() => _errorMessage = 'Nominal transfer harus lebih dari Rp 0');
      return;
    }

    if (amount > source.currentBalance) {
      setState(() => _errorMessage = AppStrings.transferInsufficientBalance);
      return;
    }

    if (source.account.id == dest.account.id) {
      setState(() => _errorMessage = AppStrings.transferSameAccountError);
      return;
    }

    // Pertahankan key yang sama jika user melakukan retry setelah timeout/kegagalan jaringan
    _transferAttemptKey ??=
        'flt-${DateTime.now().microsecondsSinceEpoch}-${source.account.id}-${dest.account.id}';

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(accountsControllerProvider).transfer(
            fromId: source.account.id,
            toId: dest.account.id,
            amount: amount,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            idempotencyKey: _transferAttemptKey,
          );

      if (!mounted) return;

      if (success) {
        _transferAttemptKey = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.transferSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      } else {
        setState(() {
          _errorMessage = 'Transfer gagal diproses. Silakan periksa koneksi.';
          _submitting = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan tidak terduga saat memproses transfer.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accountsAsync = ref.watch(accountsOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.transferTitle),
        centerTitle: true,
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat daftar akun: $err',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AppOutlineButton(
                  label: 'Coba Lagi',
                  onPressed: () => ref.invalidate(accountsOverviewProvider),
                ),
              ],
            ),
          ),
        ),
        data: (accounts) {
          if (accounts.length < 2) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.transferTitle,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.transferMinAccountsError,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: AppStrings.addAccountTitle,
                        icon: Icons.add,
                        onPressed: () => context.push(AppRoutes.accountAdd),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Inisialisasi akun sumber
          _selectedSourceId ??= (widget.initialSourceAccountId != null &&
                  accounts.any((a) => a.account.id == widget.initialSourceAccountId))
              ? widget.initialSourceAccountId
              : accounts.first.account.id;

          final sourceAccount = accounts.firstWhere(
            (a) => a.account.id == _selectedSourceId,
            orElse: () => accounts.first,
          );

          // Akun tujuan hanya akun aktif milik user selain akun sumber terpilih
          final destCandidates = accounts.where((a) => a.account.id != sourceAccount.account.id).toList();

          if (_selectedDestinationId == null ||
              _selectedDestinationId == sourceAccount.account.id ||
              !destCandidates.any((a) => a.account.id == _selectedDestinationId)) {
            _selectedDestinationId = destCandidates.isNotEmpty ? destCandidates.first.account.id : null;
          }

          final destAccount = destCandidates.firstWhere(
            (a) => a.account.id == _selectedDestinationId,
            orElse: () => destCandidates.first,
          );

          final enteredAmount = RupiahInputFormatter.parse(_amountController.text);
          final isBalanceSufficient = enteredAmount <= sourceAccount.currentBalance;
          final isAmountValid = enteredAmount > 0 && isBalanceSufficient;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner penjelasan transfer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.transferExplanation,
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown Akun Sumber
                    Text(
                      AppStrings.transferSourceAccount,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildAccountDropdown(
                      context: context,
                      items: accounts,
                      selectedId: sourceAccount.account.id,
                      onChanged: (newId) {
                        if (newId != null && newId != _selectedSourceId) {
                          setState(() {
                            _selectedSourceId = newId;
                            _transferAttemptKey = null;
                            if (_selectedDestinationId == newId) {
                              final other = accounts.firstWhere((a) => a.account.id != newId);
                              _selectedDestinationId = other.account.id;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Akun Tujuan
                    Text(
                      AppStrings.transferDestinationAccount,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildAccountDropdown(
                      context: context,
                      items: destCandidates,
                      selectedId: destAccount.account.id,
                      onChanged: (newId) {
                        if (newId != null) {
                          setState(() {
                            _selectedDestinationId = newId;
                            _transferAttemptKey = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Nominal Transfer
                    Text(
                      AppStrings.transferAmount,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [RupiahInputFormatter()],
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
                        hintText: 'Rp 0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        errorText: !isBalanceSufficient && enteredAmount > 0
                            ? AppStrings.transferInsufficientBalance
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick amount chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickAmountChip('50rb', 50000),
                        _buildQuickAmountChip('100rb', 100000),
                        _buildQuickAmountChip('250rb', 250000),
                        _buildQuickAmountChip('500rb', 500000),
                        if (sourceAccount.currentBalance > 0)
                          ActionChip(
                            label: const Text('Semua Saldo'),
                            backgroundColor: AppColors.secondarySoft,
                            labelStyle: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _setAmount(sourceAccount.currentBalance),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Catatan Opsional
                    Text(
                      AppStrings.transferNotes,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLength: 255,
                      decoration: InputDecoration(
                        hintText: AppStrings.transferNotesHint,
                        prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Visual Ringkasan Simulasi Saldo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sync_alt, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Simulasi Saldo Setelah Transfer',
                                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildAccountBalanceRow(
                            label: 'Sumber: ${sourceAccount.account.name}',
                            currentBalance: sourceAccount.currentBalance,
                            projectedBalance: sourceAccount.currentBalance - enteredAmount,
                            isDeduction: true,
                          ),
                          const SizedBox(height: 10),
                          _buildAccountBalanceRow(
                            label: 'Tujuan: ${destAccount.account.name}',
                            currentBalance: destAccount.currentBalance,
                            projectedBalance: destAccount.currentBalance + enteredAmount,
                            isDeduction: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Message Banner jika ada
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 20, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Tombol Konfirmasi Transfer
                    AppButton(
                      label: AppStrings.transferSubmit,
                      icon: Icons.send_rounded,
                      isLoading: _submitting,
                      onPressed: isAmountValid && !_submitting
                          ? () => _submitTransfer(sourceAccount, destAccount, enteredAmount)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double amount) {
    return ActionChip(
      label: Text(label),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      onPressed: () => _setAmount(amount),
    );
  }

  Widget _buildAccountBalanceRow({
    required String label,
    required double currentBalance,
    required double projectedBalance,
    required bool isDeduction,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final isNegative = projectedBalance < 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Saldo saat ini: ${CurrencyFormatter.formatCompact(currentBalance)}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Menjadi',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              CurrencyFormatter.formatCompact(projectedBalance),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isNegative
                    ? AppColors.error
                    : (isDeduction ? AppColors.textPrimary : AppColors.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountDropdown({
    required BuildContext context,
    required List<AccountOverview> items,
    required String selectedId,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: selectedId,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item.account.id,
          child: Row(
            children: [
              AccountProviderIcon(
                type: item.account.type,
                institutionName: item.account.institutionName,
                bankName: item.account.bankName,
                bankSlug: item.account.bankSlug,
                bankLogoUrl: item.account.bankLogoUrl,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.account.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.formatCompact(item.currentBalance),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

