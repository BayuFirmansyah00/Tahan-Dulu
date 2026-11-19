import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';
import 'package:tahan_dulu/core/routing/app_router.dart';
import 'package:tahan_dulu/core/routing/app_routes.dart';
import 'package:tahan_dulu/data/repositories/auth_repository.dart';
import 'package:tahan_dulu/features/auth/presentation/models/password_reset_flow.dart';
import 'package:tahan_dulu/features/auth/presentation/providers/auth_controller.dart';
import 'package:tahan_dulu/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tahan_dulu/features/auth/presentation/screens/verify_reset_otp_screen.dart';

class _RecordingAuthRepository extends MockAuthRepository {
  final requestedEmails = <String>[];

  @override
  Future<PasswordResetRequestInfo> requestPasswordReset({
    required String email,
  }) async {
    requestedEmails.add(email);
    return const PasswordResetRequestInfo(
      expiresInSeconds: 300,
      resendAfterSeconds: 0,
    );
  }
}

GoRouter _router() {
  return GoRouter(
    initialLocation: AppRoutes.forgotPassword,
    routes: [
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyResetOtp,
        redirect: (context, state) => hasValidPasswordResetOtpArgs(state.extra)
            ? null
            : AppRoutes.forgotPassword,
        builder: buildVerifyResetOtpRoute,
      ),
    ],
  );
}

void main() {
  testWidgets('displays and reuses the normalized email on a small viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _RecordingAuthRepository();
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      '  contoh@gmail.com  ',
    );
    final sendOtpButton = find.ancestor(
      of: find.text(AppStrings.sendOtp),
      matching: find.byType(ElevatedButton),
    );
    await tester.ensureVisible(sendOtpButton);
    await tester.tap(sendOtpButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text(AppStrings.emailInvalid), findsNothing);
    expect(tester.takeException(), isNull);
    expect(repository.requestedEmails, ['contoh@gmail.com']);
    expect(find.byType(VerifyResetOtpScreen), findsOneWidget);
    expect(
      find.textContaining(
        'Masukkan kode 6 digit yang dikirim ke email contoh@gmail.com jika alamat tersebut terdaftar.',
      ),
      findsOneWidget,
    );

    final introText = tester.widget<Text>(
      find.textContaining('Masukkan kode 6 digit yang dikirim ke email'),
    );
    final emailSpan = (introText.textSpan! as TextSpan).children!
        .whereType<TextSpan>()
        .firstWhere((span) => span.text == 'contoh@gmail.com');
    expect(emailSpan.style?.fontWeight, FontWeight.w600);
    expect(find.textContaining('Kode kedaluwarsa dalam'), findsOneWidget);
    expect(find.textContaining('Kode berlaku'), findsNothing);
    expect(tester.takeException(), isNull);

    final resendButton = find.ancestor(
      of: find.text(AppStrings.resendOtp),
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(resendButton);
    await tester.tap(resendButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.requestedEmails, [
      'contoh@gmail.com',
      'contoh@gmail.com',
    ]);

    expect(tester.takeException(), isNull);
  });

  testWidgets('returns to forgot password if OTP route has no valid email', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    router.go(
      AppRoutes.verifyResetOtp,
      extra: const PasswordResetOtpArgs(
        email: 'invalid-email',
        expiresInSeconds: 300,
        resendAfterSeconds: 60,
      ),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.byType(VerifyResetOtpScreen), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.forgotPassword,
    );
    expect(tester.takeException(), isNull);
  });
}
