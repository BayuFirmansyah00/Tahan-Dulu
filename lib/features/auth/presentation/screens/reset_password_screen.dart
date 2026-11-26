import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_adaptive_controls.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../models/password_reset_flow.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.args});

  final PasswordResetTokenArgs args;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late String _resetToken;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _submitting = false;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resetToken = widget.args.resetToken;
  }

  @override
  void dispose() {
    _resetToken = '';
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            resetToken: _resetToken,
            password: _passwordController.text,
            passwordConfirmation: _confirmationController.text,
          );
      if (!mounted) return;
      setState(() {
        _completed = true;
        _resetToken = '';
        _passwordController.clear();
        _confirmationController.clear();
      });
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
        setState(() => _error = 'Password gagal disimpan. Periksa koneksi.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBar: AppAdaptiveAppBar(
        title: const Text(AppStrings.resetPasswordTitle),
        leading: AppAdaptiveIconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      child: _completed ? _successView(context) : _formView(context),
    );
  }

  Widget _formView(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.resetPasswordTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Buat password baru dengan minimal 8 karakter.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            AuthErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          AppTextField(
            controller: _passwordController,
            label: AppStrings.password,
            hint: 'Minimal 8 karakter',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Tampilkan password'
                  : 'Sembunyikan password',
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (value) {
              final required = Validators.required(
                value,
                AppStrings.passwordRequired,
              );
              if (required != null) return required;
              if (value!.length < 8) return AppStrings.authPasswordShort;
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirmationController,
            label: AppStrings.confirmPassword,
            hint: 'Ulangi password baru',
            obscureText: _obscureConfirmation,
            suffixIcon: IconButton(
              tooltip: _obscureConfirmation
                  ? 'Tampilkan password'
                  : 'Sembunyikan password',
              onPressed: () =>
                  setState(() => _obscureConfirmation = !_obscureConfirmation),
              icon: Icon(
                _obscureConfirmation
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (value) {
              final required = Validators.required(
                value,
                AppStrings.confirmRequired,
              );
              if (required != null) return required;
              if (value != _passwordController.text) {
                return AppStrings.confirmMismatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: AppStrings.saveNewPassword,
            isLoading: _submitting,
            onPressed: _submitting ? null : _savePassword,
          ),
        ],
      ),
    );
  }

  Widget _successView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.check_circle_outline,
          size: 68,
          color: context.palette.primary,
        ),
        const SizedBox(height: 18),
        Text(
          AppStrings.resetPasswordSuccess,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: AppStrings.backToLogin,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
