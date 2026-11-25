import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_image_icon.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../data/models/transfer_model.dart';
import '../../../../data/providers/account_providers.dart';
import '../providers/accounts_controller.dart';

class TransferHistoryScreen extends ConsumerWidget {
  const TransferHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfersAsync = ref.watch(transfersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Riwayat Transfer'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transfersProvider);
        },
        child: transfersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: AppErrorState(
              message: 'Gagal memuat riwayat transfer: $err',
              onRetry: () => ref.invalidate(transfersProvider),
            ),
          ),
          data: (transfers) {
            if (transfers.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    title: 'Belum Ada Transfer',
                    subtitle:
                        'Semua perpindahan dana antar rekening internal Anda akan tercatat di sini.',
                    icon: Icons.swap_horiz_rounded,
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: transfers.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = transfers[index];
                return _TransferCard(
                  transfer: item,
                  onTap: () => _showTransferDetail(context, ref, item),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showTransferDetail(
    BuildContext context,
    WidgetRef ref,
    TransferItem transfer,
  ) {
    if (GlassDesignTokens.isDarkGlass(context)) {
      showGlassSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _TransferDetailSheet(transfer: transfer),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TransferDetailSheet(transfer: transfer),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer, required this.onTap});

  final TransferItem transfer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fromName = transfer.fromInstrument?.name ?? 'Akun Sumber';
    final toName = transfer.toInstrument?.name ?? 'Akun Tujuan';
    final amountText = transfer.amountFormatted ??
        CurrencyFormatter.format(transfer.amount);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fromName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        toName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (transfer.notes != null && transfer.notes!.isNotEmpty)
                  Text(
                    transfer.notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransferDetailSheet extends ConsumerStatefulWidget {
  const _TransferDetailSheet({required this.transfer});

  final TransferItem transfer;

  @override
  ConsumerState<_TransferDetailSheet> createState() =>
      _TransferDetailSheetState();
}

class _TransferDetailSheetState extends ConsumerState<_TransferDetailSheet> {
  bool _cancelling = false;

  Future<void> _confirmCancelTransfer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Transfer?'),
        content: Text(
          'Saldo sebesar ${widget.transfer.amountFormatted ?? CurrencyFormatter.format(widget.transfer.amount)} '
          'akan dikembalikan ke rekening ${widget.transfer.fromInstrument?.name ?? 'asal'} dan ditarik '
          'dari rekening ${widget.transfer.toInstrument?.name ?? 'tujuan'}.\n\n'
          'Pastikan saldo pada rekening tujuan masih mencukupi untuk pembalikan ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);

    try {
      final success = await ref
          .read(accountsControllerProvider)
          .cancelTransfer(widget.transfer.id);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(); // Tutup modal detail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer berhasil dibatalkan dan saldo dikembalikan.'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        setState(() => _cancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membatalkan transfer. Periksa koneksi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tidak Dapat Membatalkan'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transfer;
    final amountStr =
        t.amountFormatted ?? CurrencyFormatter.format(t.amount);
    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);

    final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!useDarkGlass) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Detail Transfer Dana',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              amountStr,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Dari Rekening', t.fromInstrument?.name ?? '-'),
          const Divider(height: 20),
          _buildInfoRow('Ke Rekening', t.toInstrument?.name ?? '-'),
          const Divider(height: 20),
          if (t.notes != null && t.notes!.isNotEmpty) ...[
            _buildInfoRow('Catatan', t.notes!),
            const Divider(height: 20),
          ],
          _buildInfoRow('ID Transaksi', t.id),
          const SizedBox(height: 28),
          AppButton(
            label: _cancelling ? 'Membatalkan...' : 'Batalkan Transfer',
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            isLoading: _cancelling,
            onPressed: _cancelling ? null : _confirmCancelTransfer,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      );

    final padding = EdgeInsets.only(
      left: 20,
      right: 20,
      top: useDarkGlass ? 8 : 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24,
    );

    if (useDarkGlass) {
      return Padding(padding: padding, child: content);
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: padding,
      child: content,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
