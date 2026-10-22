import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../providers/tahandulu_controller.dart';
import '../utils/tahandulu_ui.dart';
import '../widgets/tahandulu_widgets.dart';

/// Tambah Barang: tiga kartu metode (manual, link, foto-segera-hadir).
///
/// Tahap 46: ilustrasi header_tambah_barang + kartu konsisten.
/// Catatan audit: ikon 3D khusus manual/link/foto TIDAK ada di disk
/// (hanya icon_kategori_* dan icon_edit), sehingga kartu memakai
/// ikon Material dalam tile pastel — tanpa mengarang file aset.
class TahanDuluAddScreen extends ConsumerWidget {
  const TahanDuluAddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return TahanDuluScaffold(
      title: AppStrings.addItemTitle,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.addItemQuestion,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                color: TdColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.addItemHint,
              style: textTheme.bodyMedium?.copyWith(color: TdColors.slate),
            ),
            const SizedBox(height: 12),
            const Center(
              child: TdHeroImage(
                asset: TdHeaderArt.add,
                fallbackAsset:
                    'assets/illustrations/illustration_tas_tahandulu.png',
                height: 150,
                width: 220,
              ),
            ),
            const SizedBox(height: 16),
            _MethodCard(
              icon: Icons.edit_outlined,
              foreground: TdColors.warning,
              background: TdColors.warningBg,
              title: AppStrings.methodManual,
              subtitle: AppStrings.methodManualDesc,
              onTap: () {
                ref.read(tahanDuluControllerProvider.notifier).reset();
                context.push(AppRoutes.tahanDuluForm);
              },
            ),
            const SizedBox(height: 12),
            _MethodCard(
              icon: Icons.link_outlined,
              foreground: TdColors.success,
              background: TdColors.successBg,
              title: AppStrings.methodLink,
              subtitle: AppStrings.methodLinkDesc,
              onTap: () {
                ref.read(tahanDuluControllerProvider.notifier).reset();
                context.push(AppRoutes.tahanDuluLink);
              },
            ),
            const SizedBox(height: 12),
            _MethodCard(
              icon: Icons.camera_alt_outlined,
              foreground: const Color(0xFF8B5CF6),
              background: const Color(0xFFEEE9FE),
              title: AppStrings.methodPhoto,
              subtitle: AppStrings.methodPhotoDesc,
              badge: AppStrings.comingSoonBadge,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.photoComingSoon)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TdColors.creamCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: TdColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: TdColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kami akan menganalisis dampaknya terhadap '
                      'keuanganmu, bukan memberikan saran finansial.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: TdColors.slate,
                      ),
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

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TdColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TdColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F102A43),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: foreground, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            color: TdColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TdColors.highlight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge!,
                            style: textTheme.labelSmall?.copyWith(
                              color: TdColors.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: TdColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: TdColors.slate),
          ],
        ),
      ),
    );
  }
}
