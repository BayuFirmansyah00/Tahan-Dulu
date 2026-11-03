import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// Golden regresi visual daftar akun pada viewport phone 390x844.
void main() {
  testWidgets('Accounts golden', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await initializeDateFormatting('id_ID');

    await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    Future<void> tapVisible(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pump();
    }

    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'bayu@email.com');
    await tester.enterText(loginFields.at(1), 'rahasia123');
    await tester.pump();
    await tapVisible(find.text(AppStrings.loginWithEmail));
    await tester.pumpAndSettle();
    // Langsung ke Dashboard; tutup popup onboarding bila muncul.
    if (find.text(AppStrings.onboardingPopupLater).evaluate().isNotEmpty) {
      await tapVisible(find.text(AppStrings.onboardingPopupLater));
      await tester.pumpAndSettle();
    }
    await tapVisible(find.text(AppStrings.totalBalanceTitle));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.accountsTitle), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/accounts_screen.png'),
    );
  });
}
