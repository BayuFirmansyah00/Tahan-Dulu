import 'package:flutter/material.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Komponen form bersama untuk pengaturan biaya administrasi akun bulanan.
/// Digunakan pada Onboarding Tahap 2, Tambah Akun, dan Edit Akun.
class AdminFeeFormSection extends StatelessWidget {
  const AdminFeeFormSection({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    required this.feeController,
    required this.feeDay,
    required this.onDayChanged,
    this.fieldError,
  });

  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final TextEditingController feeController;
  final int feeDay;
  final ValueChanged<int> onDayChanged;
  final String? fieldError;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Biaya Administrasi Bulanan',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _AdminFeeOptionTile(
                title: 'Tidak Ada',
                subtitle: 'Bebas biaya',
                icon: Icons.money_off_csred_outlined,
                isSelected: !enabled,
                onTap: () => onEnabledChanged(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminFeeOptionTile(
                title: 'Ada Biaya',
                subtitle: 'Rutin bulanan',
                icon: Icons.receipt_long_outlined,
                isSelected: enabled,
                onTap: () => onEnabledChanged(true),
              ),
            ),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: 14),
          AppTextField(
            controller: feeController,
            label: 'Nominal Biaya Admin',
            hint: '0',
            prefixText: 'Rp ',
            keyboardType: TextInputType.number,
            inputFormatters: [RupiahInputFormatter()],
          ),
          if (fieldError != null) ...[
            const SizedBox(height: 6),
            Text(
              fieldError!,
              style: textTheme.bodySmall?.copyWith(color: context.palette.error),
            ),
          ],
          const SizedBox(height: 12),
          Text('Tanggal Pemotongan', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: feeDay,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.palette.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.palette.outlineVariant),
              ),
            ),
            items: [
              for (var day = 1; day <= 31; day++)
                DropdownMenuItem(
                  value: day,
                  child: Text('Tanggal $day'),
                ),
            ],
            selectedItemBuilder: (context) => [
              for (var day = 1; day <= 31; day++)
                Text('Setiap tanggal $day'),
            ],
            onChanged: (day) {
              if (day != null) onDayChanged(day);
            },
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: context.palette.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Jika tanggal tidak tersedia pada bulan tertentu (cth. tgl 31 di Februari), '
                  'pemotongan diestimasi pada hari terakhir bulan tersebut. Biaya ini tidak otomatis memotong saldo.',
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AdminFeeOptionTile extends StatelessWidget {
  const _AdminFeeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? context.palette.primaryContainer : context.palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? context.palette.primary : context.palette.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? context.palette.primary : context.palette.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? context.palette.primary
                              : context.palette.onSurface,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: isSelected
                              ? context.palette.primary
                              : context.palette.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

