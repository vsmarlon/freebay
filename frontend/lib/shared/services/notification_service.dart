import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef NotificationTapCallback = void Function(Map<String, dynamic> data);
typedef NotificationReceivedCallback =
    void Function(String type, Map<String, dynamic> data);

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  if (Platform.isAndroid) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      'freebay_notifications',
      'FreeBay Notifications',
      channelDescription: 'Notifications from FreeBay',
      importance: Importance.high,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(android: androidDetails),
      payload: Uri(queryParameters: message.data).toString(),
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? get _firebaseMessaging =>
      Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _fcmTokenKey = 'fcm_token';

  NotificationTapCallback? onNotificationTapped;
  NotificationReceivedCallback? onNotificationReceived;

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    if (Firebase.apps.isNotEmpty) {
      try {
        await _requestPermissions();
        await _getToken();
        await _handleForegroundMessages();
        await _handleBackgroundMessages();
        _handleNotificationOpens();
      } catch (e) {
        debugPrint('[NotificationService] FCM init skipped: $e');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'freebay_notifications',
        'FreeBay Notifications',
        description: 'Notifications from FreeBay',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final data = Map<String, dynamic>.from(
        Uri.splitQueryString(payload).map(MapEntry.new),
      );
      onNotificationTapped?.call(data);
    }
  }

  /// Public opt-in used by the post-login welcome setup.
  Future<void> requestPermissions() => _requestPermissions();

  Future<void> _requestPermissions() async {
    final fm = _firebaseMessaging;
    if (fm == null) return;
    if (Platform.isIOS) {
      await fm.requestPermission();
    } else if (Platform.isAndroid) {
      await fm.requestPermission();
    }
  }

  Future<String?> _getToken() async {
    final fm = _firebaseMessaging;
    if (fm == null) return null;
    try {
      final token = await fm.getToken();
      if (token != null) {
        await _saveToken(token);
      }
      return token;
    } catch (e) {
      debugPrint('[NotificationService] Failed to retrieve FCM token: $e');
      return null;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  Future<void> _handleForegroundMessages() async {
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      if (message.data.isNotEmpty) {
        onNotificationReceived?.call(
          message.data['type'] ?? 'UNKNOWN',
          Map<String, dynamic>.from(message.data),
        );
      }
    });
  }

  Future<void> _handleBackgroundMessages() async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  }

  void _handleNotificationOpens() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data.isEmpty) return;
      onNotificationTapped?.call(Map<String, dynamic>.from(message.data));
    });
  }

  Future<void> consumeLaunchNotification() async {
    final message = await getInitialMessage();
    final data = message?.data;
    if (data == null || data.isEmpty) return;
    onNotificationTapped?.call(Map<String, dynamic>.from(data));
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = const AndroidNotificationDetails(
      'freebay_notifications',
      'FreeBay Notifications',
      channelDescription: 'Notifications from FreeBay',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: Uri(queryParameters: message.data).toString(),
    );
  }

  void onTokenRefresh(Function(String token) callback) {
    _firebaseMessaging?.onTokenRefresh.listen((token) async {
      await _saveToken(token);
      callback(token);
    });
  }

  Future<RemoteMessage?> getInitialMessage() async {
    return _firebaseMessaging?.getInitialMessage();
  }
}
