import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _fcmTokenKey = 'fcm_token';

  Function(Map<String, dynamic>)? onNotificationTapped;
  Function(String type, Map<String, dynamic> data)? onNotificationReceived;

  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _getToken();
    await _handleForegroundMessages();
    await _handleBackgroundMessages();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      final data = Map<String, dynamic>.from(
        Uri.splitQueryString(payload).map((k, v) => MapEntry(k, v)),
      );
      onNotificationTapped?.call(data);
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      await _firebaseMessaging.requestPermission();
    }
  }

  Future<String?> _getToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
    return token;
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
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      const androidDetails = AndroidNotificationDetails(
        'freebay_notifications',
        'FreeBay Notifications',
        channelDescription: 'Notifications from FreeBay',
        importance: Importance.high,
        priority: Priority.high,
      );

      flutterLocalNotificationsPlugin.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        const NotificationDetails(android: androidDetails),
        payload: Uri(queryParameters: message.data).toString(),
      );
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'freebay_notifications',
      'FreeBay Notifications',
      channelDescription: 'Notifications from FreeBay',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails(
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
    _firebaseMessaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
      callback(token);
    });
  }

  Future<RemoteMessage?> getInitialMessage() async {
    return _firebaseMessaging.getInitialMessage();
  }
}
