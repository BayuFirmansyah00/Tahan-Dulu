import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

/// Login sesuai desain: ilustrasi, headline, tombol Google + form email,
/// tombol primer dark navy, link ke Register.
/// Sukses (mock) -> /onboarding.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submittingEmail = false;
  bool _submittingGoogle = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goOnboarding(AuthState? prev, AuthState next) {
    if (next.status == AuthStatus.authenticated) {
      context.go(AppRoutes.onboardingSalary);
    }
  }

  Future<void> _submitEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submittingEmail = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .loginWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } finally {
      if (mounted) setState(() => _submittingEmail = false);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() => _submittingGoogle = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } finally {
      if (mounted) setState(() => _submittingGoogle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, _goOnboarding);
    final authState = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return AuthScaffold(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(
                AppAssets.loginIllustration,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.loginHeadline,
              style: textTheme.headlineMedium?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 8),
            Text(AppStrings.loginSubtitle, style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            _GoogleButton(
              isLoading: _submittingGoogle,
              onPressed: authState.isLoading ? null : _submitGoogle,
            ),
            const SizedBox(height: 20),
            if (authState.errorMessage != null) ...[
              AuthErrorBanner(message: authState.errorMessage!),
              const SizedBox(height: 16),
            ],
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 20),
            AppButton(
              label: AppStrings.loginWithEmail,
              icon: Icons.email_outlined,
              isLoading: _submittingEmail,
              onPressed: authState.isLoading ? null : _submitEmail,
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(AppStrings.noAccount, style: textTheme.bodyMedium),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text(
                      AppStrings.registerLink,
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Tombol Google: outline abu + teks dark navy + ikon Google lokal.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                children: const [
                  _GoogleBadge(),
                  Text(AppStrings.continueWithGoogle),
                ],
              ),
      ),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.setGoogle,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );
  }
}
