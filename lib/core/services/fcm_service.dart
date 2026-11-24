import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/dashboard_providers.dart';
import '../../data/repositories/fcm_token_repository.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../firebase_options.dart';
import '../routing/app_routes.dart';
import '../routing/notification_deep_link.dart';

/// Handler pesan FCM saat aplikasi berada di background atau terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {
    // Abaikan di platform/test yang tidak menyediakan plugin Firebase.
  }
}

/// Pengelola lifecycle Firebase Cloud Messaging & notifikasi lokal foreground.
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  static const String androidChannelId = 'tahan_dulu_notifications';
  static const String androidChannelName = 'Notifikasi TahanDulu';
  static const String androidChannelDescription =
      'Pengingat gaji, tagihan, anggaran, tabungan, dan Tahan Dulu.';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  ProviderContainer? _container;
  bool _listenersAttached = false;
  bool _localInitialized = false;
  bool _permissionRequested = false;
  String? _lastSyncedToken;
  String? _lastSyncedUserId;
  Map<String, dynamic>? _pendingData;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  /// Inisialisasi Firebase hanya di platform Android yang terkonfigurasi.
  static Future<void> initializeFirebase() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      if (kDebugMode) {
        debugPrint(
          '[FCM] Firebase initialized: apps=${Firebase.apps.length}, projectId=${DefaultFirebaseOptions.android.projectId}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] Firebase init failed: $e');
      }
      // Aplikasi tetap berjalan meski Firebase gagal diinisialisasi.
    }
  }

  /// Menghubungkan listener FCM dengan Riverpod [ProviderContainer] root app.
  void attach(ProviderContainer container) {
    _container = container;
    if (_listenersAttached || Firebase.apps.isEmpty) {
      return;
    }
    _listenersAttached = true;

    unawaited(_initLocalNotifications());
    _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _onOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);
    _onTokenRefreshSub =
        // Tetap gunakan token registrasi FCM untuk target FCM HTTP v1 `message.token`.
        // ignore: deprecated_member_use
        FirebaseMessaging.instance.onTokenRefresh.listen(_syncTokenString);

    unawaited(_checkInitialMessage());
  }

  /// Sinkronisasi token FCM & konsumsi deep-link tertunda setelah user login.
  Future<void> onAuthenticated() async {
    await syncToken();
    drainPendingDeepLink();
  }

  /// Minta izin notifikasi dan kirim token FCM aktif ke backend Laravel.
  Future<void> syncToken() async {
    final container = _container;
    if (container == null || Firebase.apps.isEmpty) return;

    final authState = container.read(authControllerProvider);
    if (authState.status != AuthStatus.authenticated) return;

    try {
      if (!_permissionRequested) {
        _permissionRequested = true;
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (kDebugMode) {
          debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
        }
      }

      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (kDebugMode) {
        debugPrint('[FCM] Token obtained: available=${token != null && token.isNotEmpty}, len=${token?.length ?? 0}');
      }
      if (token != null && token.isNotEmpty) {
        await _syncTokenString(token);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] syncToken error: $e');
      }
      // Gagal sync FCM tidak boleh memblokir alur login atau dashboard.
    }
  }

  /// Hapus registrasi token perangkat dari backend sebelum auth token dihapus.
  Future<void> unregisterBeforeLogout(FcmTokenRepository repository) async {
    String? token = _lastSyncedToken;
    if ((token == null || token.isEmpty) && Firebase.apps.isNotEmpty) {
      try {
        // ignore: deprecated_member_use
        token = await FirebaseMessaging.instance.getToken();
      } catch (_) {}
    }

    if (token != null && token.isNotEmpty) {
      try {
        await repository.unregisterToken(token);
      } catch (_) {
        // Logout lokal tetap dilanjutkan walau request delete token gagal.
      }
    }

    _lastSyncedToken = null;
    _lastSyncedUserId = null;
    _pendingData = null;
  }

  Future<void> _initLocalNotifications() async {
    if (_localInitialized) return;
    _localInitialized = true;

    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotifications.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          androidChannelId,
          androidChannelName,
          description: androidChannelDescription,
          importance: Importance.high,
        ),
      );

      final launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          launchDetails?.notificationResponse != null) {
        _handleLocalNotificationTap(launchDetails!.notificationResponse!);
      }
    } catch (_) {
      // Abaikan jika plugin lokal tidak tersedia (mis. di environment test).
    }
  }

  Future<void> _checkInitialMessage() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleRemoteMessageTap(initial);
      }
    } catch (_) {}
  }

  Future<void> _syncTokenString(String token) async {
    final container = _container;
    if (container == null || token.trim().isEmpty) return;

    final authState = container.read(authControllerProvider);
    if (authState.status != AuthStatus.authenticated) return;

    final currentUserId = authState.user?.id;
    if (_lastSyncedToken == token && _lastSyncedUserId == currentUserId) {
      return;
    }

    try {
      await container.read(fcmTokenRepositoryProvider).registerToken(
            token,
            platform: 'android',
            deviceName: defaultTargetPlatform.name,
          );
      _lastSyncedToken = token;
      _lastSyncedUserId = currentUserId;
    } catch (_) {
      // Akan dicoba lagi saat onAuthenticated / onTokenRefresh berikutnya.
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final container = _container;
    if (container == null) return;

    // Segarkan daftar notifikasi, badge unread, dan ringkasan dashboard.
    container.invalidate(unreadCountProvider);
    container.invalidate(notificationsListProvider);
    container.invalidate(paginatedNotificationsProvider);
    container.invalidate(notificationsProvider);
    container.invalidate(dashboardDataProvider);

    final showInApp = container.read(showInAppNotificationsProvider);
    if (!showInApp) return;

    final title =
        message.notification?.title ?? message.data['title']?.toString() ?? '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;

    await _initLocalNotifications();
    if (kDebugMode) {
      debugPrint(
        '[FCM] Foreground message id=${message.messageId} route=${message.data['route']} type=${message.data['type']}',
      );
    }
    final notificationId =
        (message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString())
                .hashCode &
            0x7fffffff;

    try {
      await _localNotifications.show(
        id: notificationId,
        title: title.isEmpty ? 'TahanDulu' : title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            androidChannelName,
            channelDescription: androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (_) {}
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    _queueDeepLink(message.data);
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      _queueDeepLink(const <String, dynamic>{});
      return;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _queueDeepLink(Map<String, dynamic>.from(decoded));
        return;
      }
    } catch (_) {}
    _queueDeepLink(const <String, dynamic>{});
  }

  void _queueDeepLink(Map<String, dynamic> data) {
    _pendingData = Map<String, dynamic>.from(data);
    drainPendingDeepLink();
  }

  /// Eksekusi deep-link tertunda setelah user login dan keluar dari splash.
  void drainPendingDeepLink() {
    final data = _pendingData;
    final container = _container;
    if (data == null || container == null) return;

    final auth = container.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated ||
        !(auth.user?.isOnboarded ?? false)) {
      return;
    }

    final router = container.read(goRouterProvider);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == AppRoutes.splash) {
      return;
    }

    _pendingData = null;

    final notificationId = data['notification_id']?.toString().trim();
    if (notificationId != null && notificationId.isNotEmpty) {
      unawaited(
        container
            .read(notificationsControllerProvider.notifier)
            .markAsRead(notificationId),
      );
    }

    final targetRoute = NotificationDeepLink.resolve(
      route: data['route']?.toString(),
      type: data['type']?.toString(),
      entityId: data['entity_id']?.toString(),
    );
    if (kDebugMode) {
      debugPrint('[FCM] Navigating deep link -> $targetRoute');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        router.push(targetRoute);
      } catch (_) {}
    });
  }

  /// Lepas stream listener (untuk cleanup/testing).
  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedAppSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onOpenedAppSub = null;
    _onTokenRefreshSub = null;
    _listenersAttached = false;
  }
}
