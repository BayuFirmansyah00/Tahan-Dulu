import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/constants/app_assets.dart';
import 'package:tahan_dulu/core/widgets/app_image_icon.dart';

void main() {
  group('AppBackButton & Navigation Icon Tests', () {
    testWidgets('AppBackButton renders IconButton with AppImageIcon navBack', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(),
            ),
          ),
        ),
      );

      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(AppImageIcon), findsOneWidget);

      final appImageIcon = tester.widget<AppImageIcon>(find.byType(AppImageIcon));
      expect(appImageIcon.assetPath, AppAssets.navBack);
      expect(appImageIcon.size, 24.0);
      expect(appImageIcon.semanticLabel, 'Kembali');
      expect(appImageIcon.fallbackIcon, Icons.arrow_back_rounded);
    });

    testWidgets('AppBackButton custom onPressed is triggered when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: AppBackButton(
                onPressed: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('AppBackButton default onPressed navigates back', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          leading: const AppBackButton(),
                        ),
                        body: const Text('Second Screen'),
                      ),
                    ),
                  );
                },
                child: const Text('Go to Second'),
              ),
            ),
          ),
        ),
      );

      // Navigate to second screen
      await tester.tap(find.text('Go to Second'));
      await tester.pumpAndSettle();
      expect(find.text('Second Screen'), findsOneWidget);

      // Tap AppBackButton
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      // Verified back on first screen
      expect(find.text('Second Screen'), findsNothing);
      expect(find.text('Go to Second'), findsOneWidget);
    });

    testWidgets('AppBackButton supports custom size and color', (tester) async {
      const customColor = Color(0xFF10B981);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: const AppBackButton(
                size: 28.0,
                color: customColor,
                tooltip: 'Kembali ke Beranda',
              ),
            ),
          ),
        ),
      );

      final appImageIcon = tester.widget<AppImageIcon>(find.byType(AppImageIcon));
      expect(appImageIcon.size, 28.0);
      expect(appImageIcon.color, customColor);
      expect(appImageIcon.semanticLabel, 'Kembali ke Beranda');
    });
  });
}
