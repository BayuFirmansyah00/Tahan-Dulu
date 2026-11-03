import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../presentation/providers/onboarding_status_provider.dart';

/// Pemicu popup ajakan melengkapi profil keuangan di Dashboard.
///
/// Widget ini sendiri tidak terlihat (mengembalikan [SizedBox.shrink]) dan
/// hanya bertugas memantau [onboardingStatusProvider]. Ketika status sudah
/// diketahui (bukan loading/error) DAN onboarding belum selesai, ia memanggil
/// [showDialog] satu kali per sesi untuk akun tersebut.
///
/// Perbaikan atas versi sebelumnya yang merender [AlertDialog] secara inline
/// di dalam [Stack] (tanpa modal barrier) dan memakai `context.pop()` yang
/// melempar pengguna keluar dari Dashboard. Sekarang dialog ditampilkan
/// lewat [showDialog] sehingga tombol menutup hanya dialog itu sendiri.
class OnboardingInvitationPopup extends ConsumerStatefulWidget {
  const OnboardingInvitationPopup({super.key});

  @override
  ConsumerState<OnboardingInvitationPopup> createState() =>
      _OnboardingInvitationPopupState();
}

class _OnboardingInvitationPopupState
    extends ConsumerState<OnboardingInvitationPopup> {
  /// Id pengguna yang sudah dijadwalkan dialog-nya pada lifecycle widget ini.
  /// Mencegah penjadwalan [showDialog] ganda untuk akun yang sama (mis. dari
  /// banyak rebuild / listen fire cepat), namun tetap mengizinkan penjadwalan
  /// baru bila akun berganti (id berbeda).
  String? _scheduledFor;

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan status tanpa memblokir build.
    ref.listen(onboardingStatusProvider, (previous, next) {
      _evaluate(next);
    });

    // Saat build pertama, nilai mungkin sudah tersedia (mis. provider sudah
    // pernah di-await di layar sebelumnya). Evaluasi nilai saat ini.
    _evaluate(ref.read(onboardingStatusProvider));

    return const SizedBox.shrink();
  }

  void _evaluate(AsyncValue<OnboardingStatus> statusAsync) {
    // Hanya bertindak ketika status benar-benar sudah diketahui.
    // Loading / error -> jangan tampilkan apa pun (dan jangan logout).
    final status = statusAsync.maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );
    if (status == null) return;

    // Onboarding sudah selesai -> tidak perlu mengajak.
    if (status.isCompleted) return;

    // Sudah ditampilkan untuk akun ini pada sesi berjalan -> jangan ganda.
    final shownFor = ref.read(onboardingPopupShownNotifierProvider);
    if (shownFor == status.userId) return;

    // Sudah dijadwalkan untuk akun ini -> jangan ganda.
    if (_scheduledFor == status.userId) return;
    _scheduledFor = status.userId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showDialog(status.userId);
    });
  }

  void _showDialog(String? userId) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _OnboardingInvitationDialog(
        onComplete: () {
          Navigator.of(dialogContext).pop();
          ref.read(onboardingPopupShownNotifierProvider.notifier).markShown(userId);
          if (mounted) context.push(AppRoutes.onboardingSalary);
        },
        onLater: () {
          Navigator.of(dialogContext).pop();
          ref.read(onboardingPopupShownNotifierProvider.notifier).markShown(userId);
        },
      ),
    );
  }
}

/// Isi dialog ajakan: judul, deskripsi, dan dua tombol.
class _OnboardingInvitationDialog extends StatelessWidget {
  const _OnboardingInvitationDialog({
    required this.onComplete,
    required this.onLater,
  });

  final VoidCallback onComplete;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      icon: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.account_balance_wallet_outlined,
          size: 32,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        AppStrings.onboardingPopupTitle,
        textAlign: TextAlign.center,
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        AppStrings.onboardingPopupDescription,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: AppStrings.onboardingPopupCompleteNow,
              onPressed: onComplete,
            ),
            const SizedBox(height: 10),
            AppOutlineButton(
              label: AppStrings.onboardingPopupLater,
              onPressed: onLater,
            ),
          ],
        ),
      ],
    );
  }
}
