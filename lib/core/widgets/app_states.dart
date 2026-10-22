import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';

/// State kosong generik (dipakai semua fitur).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.title = AppStrings.emptyTitle,
    this.subtitle = AppStrings.emptySubtitle,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading terpusat.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// State error generik: ikon pastel + pesan ramah + tombol ulangi.
/// Dipakai semua cabang error provider agar konsisten (tanpa
/// membocorkan teks exception ke pengguna).
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message = AppStrings.loadFailed,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
