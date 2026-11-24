import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/providers/account_providers.dart';
import '../../../../data/providers/app_providers.dart';
import '../../../../data/providers/dashboard_providers.dart';
import '../../../../data/providers/reports_providers.dart';
import '../providers/transactions_controller.dart';

/// Membuka lembar detail transaksi (F12) dengan perlindungan transaksi tertaut.
void showTransactionDetailSheet(
  BuildContext context,
  AppTransaction item, {
  String? accountName,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => TransactionDetailSheet(
      item: item,
      accountName: accountName,
    ),
  );
}

class TransactionDetailSheet extends ConsumerWidget {
  const TransactionDetailSheet({
    super.key,
    required this.item,
    this.accountName,
  });

  final AppTransaction item;
  final String? accountName;

  bool get _isOpeningBalance => item.category == 'Saldo Awal';

  bool get _isTransfer =>
      item.category == 'Transfer' ||
      item.title.startsWith('Transfer:') ||
      item.title.contains('Transfer Antar');

  bool get _isGoal =>
      item.category == 'Target & Tujuan' ||
      item.title.startsWith('Setor Target:') ||
      item.title.startsWith('Pencairan Target:');

  bool get _isWishlist =>
      item.category == 'Wishlist' ||
      item.title.startsWith('Beli Wishlist:');

  bool get _isInvestment =>
      item.category == 'Investasi' ||
      item.title.startsWith('Investasi:');

  bool get isLinkedTransaction =>
      _isOpeningBalance || _isTransfer || _isGoal || _isWishlist || _isInvestment;

  String get linkedFeatureName {
    if (_isOpeningBalance) return 'Saldo Awal Akun';
    if (_isTransfer) return 'Transfer Antar Rekening';
    if (_isGoal) return 'Target Keuangan';
    if (_isWishlist) return 'Tahan Dulu (Wishlist)';
    if (_isInvestment) return 'Portofolio Investasi';
    return 'Fitur Khusus';
  }

  String get linkedExplanation {
    if (_isOpeningBalance) {
      return 'Transaksi ini adalah saldo awal akun. Saldo awal terikat pada instrumen keuangan dan tidak dapat diubah dari riwayat transaksi.';
    }
    if (_isTransfer) {
      return 'Transaksi ini merupakan mutasi transfer antar rekening. Untuk membatalkan mutasi ini, silakan gunakan fitur Batalkan Transfer di menu Akun.';
    }
    if (_isGoal) {
      return 'Transaksi ini terhubung dengan target keuangan. Silakan lakukan perubahan atau penarikan dana melalui menu Target Keuangan.';
    }
    if (_isWishlist) {
      return 'Transaksi ini merupakan realisasi pembelian barang pertimbangan. Kelola melalui menu Tahan Dulu.';
    }
    if (_isInvestment) {
      return 'Transaksi ini terhubung dengan portofolio investasi.';
    }
    return 'Transaksi ini terhubung dengan entitas lain dan tidak dapat diubah secara bebas.';
  }

  void _refreshProviders(WidgetRef ref) {
    ref.invalidate(paginatedTransactionsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(accountsOverviewProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(dashboardDataProvider);
    ref.invalidate(monthlyReportProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = item.type == TransactionType.income;
    final color = isIncome ? context.palette.primary : context.palette.error;
    final sign = isIncome ? '+' : '-';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CategoryIcon.forLabel(item.category, item.type, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${isIncome ? 'Pemasukan' : 'Pengeluaran'} • ${item.category ?? 'Umum'}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: context.palette.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: Glass.panel(context, radius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nominal',
                      style: textTheme.bodySmall?.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sign${CurrencyFormatter.format(item.amount)}',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Tanggal',
                value: DateFormatter.dayMonthYear(item.date),
              ),
              _DetailRow(
                label: 'Rekening',
                value: accountName ?? 'Tidak diketahui',
              ),
              if (item.note != null && item.note!.isNotEmpty)
                _DetailRow(
                  label: 'Catatan',
                  value: item.note!,
                ),
              if (item.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Lampiran Struk',
                  style: textTheme.labelMedium?.copyWith(
                    color: context.palette.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.attachments.map((url) {
                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dCtx) => Dialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppBar(
                                  title: const Text('Pratinjau Struk'),
                                  leading: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.pop(dCtx),
                                  ),
                                ),
                                Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Gagal memuat pratinjau gambar struk.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.palette.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: context.palette.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long, size: 18, color: context.palette.primary),
                            const SizedBox(width: 6),
                            const Text('Lihat Struk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new, size: 14, color: context.palette.onSurfaceVariant),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              if (isLinkedTransaction) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.palette.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.palette.secondary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: context.palette.secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaksi Tertaut ($linkedFeatureName)',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.palette.secondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              linkedExplanation,
                              style: textTheme.bodySmall?.copyWith(
                                color: context.palette.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text('Edit Transaksi'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          _showEditDialog(context, ref);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(context).colorScheme.onError,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text('Hapus'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dlgContext) => AlertDialog(
                              title: const Text('Hapus Transaksi?'),
                              content: Text(
                                'Transaksi "${item.title}" sebesar ${CurrencyFormatter.format(item.amount)} akan dihapus. Saldo akun terkait akan disesuaikan kembali.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dlgContext).pop(false),
                                  child: const Text(AppStrings.cancel),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(dlgContext).colorScheme.error,
                                    foregroundColor: Theme.of(dlgContext).colorScheme.onError,
                                  ),
                                  onPressed: () => Navigator.of(dlgContext).pop(true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            try {
                              await ref
                                  .read(transactionRepositoryProvider)
                                  .deleteTransaction(item.id);
                              _refreshProviders(ref);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaksi berhasil dihapus.')),
                                );
                              }
                            } on ApiException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.message),
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gagal menghapus transaksi.')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController(text: item.title);
    final noteController = TextEditingController(text: item.note ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('Ubah Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Transaksi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dlgContext).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        final updated = item.copyWith(
          title: titleController.text.trim().isNotEmpty
              ? titleController.text.trim()
              : item.title,
          note: noteController.text.trim().isNotEmpty
              ? noteController.text.trim()
              : null,
        );
        await ref.read(transactionRepositoryProvider).updateTransaction(updated);
        _refreshProviders(ref);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil diperbarui.')),
          );
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memperbarui transaksi.')),
          );
        }
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.palette.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
