import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

typedef NotificationTapCallback = void Function(Map<String, dynamic> data);
typedef NotificationReceivedCallback =
    void Function(String type, Map<String, dynamic> data);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? get _firebaseMessaging =>
      Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationTapCallback? onNotificationTapped;
  NotificationReceivedCallback? onNotificationReceived;
  Future<void> Function(String token)? onTokenChanged;
  bool Function(Map<String, dynamic> data)? shouldShowNotification;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _initializeLocalNotifications();
    _initialized = true;
    if (Firebase.apps.isNotEmpty) {
      try {
        _firebaseMessaging?.onTokenRefresh.listen((token) async {
          await onTokenChanged?.call(token);
        });
        await _handleForegroundMessages();
        _handleNotificationOpens();
        final token = await getToken();
        if (token != null) await onTokenChanged?.call(token);
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
        Uri.parse(payload).queryParameters,
      );
      onNotificationTapped?.call(data);
    }
  }

  /// Public opt-in used by the post-login welcome setup.
  Future<void> requestPermissions() async {
    await _requestPermissions();
    final token = await getToken();
    if (token != null) await onTokenChanged?.call(token);
  }

  Future<void> _requestPermissions() async {
    final fm = _firebaseMessaging;
    if (fm == null) return;
    if (Platform.isIOS) {
      await fm.requestPermission();
    } else if (Platform.isAndroid) {
      await fm.requestPermission();
    }
  }

  Future<String?> getToken() async {
    final fm = _firebaseMessaging;
    if (fm == null) return null;
    try {
      if (Platform.isIOS && await fm.getAPNSToken() == null) return null;
      return await fm.getToken();
    } catch (e) {
      debugPrint('[NotificationService] Failed to retrieve FCM token: $e');
      return null;
    }
  }

  Future<void> clearToken() async => _firebaseMessaging?.deleteToken();

  Future<void> _handleForegroundMessages() async {
    FirebaseMessaging.onMessage.listen((message) {
      if (shouldShowNotification?.call(message.data) ?? true) {
        _showLocalNotification(message);
      }
      if (message.data.isNotEmpty) {
        onNotificationReceived?.call(
          message.data['type'] ?? 'UNKNOWN',
          Map<String, dynamic>.from(message.data),
        );
      }
    });
  }

  void _handleNotificationOpens() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data.isEmpty) return;
      onNotificationTapped?.call(Map<String, dynamic>.from(message.data));
    });
  }

  Future<void> consumeLaunchNotification() async {
    final localLaunch = await _localNotifications
        .getNotificationAppLaunchDetails();
    final response = localLaunch?.notificationResponse;
    if (localLaunch?.didNotificationLaunchApp == true && response != null) {
      _onNotificationTapped(response);
      return;
    }
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

  Future<RemoteMessage?> getInitialMessage() async {
    return _firebaseMessaging?.getInitialMessage();
  }
}
