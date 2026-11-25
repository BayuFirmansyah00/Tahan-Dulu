import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/core/theme/app_colors.dart';
import 'package:tahan_dulu/features/dev/presentation/glass_poc_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    Brightness brightness = Brightness.light,
    bool highContrast = false,
  }) {
    return MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ),
      ),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(393, 852),
          highContrast: highContrast,
        ),
        child: const GlassPocScreen(),
      ),
    );
  }

  group('GlassPocScreen Tests', () {
    testWidgets('renders all three comparison samples and background scene', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('True Clear Liquid Glass POC'), findsOneWidget);

      // Verify background scene is rendered
      expect(find.byKey(const Key('background_scene')), findsOneWidget);

      // Verify all 3 samples are present
      expect(find.byKey(const Key('sample_a_card')), findsOneWidget);
      expect(find.byKey(const Key('sample_b_card')), findsOneWidget);
      expect(find.byKey(const Key('sample_c_card')), findsOneWidget);

      // Verify sample badges
      expect(find.text('SAMPEL A'), findsOneWidget);
      expect(find.text('SAMPEL B'), findsOneWidget);
      expect(find.text('SAMPEL C'), findsOneWidget);

      // Verify sample labels and statuses
      expect(find.text('Sampel A: Kaca Eksisting (Baseline Milky/Opaque)'), findsOneWidget);
      expect(find.text('Sampel B: True Clear Glass (Tuned Toolkit)'), findsOneWidget);
      expect(find.text('Sampel C: Optical Lens Glass (iOS 27 Fragment Shader)'), findsOneWidget);
    });

    testWidgets('toggles between geometric and financial background scenes', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initial scene is geometric
      expect(find.text('TAHAN DULU OPTICAL TEST SCENE'), findsNothing); // Drawn via custom painter

      // Tap toggle scene button
      await tester.tap(find.byKey(const Key('toggle_scene_btn')));
      await tester.pumpAndSettle();

      // Now financial scene is active
      expect(find.text('TOTAL KEKAYAAN BERSIH'), findsOneWidget);
      expect(find.text('Rp 87.450.000'), findsOneWidget);

      // Tap again to toggle back
      await tester.tap(find.byKey(const Key('toggle_scene_btn')));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL KEKAYAAN BERSIH'), findsNothing);
    });

    testWidgets('switches to Interactive Sandbox tab and adjusts sliders', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Sandbox chip
      await tester.tap(find.text('Interactive Sandbox'));
      await tester.pumpAndSettle();

      expect(find.text('Parameter Tuning Kaca Real-time'), findsOneWidget);
      expect(find.text('Live Preview Permukaan Kaca:'), findsOneWidget);
      expect(find.text('Enable Optical Refraction'), findsOneWidget);

      // Verify sliders exist
      expect(find.byType(Slider), findsNWidgets(4));

      // Drag blur slider
      await tester.drag(find.byType(Slider).first, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Toggle refraction switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
    });

    testWidgets('switches to GPU & Engine tab and displays architecture report', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap GPU & Engine chip
      await tester.tap(find.text('GPU & Engine'));
      await tester.pumpAndSettle();

      expect(find.text('Arsitektur GPU & Rendering'), findsOneWidget);
      expect(find.text('3.44.4 (channel stable)'), findsOneWidget);
      expect(find.text('Impeller (Vulkan 1.1+) / Skia Fallback'), findsOneWidget);
      expect(find.textContaining('Decision A: Keep existing 3.44.4'), findsOneWidget);
    });

    testWidgets('renders in dark mode without visual or layout exceptions', (tester) async {
      await tester.pumpWidget(buildTestWidget(brightness: Brightness.dark));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sample_a_card')), findsOneWidget);
      expect(find.byKey(const Key('sample_b_card')), findsOneWidget);
      expect(find.byKey(const Key('sample_c_card')), findsOneWidget);
    });
  });
}
