import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// Golden regresi visual No.5 pada viewport phone 390x844.
void main() {
  testWidgets('Expenses golden', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'bayu@email.com');
    await tester.enterText(loginFields.at(1), 'rahasia123');
    await tester.pump();
    await tester.tap(find.text(AppStrings.loginWithEmail));
    await tester.pumpAndSettle();
    // Langsung ke Dashboard; tutup popup onboarding bila muncul.
    if (find.text(AppStrings.onboardingPopupLater).evaluate().isNotEmpty) {
      await tester.tap(find.text(AppStrings.onboardingPopupLater));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(AppStrings.navReports));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.dashboardSeeReport));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/expenses_screen.png'),
    );
  });
}
