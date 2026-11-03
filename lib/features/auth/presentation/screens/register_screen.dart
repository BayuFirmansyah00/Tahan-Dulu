import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Register: Nama, Email, Password, Konfirmasi Password.
/// Sukses -> /onboarding/salary (pengguna baru wajib onboarding).
/// "Masuk" kembali ke Login.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _goDashboard(AuthState? prev, AuthState next) {
    if (next.status == AuthStatus.authenticated) {
      // Pengguna baru (is_onboarded=false) wajib menyelesaikan onboarding.
      // Pengguna lama yang sudah migrasi (is_onboarded=true) langsung dashboard.
      final isOnboarded = next.user?.isOnboarded ?? false;
      context.go(isOnboarded ? AppRoutes.dashboard : AppRoutes.onboardingSalary);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, _goDashboard);
    final authState = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return AuthScaffold(
      appBar: AppBar(title: const Text(AppStrings.registerTitle)),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.registerSubtitle, style: textTheme.bodyMedium),
            const SizedBox(height: 20),
            if (authState.errorMessage != null) ...[
              AuthErrorBanner(message: authState.errorMessage!),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: _nameController,
              label: AppStrings.fullName,
              hint: AppStrings.fullNameHint,
              validator: (v) => Validators.required(v, AppStrings.nameRequired),
            ),
            if (authState.hasFieldError('name')) ...[
              const SizedBox(height: 6),
              _FieldError(text: authState.fieldErrors!['name']!.first),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: AppStrings.email,
              hint: AppStrings.emailHint,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => Validators.email(
                v,
                requiredMessage: AppStrings.emailRequired,
                invalidMessage: AppStrings.emailInvalid,
              ),
            ),
            if (authState.hasFieldError('email')) ...[
              const SizedBox(height: 6),
              _FieldError(text: authState.fieldErrors!['email']!.first),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              label: AppStrings.password,
              hint: '••••••••',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) =>
                  Validators.required(v, AppStrings.passwordRequired),
            ),
            if (authState.hasFieldError('password')) ...[
              const SizedBox(height: 6),
              _FieldError(text: authState.fieldErrors!['password']!.first),
            ],
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmController,
              label: AppStrings.confirmPassword,
              hint: '••••••••',
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                final empty = Validators.required(
                  v,
                  AppStrings.confirmRequired,
                );
                if (empty != null) return empty;
                if (v != _passwordController.text) {
                  return AppStrings.confirmMismatch;
                }
                return null;
              },
            ),
            if (authState.hasFieldError('password_confirmation')) ...[
              const SizedBox(height: 6),
              _FieldError(text: authState.fieldErrors!['password_confirmation']!.first),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: AppStrings.registerButton,
              isLoading: _submitting,
              onPressed: authState.isLoading ? null : _submit,
            ),
            const SizedBox(height: 8),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(AppStrings.haveAccount, style: textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text(
                      AppStrings.loginLink,
                      style: TextStyle(decoration: TextDecoration.underline),
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

class _FieldError extends StatelessWidget {
  const _FieldError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
    );
  }
}
