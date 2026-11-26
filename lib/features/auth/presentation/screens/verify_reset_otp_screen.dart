import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    hide GlassQuality;

import '../../../../core/constants/glass_design_tokens.dart';
import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../models/password_reset_flow.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class VerifyResetOtpScreen extends ConsumerStatefulWidget {
  const VerifyResetOtpScreen({super.key, required this.args});

  final PasswordResetOtpArgs args;

  @override
  ConsumerState<VerifyResetOtpScreen> createState() =>
      _VerifyResetOtpScreenState();
}

class _VerifyResetOtpScreenState extends ConsumerState<VerifyResetOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  late DateTime _expiresAt;
  late DateTime _resendAvailableAt;
  bool _submitting = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setDeadlines(
      expiresInSeconds: widget.args.expiresInSeconds,
      resendAfterSeconds: widget.args.resendAfterSeconds,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _setDeadlines({
    required int expiresInSeconds,
    required int resendAfterSeconds,
  }) {
    _expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    _resendAvailableAt = DateTime.now().add(
      Duration(seconds: resendAfterSeconds),
    );
  }

  int _secondsRemaining(DateTime deadline) =>
      deadline.difference(DateTime.now()).inSeconds.clamp(0, 3600);

  String _formatCountdown(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  String get _otp => _controllers.map((controller) => controller.text).join();

  void _handleDigitChange(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      final pasted = digits.substring(0, digits.length > 6 ? 6 : digits.length);
      for (var i = 0; i < _controllers.length; i++) {
        _controllers[i].text = i < pasted.length ? pasted[i] : '';
      }
      final nextIndex = pasted.length >= 6 ? 5 : pasted.length;
      _focusNodes[nextIndex].requestFocus();
      setState(() => _error = null);
      return;
    }

    if (digits.isEmpty) {
      if (index > 0) _focusNodes[index - 1].requestFocus();
      return;
    }

    _controllers[index].value = TextEditingValue(
      text: digits,
      selection: const TextSelection.collapsed(offset: 1),
    );
    setState(() => _error = null);
    if (index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
  }

  Future<void> _verify() async {
    if (_submitting) return;
    if (_otp.length != 6) {
      setState(() => _error = 'Masukkan kode OTP 6 digit.');
      return;
    }
    if (_secondsRemaining(_expiresAt) == 0) {
      setState(
        () => _error = 'Kode kedaluwarsa. Kirim ulang kode setelah cooldown.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final resetToken = await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetOtp(email: widget.args.email, otp: _otp);
      if (!mounted) return;
      context.go(
        AppRoutes.resetPassword,
        extra: PasswordResetTokenArgs(resetToken: resetToken),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.statusCode == 429
              ? 'Terlalu banyak percobaan. Coba lagi setelah beberapa saat.'
              : e.message,
        );
      }
    } on UnsupportedError catch (e) {
      if (mounted) setState(() => _error = e.message?.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Verifikasi gagal. Periksa koneksi.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _secondsRemaining(_resendAvailableAt) > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final info = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: widget.args.email);
      if (!mounted) return;
      setState(() {
        _setDeadlines(
          expiresInSeconds: info.expiresInSeconds,
          resendAfterSeconds: info.resendAfterSeconds,
        );
        for (final controller in _controllers) {
          controller.clear();
        }
      });
      _focusNodes.first.requestFocus();
    } on ApiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.statusCode == 429
              ? 'Terlalu banyak permintaan. Coba lagi setelah beberapa saat.'
              : e.message,
        );
      }
    } on UnsupportedError catch (e) {
      if (mounted) setState(() => _error = e.message?.toString());
    } catch (_) {
      if (mounted) setState(() => _error = 'Tidak dapat mengirim ulang kode.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expiresIn = _secondsRemaining(_expiresAt);
    final resendIn = _secondsRemaining(_resendAvailableAt);
    final useDarkGlass = GlassDesignTokens.isDarkGlass(context);
    return AuthScaffold(
      appBar: AppAdaptiveAppBar(
        title: const Text(AppStrings.verifyEmailTitle),
        leading: AppAdaptiveIconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.verifyEmailTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Masukkan kode 6 digit yang dikirim ke email ',
                ),
                TextSpan(
                  text: widget.args.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' jika alamat tersebut terdaftar.'),
              ],
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Semantics(
            label: 'Kode OTP, 6 digit',
            child: Row(
              children: List.generate(6, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                    child: useDarkGlass
                        ? GlassTextField(
                            autofocus: index == 0,
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textInputAction: index == 5
                                ? TextInputAction.done
                                : TextInputAction.next,
                            height: 54,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            useOwnLayer: true,
                            surfaceStyle: GlassSurfaceStyle.glass,
                            settings: GlassDesignTokens.darkInputSettings(context),
                            shape: const LiquidRoundedRectangle(
                              borderRadius: 12,
                            ),
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) =>
                                _handleDigitChange(index, value),
                            onSubmitted: (_) {
                              if (index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              }
                            },
                          )
                        : TextField(
                            autofocus: index == 0,
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            textInputAction: index == 5
                                ? TextInputAction.done
                                : TextInputAction.next,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              counterText: '',
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (value) =>
                                _handleDigitChange(index, value),
                            onSubmitted: (_) {
                              if (index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              }
                            },
                          ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            expiresIn == 0
                ? 'Kode sudah kedaluwarsa.'
                : 'Kode kedaluwarsa dalam ${_formatCountdown(expiresIn)}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: expiresIn == 0 ? context.palette.error : context.palette.onSurfaceVariant,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            AuthErrorBanner(message: _error!),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: AppStrings.verifyOtp,
            isLoading: _submitting,
            onPressed: _submitting ? null : _verify,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _resending || resendIn > 0 ? null : _resend,
              child: Text(
                _resending
                    ? 'Mengirim...'
                    : resendIn > 0
                    ? '${AppStrings.resendOtp} (${_formatCountdown(resendIn)})'
                    : AppStrings.resendOtp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
