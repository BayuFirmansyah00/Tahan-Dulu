import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    hide GlassQuality;

import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../screens/delete_account_otp_screen.dart';
import 'profile_ui.dart';

/// Membuka form modal bottom sheet untuk ubah kata sandi pengguna email.
Future<void> showChangePasswordBottomSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showGlassSheet<void>(
    context: context,
    isScrollControlled: true,
      builder: (ctx) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
            newPasswordConfirmation: _confirmController.text,
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diperbarui.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message =
          e is ApiException ? e.message : 'Gagal memperbarui kata sandi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubah Kata Sandi',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Masukkan kata sandi saat ini dan kata sandi baru minimal 8 karakter.',
                style: textTheme.bodyMedium?.copyWith(
                  color: context.palette.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _currentController,
                label: 'Kata Sandi Saat Ini',
                hint: 'Masukkan kata sandi saat ini',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureCurrent,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Kata sandi saat ini wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _newController,
                label: 'Kata Sandi Baru',
                hint: 'Minimal 8 karakter',
                prefixIcon: Icons.lock_reset_outlined,
                obscureText: _obscureNew,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kata sandi baru wajib diisi';
                  if (v.length < 8) return 'Minimal 8 karakter';
                  if (v == _currentController.text) {
                    return 'Kata sandi baru tidak boleh sama dengan kata sandi saat ini';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirmController,
                label: 'Konfirmasi Kata Sandi Baru',
                hint: 'Ulangi kata sandi baru',
                prefixIcon: Icons.check_circle_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Konfirmasi kata sandi wajib diisi';
                  }
                  if (v != _newController.text) {
                    return 'Konfirmasi kata sandi tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Simpan Kata Sandi',
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: 8),
              AppOutlineButton(
                label: 'Batal',
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alur terpadu untuk Hapus Akun permanen (mendukung Email/Password dan Google SSO).
Future<void> showDeleteAccountFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final auth = ref.read(authControllerProvider);
  final isGoogle = auth.loginMethod == 'google';

  if (isGoogle) {
    final confirmed = await showConfirmDialog(
      context: context,
      assetPath: AppAssets.setDeleteAccount,
      icon: Icons.delete_forever_outlined,
      iconForeground: context.palette.error,
      iconBackground: context.palette.errorContainer,
      title: 'Hapus Akun Permanen?',
      message:
          'Seluruh data transaksi, anggaran, dan target keuangan kamu akan dihapus secara permanen. Autentikasi ulang akun Google diperlukan untuk konfirmasi.',
      cancelLabel: 'Batal',
      confirmLabel: 'Lanjut Hapus Akun',
      confirmColor: context.palette.error,
    );
    if (!confirmed || !context.mounted) return;

    try {
      final googleToken = await ref
          .read(authControllerProvider.notifier)
          .getGoogleReauthIdToken();
      if (googleToken == null || googleToken.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penghapusan akun dibatalkan.')),
          );
        }
        return;
      }
      if (!context.mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DeleteAccountOtpScreen(googleIdToken: googleToken),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        final message =
            e is ApiException ? e.message : 'Gagal menghapus akun: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  } else {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _DeleteAccountPasswordDialog(
        onConfirm: (password) async {
          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          await Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => DeleteAccountOtpScreen(password: password),
            ),
          );
        },
      ),
    );
  }
}

class _DeleteAccountPasswordDialog extends StatefulWidget {
  const _DeleteAccountPasswordDialog({required this.onConfirm});

  final Future<void> Function(String password) onConfirm;

  @override
  State<_DeleteAccountPasswordDialog> createState() =>
      _DeleteAccountPasswordDialogState();
}

class _DeleteAccountPasswordDialogState
    extends State<_DeleteAccountPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onConfirm(_passwordController.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : 'Gagal menghapus akun: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (GlassDesignTokens.isDarkGlass(context)) {
      return GlassDialog(
        title: 'Hapus Akun',
        settings: GlassDesignTokens.darkOverlaySettings(context),
        content: InheritedGlassSurfaceStyle(
          surfaceStyle: GlassSurfaceStyle.solid,
          child: Material(
            type: MaterialType.transparency,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tindakan ini tidak dapat dibatalkan. Seluruh data keuangan, transaksi, dan target kamu akan dihapus secara permanen.\n\nMasukkan kata sandi untuk konfirmasi:',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Kata Sandi Akun',
                      hint: 'Masukkan kata sandi',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Kata sandi wajib diisi untuk konfirmasi'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.palette.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          GlassDialogAction(
            label: 'Batal',
            onPressed: _loading ? () {} : () => Navigator.of(context).pop(),
          ),
          GlassDialogAction(
            label: _loading ? 'Memproses...' : 'Ya, Hapus Akun',
            isDestructive: true,
            onPressed: _loading ? () {} : _handleConfirm,
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardLarge),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.palette.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: context.palette.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hapus Akun',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.palette.error,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tindakan ini tidak dapat dibatalkan. Seluruh data keuangan, transaksi, dan target kamu akan dihapus secara permanen.\n\nMasukkan kata sandi untuk konfirmasi:',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Akun',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Kata sandi wajib diisi untuk konfirmasi'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(
                    color: context.palette.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: destructiveButtonStyle(context),
          onPressed: _loading ? null : _handleConfirm,
          child: _loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(context.palette.onError),
                  ),
                )
              : const Text('Ya, Hapus Akun'),
        ),
      ],
    );
  }
}
