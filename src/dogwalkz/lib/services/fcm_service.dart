import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final _supabase = Supabase.instance.client;

  // Stream controller for handling notification taps
  static final StreamController<Map<String, dynamic>>
  _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  /// Initialize FCM service
  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _setupFCMListeners();
    await _saveTokenToDatabase();
    await validateAndRefreshToken();
    listenToTokenRefresh();
    //periodic validation
    Timer.periodic(Duration(hours: 1), (timer) {
      validateAndRefreshToken();
    });
  }

  static Future<void> onAppResume() async {
    await validateAndRefreshToken();
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'dogwalkz_channel',
              'DogWalkz Notifications',
              description: 'Notifications for DogWalkz app',
              importance: Importance.high,
              sound: RawResourceAndroidNotificationSound('notification_sound'),
            ),
          );
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  /// Setup FCM listeners
  static Future<void> _setupFCMListeners() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }
  }

  /// Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp();
    await _showLocalNotification(message);
    await _triggerVibration();
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
    await _triggerVibration();
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    var androidDetails = AndroidNotificationDetails(
      'dogwalkz_channel',
      'DogWalkz Notifications',
      channelDescription: 'Notifications for DogWalkz app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF8B4513),
      vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
      enableLights: true,
      ledColor: const Color(0xFF8B4513),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    var notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? message.data['title'],
      message.notification?.body ?? message.data['message'],
      notificationDetails,
      payload: _encodePayload(message.data),
    );
  }

  /// Encode payload to string format
  static String _encodePayload(Map<String, dynamic> data) {
    try {
      return data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } catch (e) {
      return '';
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(dynamic payload) {
    Map<String, dynamic> data;

    if (payload is String) {
      data = _parsePayload(payload);
    } else if (payload is Map<String, dynamic>) {
      data = payload;
    } else {
      return;
    }

    _notificationStreamController.add(data);
  }

  /// Parse string payload to map
  static Map<String, dynamic> _parsePayload(String payload) {
    try {
      final pairs = payload.split(', ');
      final Map<String, dynamic> result = {};

      for (final pair in pairs) {
        final keyValue = pair.split(': ');
        if (keyValue.length == 2) {
          result[keyValue[0]] = keyValue[1];
        }
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  /// Trigger vibration
  static Future<void> _triggerVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(
        pattern: [0, 200, 100, 200],
        intensities: [0, 128, 0, 255],
      );
    }
  }

  /// Save FCM token to database
  static Future<void> _saveTokenToDatabase() async {
    try {
      final token = await _firebaseMessaging.getToken();
      final userId = _supabase.auth.currentUser?.id;

      if (token == null || userId == null) {
        throw Exception('Token or user is null');
      }

      // Use upsert instead of separate update/insert
      await _supabase.from('user_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,platform');

      print('FCM token saved to database: $token');
    } catch (e) {
      print('Error saving FCM token: $e');
      rethrow;
    }
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Update token when it refreshes
  static void listenToTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((token) async {
      print('FCM token refreshed: $token');

      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          await _saveTokenToDatabase();
          print('Token successfully updated in database');
          break;
        } catch (e) {
          retryCount++;
          print('Error saving refreshed token (attempt $retryCount): $e');

          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }
    });
  }

  static Future<void> validateAndRefreshToken({bool force = false}) async {
    try {
      final currentToken = await _firebaseMessaging.getToken();
      final userId = _supabase.auth.currentUser?.id;

      if (currentToken == null || userId == null) {
        if (force) {
          // If forcing, try again after a short delay
          await Future.delayed(Duration(seconds: 2));
          return validateAndRefreshToken(force: force);
        }
        return;
      }

      final dbToken =
          await _supabase
              .from('user_tokens')
              .select('fcm_token, updated_at')
              .eq('user_id', userId)
              .eq('platform', Platform.isIOS ? 'ios' : 'android')
              .eq('is_active', true)
              .maybeSingle();

      bool needsUpdate =
          force ||
          dbToken == null ||
          dbToken['fcm_token'] != currentToken ||
          DateTime.now()
                  .difference(DateTime.parse(dbToken['updated_at']))
                  .inDays >
              1; // Reduced from 7 days to 1 day

      if (needsUpdate) {
        await _saveTokenToDatabase();
      }
    } catch (e) {
      print('Error validating token: $e');
      if (force) {
        await Future.delayed(Duration(seconds: 2));
        return validateAndRefreshToken(force: force);
      }
    }
  }

  /// Send push notification via Supabase Edge Function
  /// This calls the backend to send the notification using FCM HTTP v1 API
  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to send push notification: ${response.data}');
      }

      print('Push notification sent successfully');
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  /// Send notification for new walk scheduled
  static Future<void> sendWalkScheduledNotification({
    required String walkerId,
    required String walkId,
  }) async {
    await sendPushNotification(
      userId: walkerId,
      title: 'New Walk Scheduled! 🐕',
      body: 'You have a new walk scheduled. Tap to view details.',
      data: {
        'type': 'walk_scheduled',
        'walk_id': walkId,
        'action': 'open_walk_details',
      },
    );
  }

  /// Send notification for new message
  static Future<void> sendNewMessageNotification({
    required String receiverId,
    required String walkId,
    required String senderName,
  }) async {
    await sendPushNotification(
      userId: receiverId,
      title: 'New Message 💬',
      body: 'You have a new message from $senderName!',
      data: {
        'type': 'new_message',
        'walk_id': walkId,
        'sender_name': senderName,
        'action': 'open_chat',
      },
    );
  }

  /// Send notification for walk reminder
  static Future<void> sendWalkReminderNotification({
    required String userId,
    required String walkId,
    required String dogName,
    required int minutesUntilWalk,
  }) async {
    await sendPushNotification(
      userId: userId,
      title: 'Walk Reminder ⏰',
      body: '$dogName\'s walk starts in $minutesUntilWalk minutes!',
      data: {
        'type': 'walk_reminder',
        'walk_id': walkId,
        'dog_name': dogName,
        'action': 'open_walk_details',
      },
    );
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear specific notification
  static Future<void> clearNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Dispose resources
  static void dispose() {
    _notificationStreamController.close();
  }
}
