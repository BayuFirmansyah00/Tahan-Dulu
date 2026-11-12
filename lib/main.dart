import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/services/fcm_service.dart';

/// Entry point bersih: init locale IDR, Firebase FCM, lalu jalankan app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await FcmService.initializeFirebase();
  runApp(const ProviderScope(child: TahanDuluApp()));
}
