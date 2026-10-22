import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahan_dulu/app.dart';
import 'package:tahan_dulu/core/constants/app_strings.dart';

/// Entry flow: Splash -> Login.
void main() {
  testWidgets('Splash shows logo, tagline, loading then goes to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TahanDuluApp()));

    expect(find.text(AppStrings.splashTagline), findsOneWidget);
    expect(find.text(AppStrings.splashLoading), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    expect(find.text(AppStrings.loginHeadline), findsOneWidget);
  });
}
