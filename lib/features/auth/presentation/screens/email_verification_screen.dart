import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Layar verifikasi email pasca-registrasi / login akun belum terverifikasi.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _checking = false;
  bool _resending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  Future<void> _checkStatus() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final verified = await ref
          .read(authControllerProvider.notifier)
          .checkEmailVerificationStatus();

      if (!mounted) return;
      if (verified) {
        final isOnboarded =
            ref.read(authControllerProvider).user?.isOnboarded ?? false;
        context.go(
          isOnboarded ? AppRoutes.dashboard : AppRoutes.onboardingSalary,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email belum terverifikasi. Silakan klik tautan verifikasi di kotak masuk atau folder spam email Anda.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memeriksa status verifikasi. Coba lagi.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_resending || _cooldownSeconds > 0) return;
    setState(() => _resending = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resendVerificationEmail();
      if (!mounted) return;
      _startCooldown(60);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan verifikasi baru telah dikirim ke email Anda.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 429) {
        _startCooldown(60);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim ulang email verifikasi.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final email = authState.user?.email ?? 'email Anda';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Verifikasi Email',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Satu langkah lagi sebelum mulai mengatur keuanganmu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.72)
                      : AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          FloatingGlass(
            radius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cek Kotak Masuk Email Kamu',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kami telah mengirimkan tautan verifikasi ke:\n$email\n\nSilakan buka email tersebut dan klik tombol verifikasi, lalu tekan tombol di bawah ini.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.78)
                              : AppColors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: _checking ? 'Memeriksa...' : 'Saya Sudah Verifikasi',
            isLoading: _checking,
            onPressed: _checking ? null : _checkStatus,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: (_resending || _cooldownSeconds > 0)
                ? null
                : _resendEmail,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _resending
                  ? 'Mengirim Ulang...'
                  : _cooldownSeconds > 0
                      ? 'Kirim Ulang dalam ${_cooldownSeconds}d'
                      : 'Kirim Ulang Email Verifikasi',
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _logout,
            child: const Text('Keluar / Gunakan Akun Lain'),
          ),
        ],
      ),
    );
  }
}
