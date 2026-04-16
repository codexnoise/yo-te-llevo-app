import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../features/profile/domain/repositories/profile_repository.dart';

const String kNotificationChannelId = 'yo_te_llevo_default';
const String kNotificationChannelName = 'Notificaciones de viajes';

/// Handler de background / app cerrada. Debe ser top-level con la anotación
/// `@pragma('vm:entry-point')` para que el aislador pueda invocarlo.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  // El sistema muestra la notificación automáticamente. Solo nos interesa
  // que Flutter registre el mensaje para que al abrir la app podamos
  // procesar `getInitialMessage()`.
  debugPrint('FCM background: ${message.messageId}');
}

/// Servicio central de notificaciones. Responsabilidades:
/// - Solicitar permisos en iOS/Android 13+.
/// - Mantener el `fcmToken` sincronizado en `/users/{uid}`.
/// - Mostrar notificaciones locales cuando la app está en foreground.
/// - Deep-link a `/trips/:matchId` al tocar una notificación.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  GoRouter? _router;
  ProfileRepository? _profileRepository;
  String? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;
  bool _initialized = false;

  /// Inicializa la capa local (canales, handlers). Debe llamarse una vez
  /// después de `Firebase.initializeApp()`.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // Canal explícito para Android 8+. Debe coincidir con el channelId
    // enviado desde Cloud Functions y con `default_notification_channel_id`
    // del manifest.
    const channel = AndroidNotificationChannel(
      kNotificationChannelId,
      kNotificationChannelName,
      description: 'Solicitudes y actualizaciones de viajes',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _fm.requestPermission(alert: true, badge: true, sound: true);

    _messageSub = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      // Esperamos a que el router esté disponible antes de navegar.
      scheduleMicrotask(() => _handleNotificationTap(initial));
    }
  }

  /// Inyectado desde la capa de UI (App) una vez que el router existe.
  void attachRouter(GoRouter router) {
    _router = router;
  }

  /// Se llama cuando el usuario inicia sesión: guarda el token en Firestore
  /// y se suscribe a `onTokenRefresh` para mantenerlo al día.
  Future<void> registerForUser(
    String uid,
    ProfileRepository profileRepository,
  ) async {
    _currentUserId = uid;
    _profileRepository = profileRepository;

    final token = await _fm.getToken();
    if (token != null) {
      await profileRepository.updateFcmToken(uid, token);
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _fm.onTokenRefresh.listen((newToken) async {
      final activeUser = _currentUserId;
      if (activeUser == null) return;
      await profileRepository.updateFcmToken(activeUser, newToken);
    });
  }

  /// Se llama en logout: limpia el token del usuario saliente.
  Future<void> clearForUser(String uid) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    final repo = _profileRepository;
    if (repo != null) {
      await repo.updateFcmToken(uid, null);
    }
    _currentUserId = null;
    _profileRepository = null;
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _messageSub?.cancel();
    await _openedAppSub?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Handlers internos
  // ---------------------------------------------------------------------------

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final payload = jsonEncode(message.data);
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          kNotificationChannelId,
          kNotificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _onLocalTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data.cast<String, dynamic>());
    } catch (e) {
      debugPrint('No se pudo parsear payload de notificación: $e');
    }
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final router = _router;
    if (router == null) return;
    final matchId = data['matchId'];
    if (matchId is String && matchId.isNotEmpty) {
      router.go('/trips/$matchId');
    }
  }
}
