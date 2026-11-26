import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app.dart';
import 'core/services/fcm_service.dart';

/// Entry point bersih: init locale IDR, Firebase FCM, LiquidGlassWidgets, lalu jalankan app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait<void>([
    initializeDateFormatting('id_ID'),
    FcmService.initializeFirebase(),
    _initializeLiquidGlass(),
  ]);
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      respectSystemAccessibility: true,
      brightnessResolver: Theme.maybeBrightnessOf,
      child: const ProviderScope(child: TahanDuluApp()),
    ),
  );
}

Future<void> _initializeLiquidGlass() async {
  try {
    await LiquidGlassWidgets.initialize();
  } catch (e) {
    debugPrint('[LiquidGlass] Init fallback: $e');
  }
}
