import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// Golden regresi visual No.4 pada viewport phone 390x844.
void main() {
  testWidgets('Instruments golden', (WidgetTester tester) async {
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
    expect(find.text(AppStrings.salaryTitle), findsOneWidget);

    final salaryButton = find.widgetWithText(
      ElevatedButton,
      AppStrings.continueButton,
    );
    await tester.ensureVisible(salaryButton);
    await tester.pumpAndSettle();
    await tester.tap(salaryButton);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.instrumentsTitle), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/instruments_screen.png'),
    );

    // Scroll ke panel detail fee untuk verifikasi visualnya.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/instruments_detail.png'),
    );
  });
}
