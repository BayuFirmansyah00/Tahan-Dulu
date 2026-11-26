import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    hide GlassQuality;

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../utils/profile_ui.dart';

/// Layar verifikasi OTP 6 digit via email sebelum penghapusan akun permanen.
class DeleteAccountOtpScreen extends ConsumerStatefulWidget {
  const DeleteAccountOtpScreen({
    super.key,
    this.password,
    this.googleIdToken,
    this.autoRequestOnInit = true,
  });

  final String? password;
  final String? googleIdToken;

  /// Dapat dimatikan pada unit/widget test bila ingin mengontrol request manual.
  final bool autoRequestOnInit;

  @override
  ConsumerState<DeleteAccountOtpScreen> createState() =>
      _DeleteAccountOtpScreenState();
}

class _DeleteAccountOtpScreenState
    extends ConsumerState<DeleteAccountOtpScreen> {
  static const int _otpLength = 6;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _requestingOtp = false;
  bool _verifying = false;
  bool _deleting = false;
  String? _errorText;

  int _expiresRemainingSeconds = 0;
  int _resendCooldownSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    if (widget.autoRequestOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _requestOtp();
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text.trim()).join();

  void _startTimers({
    required int expiresInSeconds,
    required int resendAfterSeconds,
  }) {
    _countdownTimer?.cancel();
    setState(() {
      _expiresRemainingSeconds = expiresInSeconds;
      _resendCooldownSeconds = resendAfterSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_expiresRemainingSeconds <= 0 && _resendCooldownSeconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_expiresRemainingSeconds > 0) {
          _expiresRemainingSeconds -= 1;
        }
        if (_resendCooldownSeconds > 0) {
          _resendCooldownSeconds -= 1;
        }
      });
    });
  }

  String _formatCountdown(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _requestOtp() async {
    if (_requestingOtp || _resendCooldownSeconds > 0) return;
    setState(() {
      _requestingOtp = true;
      _errorText = null;
    });

    try {
      final info = await ref
          .read(authControllerProvider.notifier)
          .requestDeleteAccountOtp();

      if (!mounted) return;
      for (final c in _controllers) {
        c.clear();
      }
      _startTimers(
        expiresInSeconds: info.expiresInSeconds,
        resendAfterSeconds: info.resendAfterSeconds,
      );
      _focusNodes.first.requestFocus();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
      if (e.statusCode == 429) {
        _startTimers(
          expiresInSeconds: _expiresRemainingSeconds,
          resendAfterSeconds: 60,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Gagal mengirim kode OTP ke email Anda. Coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _requestingOtp = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    setState(() => _errorText = null);

    // Tangani paste 6 digit sekaligus
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 1) {
      for (var i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < digitsOnly.length ? digitsOnly[i] : '';
      }
      final targetIndex =
          digitsOnly.length >= _otpLength ? _otpLength - 1 : digitsOnly.length;
      _focusNodes[targetIndex].requestFocus();
      setState(() {});
      return;
    }

    if (digitsOnly.isNotEmpty) {
      _controllers[index].text = digitsOnly;
      _controllers[index].selection =
          const TextSelection.collapsed(offset: 1);
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verifyAndDelete() async {
    if (_verifying || _deleting) return;

    final otp = _otpValue;
    if (otp.length != _otpLength || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() {
        _errorText = 'Masukkan 6 digit kode OTP yang dikirim ke email Anda.';
      });
      return;
    }

    if (widget.autoRequestOnInit && _expiresRemainingSeconds == 0) {
      setState(() {
        _errorText = 'Kode OTP telah kedaluwarsa. Silakan kirim ulang kode baru.';
      });
      return;
    }

    setState(() {
      _verifying = true;
      _errorText = null;
    });

    String deletionToken;
    try {
      deletionToken = await ref
          .read(authControllerProvider.notifier)
          .verifyDeleteAccountOtp(otp);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _errorText = e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _errorText = 'Gagal memverifikasi kode OTP. Coba lagi.';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _verifying = false);

    // Konfirmasi eksplisit terakhir sebelum penghapusan akun permanen
    final confirmed = await showConfirmDialog(
      context: context,
      assetPath: AppAssets.setDeleteAccount,
      icon: Icons.delete_forever_rounded,
      iconForeground: context.palette.error,
      iconBackground: context.palette.errorContainer,
      title: 'Konfirmasi Akhir Penghapusan Akun',
      message:
          'Kode OTP berhasil diverifikasi. Apakah Anda benar-benar yakin ingin menghapus akun secara permanen? Semua data transaksi, target, dan anggaran akan hilang dan tidak dapat dipulihkan.',
      cancelLabel: 'Batal',
      confirmLabel: 'Ya, Hapus Akun Permanen',
      confirmColor: context.palette.error,
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _deleting = true;
      _errorText = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(
            password: widget.password,
            googleIdToken: widget.googleIdToken,
            deletionToken: deletionToken,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun kamu telah berhasil dihapus.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.login);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _errorText = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _errorText = 'Gagal menghapus akun: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final email = auth.user?.email ?? 'email terdaftar Anda';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = _requestingOtp || _verifying || _deleting;

    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);

    return GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: useDarkGlass,
        appBar: AppAdaptiveAppBar(
          backgroundColor: useDarkGlass ? null : Colors.transparent,
          title: const Text('Verifikasi OTP Hapus Akun'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FloatingGlass(
                  radius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: context.palette.errorContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 30,
                            color: context.palette.error,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Konfirmasi Penghapusan Akun',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan kode OTP 6 digit yang telah kami kirimkan ke:\n$email',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.78)
                                        : AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                        ),
                        if (_expiresRemainingSeconds > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.palette.errorContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Berlaku ${_formatCountdown(_expiresRemainingSeconds)}',
                              style: TextStyle(
                                color: context.palette.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_otpLength, (index) {
                    return SizedBox(
                      width: 46,
                      height: 56,
                      child: useDarkGlass
                          ? GlassTextField(
                              key: Key('delete_otp_box_$index'),
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              enabled: !busy,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              height: 56,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                              useOwnLayer: true,
                              surfaceStyle: GlassSurfaceStyle.glass,
                              settings: GlassDesignTokens.darkInputSettings(context),
                              shape: const LiquidRoundedRectangle(
                                borderRadius: 14,
                              ),
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) => _onDigitChanged(index, v),
                            )
                          : TextField(
                              key: Key('delete_otp_box_$index'),
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              enabled: !busy,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.85),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.12),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: context.palette.error,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              onChanged: (v) => _onDigitChanged(index, v),
                            ),
                    );
                  }),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.palette.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.palette.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: _deleting
                      ? 'Menghapus Akun...'
                      : _verifying
                          ? 'Memverifikasi OTP...'
                          : 'Verifikasi & Lanjutkan',
                  isLoading: _verifying || _deleting,
                  onPressed: busy ? null : _verifyAndDelete,
                ),
                const SizedBox(height: 12),
                AppAdaptiveOutlinedButton(
                  onPressed: (_requestingOtp ||
                          _resendCooldownSeconds > 0 ||
                          _verifying ||
                          _deleting)
                      ? null
                      : _requestOtp,
                  borderRadius: 14,
                  label: _requestingOtp
                      ? 'Mengirim Kode OTP...'
                      : _resendCooldownSeconds > 0
                          ? 'Kirim Ulang dalam ${_resendCooldownSeconds}d'
                          : 'Kirim Ulang Kode OTP',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
