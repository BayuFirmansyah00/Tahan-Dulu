import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/theme/app_theme.dart';
import 'package:tahan_dulu/core/theme/glass.dart';
import 'package:tahan_dulu/core/widgets/app_bottom_navigation_bar.dart';
import 'package:tahan_dulu/features/transactions/presentation/screens/transaction_record_method_screen.dart';

void main() {
  for (final width in [320.0, 360.0, 393.0, 412.0, 768.0]) {
    for (final dark in [false, true]) {
      testWidgets('Pemilih metode dan navigasi pada ${width}dp, gelap=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var tapped = -1;
        var inset = 0.0;
        Widget app() => ProviderScope(
          child: MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.6),
                disableAnimations: true,
                highContrast: true,
                viewInsets: EdgeInsets.only(bottom: inset),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: const TransactionRecordMethodScreen(),
              bottomNavigationBar: AppBottomNavigationBar(
                currentIndex: 0,
                onTap: (i) => tapped = i,
              ),
            ),
          ),
        );
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Input Manual'), findsOneWidget);
        final record = find.byKey(const Key('record_button'));
        expect(tester.getSize(record).shortestSide, greaterThanOrEqualTo(48));
        expect(find.bySemanticsLabel('Catat'), findsOneWidget);
        await tester.tap(record);
        expect(tapped, 2);
        expect(find.byType(BackdropFilter), findsNothing);
        expect(Glass.motion(tester.element(record)), Duration.zero);
        inset = 280;
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(record, findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
