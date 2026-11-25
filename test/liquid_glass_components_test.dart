import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:tahan_dulu/core/constants/glass_design_tokens.dart';
import 'package:tahan_dulu/core/theme/app_theme.dart';
import 'package:tahan_dulu/core/widgets/app_adaptive_controls.dart';
import 'package:tahan_dulu/core/widgets/app_glass_bottom_sheet.dart';
import 'package:tahan_dulu/core/widgets/app_glass_button.dart';
import 'package:tahan_dulu/core/widgets/app_glass_card.dart';
import 'package:tahan_dulu/core/widgets/app_glass_dialog.dart';
import 'package:tahan_dulu/core/widgets/app_glass_floating_action_button.dart';

void main() {
  group('AppGlassButton Widget Tests', () {
    testWidgets('Renders primary button as solid emerald CTA and handles tap', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppGlassButton(
                label: 'Lanjutkan',
                onPressed: () => tapped = true,
                isPrimary: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Lanjutkan'), findsOneWidget);
      await tester.tap(find.text('Lanjutkan'));
      expect(tapped, isTrue);
    });

    testWidgets('Primary button shows loading spinner and ignores taps', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppGlassButton(
                label: 'Simpan',
                isLoading: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
      await tester.tap(find.byType(CircularProgressIndicator));
      expect(tapped, isFalse);
    });

    testWidgets('Renders secondary button as Material OutlinedButton in Light Mode and GlassButton in Dark Mode', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppGlassButton(
                label: 'Batal',
                isPrimary: false,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Batal'), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(GlassButton), findsNothing);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);

      tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark_btn_app'),
          theme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          builder: (context, child) => GlassTheme(
            data: GlassDesignTokens.darkThemeData,
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: AppGlassButton(
                label: 'Batal',
                isPrimary: false,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Batal'), findsOneWidget);
      expect(find.byType(GlassButton), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('AppGlassIconButton Widget Tests', () {
    testWidgets('Meets minimum 48px touch target and fires onPressed', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppGlassIconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Pengaturan',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AppGlassIconButton);
      expect(buttonFinder, findsOneWidget);
      final size = tester.getSize(buttonFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });
  });

  group('AppGlassCard Widget Tests', () {
    testWidgets('Defaults to solid adaptive card for financial data legibility', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: AppGlassCard(
                child: Text('Rp 5.000.000'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Rp 5.000.000'), findsOneWidget);
      // In solid mode, GlassContainer is not used; standard Container is used.
      expect(find.byType(GlassContainer), findsNothing);
    });

    testWidgets('Floating glass card preserves Material Container in Light Mode and uses GlassContainer in Dark Mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: AppGlassCard(
                isFloatingGlass: true,
                child: Text('Floating Banner'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Floating Banner'), findsOneWidget);
      expect(find.byType(GlassContainer), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark_card_app'),
          theme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          builder: (context, child) => GlassTheme(
            data: GlassDesignTokens.darkThemeData,
            child: child!,
          ),
          home: const Scaffold(
            body: Center(
              child: AppGlassCard(
                isFloatingGlass: true,
                child: Text('Floating Banner'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Floating Banner'), findsOneWidget);
      expect(find.byType(GlassContainer), findsOneWidget);
    });

    testWidgets('Handles onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppGlassCard(
                onTap: () => tapped = true,
                child: const Text('Klik Saya'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Klik Saya'));
      expect(tapped, isTrue);
    });
  });

  group('AppGlassFloatingActionButton Widget Tests', () {
    testWidgets('Extended FAB displays label and icon', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppGlassFloatingActionButton(
                icon: const Icon(Icons.add),
                label: 'Tambah Pos',
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tambah Pos'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.tap(find.text('Tambah Pos'));
      expect(pressed, isTrue);
    });

    testWidgets('Circular FAB renders circular glass button', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppGlassFloatingActionButton(
                icon: const Icon(Icons.mic),
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });
  });

  group('Accessibility & Dialog Fallback Tests', () {
    testWidgets('showAppGlassDialog renders Material AlertDialog on high contrast', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: true),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAppGlassDialog(
                      context: ctx,
                      title: 'Konfirmasi Keluar',
                      message: 'Apakah Anda yakin ingin keluar?',
                      confirmLabel: 'Keluar',
                    );
                  },
                  child: const Text('Buka Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Konfirmasi Keluar'), findsOneWidget);
      expect(find.text('Apakah Anda yakin ingin keluar?'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('showAppGlassBottomSheet renders Material BottomSheet on high contrast', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: true),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showAppGlassBottomSheet(
                      context: ctx,
                      builder: (sheetCtx) => const Text('Isi Sheet'),
                    );
                  },
                  child: const Text('Buka Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Isi Sheet'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    test('GlassDesignTokens verify motion and accessibility helpers', () {
      expect(GlassDesignTokens.lightSurfaceOpacity, 0.72);
      expect(GlassDesignTokens.darkSurfaceOpacity, 0.86);
      expect(GlassDesignTokens.solidSurfaceOpacity, 1.0);
      expect(GlassDesignTokens.radiusCapsule.topLeft.x, 32.0);
    });

    testWidgets('AppAdaptive controls render Material in Light Mode and Liquid Glass in Dark Mode', (
      tester,
    ) async {
      bool switchValue = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                AppAdaptiveSwitch(
                  value: switchValue,
                  onChanged: (v) => switchValue = v,
                ),
                AppAdaptiveFilterChip(
                  label: 'Semua',
                  selected: true,
                  onTap: () {},
                ),
                AppAdaptiveMenuButton<String>(
                  options: const [
                    AppMenuOption(value: 'a', label: 'Opsi A'),
                  ],
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(GlassSwitch), findsNothing);
      expect(find.byType(GlassChip), findsNothing);
      expect(find.byType(GlassPullDownButton), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark_adaptive_app'),
          theme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          builder: (context, child) => GlassTheme(
            data: GlassDesignTokens.darkThemeData,
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              children: [
                AppAdaptiveSwitch(
                  value: switchValue,
                  onChanged: (v) => switchValue = v,
                ),
                AppAdaptiveFilterChip(
                  label: 'Semua',
                  selected: true,
                  onTap: () {},
                ),
                AppAdaptiveMenuButton<String>(
                  options: const [
                    AppMenuOption(value: 'a', label: 'Opsi A'),
                  ],
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassSwitch), findsOneWidget);
      expect(find.byType(GlassChip), findsOneWidget);
      expect(find.byType(GlassPullDownButton), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });
  });
}
