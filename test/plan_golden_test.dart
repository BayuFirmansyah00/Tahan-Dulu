import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// Golden regresi visual ringkasan rencana pada viewport phone 390x844.
void main() {
  testWidgets('Plan golden', (WidgetTester tester) async {
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

    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'bayu@email.com');
    await tester.enterText(loginFields.at(1), 'rahasia123');
    await tester.pump();
    await tester.tap(find.text(AppStrings.loginWithEmail));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      final next = find.widgetWithText(
        ElevatedButton,
        AppStrings.continueButton,
      );
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
    }

    final done = find.widgetWithText(
      ElevatedButton,
      AppStrings.doneButton,
    );
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.planTitle), findsOneWidget);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/plan_screen.png'),
    );

    // Scroll ke kartu aman & target untuk verifikasi visualnya.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/plan_screen_bottom.png'),
    );
  });
}
