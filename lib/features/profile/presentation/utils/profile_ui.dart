import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

/// Navigasi bawah untuk layar Profil & Pengaturan.
/// Profil adalah tab aktif (indeks 4).
void profileOnNav(int index, BuildContext context) {
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
      break;
  }
}

/// Ikon dalam lingkaran pastel.
class ProfileIconContainer extends StatelessWidget {
  const ProfileIconContainer({
    super.key,
    required this.icon,
    required this.foreground,
    required this.background,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: foreground, size: iconSize),
    );
  }
}

/// Judul section halaman pengaturan.
class ProfileSectionHeader extends StatelessWidget {
  const ProfileSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

/// Baris menu pengaturan: ikon 3D (atau pastel fallback) + judul +
/// deskripsi + badge/chevron. Kartu putih radius 20 dengan shadow tipis.
/// [asset] path PNG ikon 3D; bila null/kosong/gagal muat, ikon outline
/// [icon] dipakai sebagai fallback sehingga kartu tak pernah kosong.
class SettingsMenuRow extends StatelessWidget {
  const SettingsMenuRow({
    super.key,
    required this.icon,
    required this.iconForeground,
    required this.iconBackground,
    required this.title,
    required this.description,
    this.asset,
    this.badge,
    this.badgeColor = AppColors.warning,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconForeground;
  final Color iconBackground;
  final String title;
  final String description;
  final String? asset;
  final String? badge;
  final Color badgeColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardLarge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardLarge,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MenuIcon(
              asset: asset,
              icon: icon,
              foreground: iconForeground,
              background: iconBackground,
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
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: titleColor,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: textTheme.labelSmall?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon menu: PNG 3D utuh (contain) bila [asset] tersedia, atau lingkaran
/// pastel outline bila path kosong maupun aset gagal dimuat.
class _MenuIcon extends StatelessWidget {
  const _MenuIcon({
    required this.asset,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String? asset;
  final IconData icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final path = asset ?? '';
    if (path.isEmpty) {
      return ProfileIconContainer(
        icon: icon,
        foreground: foreground,
        background: background,
        size: 48,
        iconSize: 24,
      );
    }
    return Image.asset(
      path,
      width: 48,
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => ProfileIconContainer(
        icon: icon,
        foreground: foreground,
        background: background,
        size: 48,
        iconSize: 24,
      ),
    );
  }
}

/// Banner ilustrasi header settings: gambar jadi (dengan teks bawaan)
/// ditampilkan utuh selebar kartu — contain tanpa crop, tanpa ColorFilter
/// agar transparansi/warna asli PNG terjaga. [fallbackIcon] dipakai bila
/// aset gagal dimuat.
class SettingsBanner extends StatelessWidget {
  const SettingsBanner({
    super.key,
    required this.asset,
    required this.semanticLabel,
    this.fallbackIcon = Icons.image_outlined,
    this.height,
  });

  final String asset;
  final String semanticLabel;
  final IconData fallbackIcon;

  /// Tinggi eksplisit; null berarti tinggi alami sesuai aspek gambar
  /// (tanpa celah letterbox).
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.cardLarge,
      child: Image.asset(
        asset,
        width: double.infinity,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
        errorBuilder: (context, error, stackTrace) => Container(
          width: double.infinity,
          height: height ?? 132,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(color: AppColors.border),
          ),
          child: ProfileIconContainer(
            icon: fallbackIcon,
            foreground: AppColors.primary,
            background: Colors.white,
            size: 56,
            iconSize: 28,
          ),
        ),
      ),
    );
  }
}

/// Dekorasi mint sudut kanan atas AppBar (widget murni, di dalam bounds).
class AppBarMintCorner extends StatelessWidget {
  const AppBarMintCorner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: 56,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFD9F2E5),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog konfirmasi generik (keluar akun, hapus akun).
/// Mengembalikan true bila tombol konfirmasi ditekan.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.icon,
    required this.iconForeground,
    required this.iconBackground,
    required this.title,
    required this.message,
    this.cancelLabel = 'Batal',
    required this.confirmLabel,
    this.confirmColor = AppColors.error,
  });

  final IconData icon;
  final Color iconForeground;
  final Color iconBackground;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final Color confirmColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileIconContainer(
            icon: icon,
            foreground: iconForeground,
            background: iconBackground,
            size: 56,
            iconSize: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required IconData icon,
  required Color iconForeground,
  required Color iconBackground,
  required String title,
  required String message,
  String cancelLabel = 'Batal',
  required String confirmLabel,
  Color confirmColor = AppColors.error,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      icon: icon,
      iconForeground: iconForeground,
      iconBackground: iconBackground,
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
    ),
  );
  return result ?? false;
}

/// Dialog info satu tombol (kebijakan, syarat, lisensi, fitur mendatang).
Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String body,
  String closeLabel = 'Tutup',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(title),
      content: SingleChildScrollView(child: Text(body)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(closeLabel),
        ),
      ],
    ),
  );
}
