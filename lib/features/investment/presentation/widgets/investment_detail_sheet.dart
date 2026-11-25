import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/financial_account.dart';
import '../../../../data/providers/app_providers.dart';
import '../providers/investment_controller.dart';

/// Lembar detail portofolio investasi beserta riwayat mutasi dan aksi top-up / withdraw.
class InvestmentDetailSheet extends ConsumerStatefulWidget {
  const InvestmentDetailSheet({
    super.key,
    required this.item,
  });

  final FinancialAccount item;

  static Future<void> show(BuildContext context, FinancialAccount item) {
    if (GlassDesignTokens.isDarkGlass(context)) {
      return showGlassSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => InvestmentDetailSheet(item: item),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvestmentDetailSheet(item: item),
    );
  }

  @override
  ConsumerState<InvestmentDetailSheet> createState() =>
      _InvestmentDetailSheetState();
}

class _InvestmentDetailSheetState extends ConsumerState<InvestmentDetailSheet> {
  Future<void> _showTransactionDialog({required bool isDeposit}) async {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final accounts = (ref.read(accountsProvider).value ?? [])
        .where((a) => a.isActive)
        .toList();

    String? selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
    bool saving = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isDeposit ? 'Top Up Investasi' : 'Pencairan Investasi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDeposit
                        ? 'Tambah modal ke ${widget.item.name}'
                        : 'Cairkan dana dari ${widget.item.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Nominal (Rp)',
                    hint: '0',
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                  ),
                  const SizedBox(height: 12),
                  if (accounts.isNotEmpty) ...[
                    Text(
                      isDeposit ? 'Sumber Dana (Rekening)' : 'Rekening Tujuan',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAccountId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: accounts.map((acc) {
                        return DropdownMenuItem<String>(
                          value: acc.id,
                          child: Text('${acc.name} (${CurrencyFormatter.formatCompact(acc.balance)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedAccountId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppTextField(
                    label: 'Catatan (Opsional)',
                    hint: isDeposit ? 'Misal: Top up bulanan' : 'Misal: Kebutuhan darurat',
                    controller: notesController,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final amount = RupiahInputFormatter.parse(amountController.text).round();
                        if (amount <= 0) {
                          setDialogState(() => errorMessage = 'Nominal harus lebih dari 0');
                          return;
                        }
                        if (selectedAccountId == null) {
                          setDialogState(() => errorMessage = 'Pilih rekening terlebih dahulu');
                          return;
                        }
                        if (!isDeposit && amount > widget.item.balance) {
                          setDialogState(() => errorMessage = 'Nominal pencairan melebihi portofolio');
                          return;
                        }

                        setDialogState(() {
                          saving = true;
                          errorMessage = null;
                        });

                        final success = await ref
                            .read(investmentControllerProvider)
                            .addInvestmentTransaction(
                              investmentId: widget.item.id,
                              type: isDeposit ? 'deposit' : 'withdraw',
                              amount: amount,
                              instrumentId: selectedAccountId!,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );

                        if (ctx.mounted) {
                          if (success) {
                            Navigator.pop(ctx);
                          } else {
                            setDialogState(() {
                              saving = false;
                              errorMessage = 'Gagal menyimpan transaksi investasi';
                            });
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isDeposit ? 'Setor' : 'Cairkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final transactionsAsync =
        ref.watch(apiInvestmentTransactionsProvider(widget.item.id));
    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: useDarkGlass
          ? null
          : BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, useDarkGlass ? 8 : 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!useDarkGlass) ...[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (widget.item.institutionName != null)
                          Text(
                            widget.item.institutionName!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nilai Portofolio',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(widget.item.balance),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.palette.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Top Up',
                      icon: Icons.add_circle_outline,
                      onPressed: () => _showTransactionDialog(isDeposit: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showTransactionDialog(isDeposit: false),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('Cairkan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Riwayat Mutasi Portofolio',
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: transactionsAsync.when(
                  data: (txList) {
                    if (txList.isEmpty) {
                      return const Center(
                        child: Text('Belum ada transaksi investasi.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: txList.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final tx = txList[index];
                        final isDep = tx.type == 'deposit';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isDep
                                ? context.palette.primary.withAlpha(30)
                                : Colors.amber.withAlpha(30),
                            child: Icon(
                              isDep ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isDep ? context.palette.primary : Colors.amber[800],
                              size: 20,
                            ),
                          ),
                          title: Text(
                            isDep ? 'Top Up' : 'Pencairan',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${tx.createdAt?.substring(0, 10) ?? ''}${tx.notes != null ? ' • ${tx.notes}' : ''}',
                            style: textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isDep ? '+' : '-'}${CurrencyFormatter.format(tx.amount.toDouble())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDep ? context.palette.primary : Colors.amber[800],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: ctx,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Hapus Transaksi?'),
                                      content: const Text('Tindakan ini akan membatalkan mutasi saldo rekening dan portofolio.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dCtx, false),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(dCtx, true),
                                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await ref
                                        .read(investmentControllerProvider)
                                        .deleteInvestmentTransaction(
                                          investmentId: widget.item.id,
                                          transactionId: tx.id,
                                        );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const AppLoading(),
                  error: (_, _) => const Center(
                    child: Text('Gagal memuat riwayat transaksi'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Hapus Portofolio', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  if (widget.item.balance > 0) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Portofolio masih memiliki saldo ${CurrencyFormatter.format(widget.item.balance)}. Cairkan seluruh aset terlebih dahulu.',
                        ),
                      ),
                    );
                    return;
                  }
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Hapus Portofolio Investasi?'),
                      content: Text('Apakah Anda yakin ingin menghapus "${widget.item.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(investmentControllerProvider)
                        .removeInvestment(widget.item.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
