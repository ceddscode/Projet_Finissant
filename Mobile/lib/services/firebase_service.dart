import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:municipalgo/http/lib_http.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:municipalgo/main.dart';
import '../pages/incident_details.dart';

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _requestPermissions();

    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('Device Token: $token');
      await _sendTokenToBackend(token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('Token Refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });

    FirebaseMessaging.onMessage.listen(_showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundNotificationClick);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundNotificationClick(initialMessage);
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification clicked: ${response.payload}');
        if (response.payload != null) {
          _handleForegroundNotificationClick(response.payload!);
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'municipaligo_channel',
      'Mises à jour des incidents',
      description: 'Notifications pour les changements de statut des incidents',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification permissions granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notification permissions denied');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      await sendDeviceToken(token);
      debugPrint('Device token sent to backend');
    } catch (e) {
      debugPrint('Failed to send token: $e');
    }
  }

  static void _handleForegroundNotificationClick(String payload) {
    try {
      final incidentId = int.parse(payload);
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IncidentDetailsPage(incidentId: incidentId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  static void _handleBackgroundNotificationClick(RemoteMessage message) {
    try {
      final incidentIdStr = message.data['incidentId'];
      if (incidentIdStr == null) return;

      final incidentId = int.parse(incidentIdStr.toString());
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IncidentDetailsPage(incidentId: incidentId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling background notification: $e');
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    debugPrint('Foreground notification: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'MunicipaliGo',
      body: notification.body ?? 'Vous avez une nouvelle notification',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'municipaligo_channel',
          'Mises à jour des incidents',
          channelDescription: 'Notifications pour les changements de statut des incidents',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: message.data['incidentId']?.toString(),
    );
  }
}
