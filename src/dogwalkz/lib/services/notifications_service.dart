import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'fcm_service.dart'; // Import your FCM service

class NotificationService {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _notificationChannel;
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// This will listen for events on the notifications table.
  /// When a notification is inserted or updated, the unread count will be
  /// refreshed.
  void startListening() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _notificationChannel =
        _supabase
            .channel('notifications_$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                _refreshUnreadCount();
                _triggerVibration();
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId,
              ),
              callback: (payload) {
                _refreshUnreadCount();
                _triggerVibration();
              },
            )
            .subscribe();
  }

  /// Refresh the unread notification count
  Future<void> _refreshUnreadCount() async {
    final count = await getUnreadCount();
    _unreadCountController.add(count);
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;
    final data = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return data.length;
  }

  /// Get all notifications for the current user
  /// Returns a list of notifications, each represented as a map.
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (response is PostgrestException) {
      print('Error fetching notifications');
      return [];
    }

    return List<Map<String, dynamic>>.from(response);
  }

  /// Marks a notification as read.
  /// [notificationId] is the ID of the notification to be marked as read.
  Future<void> markAsRead(String notificationId) async {
    final result = await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);

    if (result is PostgrestException) {
      print('Error marking as read: ${result.message}');
    }
  }

  /// Deletes a notification.
  /// [notificationId] is the ID of the notification to be deleted.
  Future<void> deleteNotification(String notificationId) async {
    final result = await _supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);

    if (result is PostgrestException) {
      print('Error deleting notification: ${result.message}');
    }
  }

  /// Sends a notification to a user and stores it in database.
  /// Also sends push notification if user has FCM token.
  /// [userId] is the ID of the user to whom the notification is sent.
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedEntityType,
    String? relatedEntityId,
    bool sendPush = true,
  }) async {
    final supabase = Supabase.instance.client;

    // Store notification in database
    final result = await supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_entity_type': relatedEntityType,
      'related_entity_id': relatedEntityId,
    });

    if (result is PostgrestException) {
      print('Error sending notification: ${result.message}');
      return;
    }
  }

  /// Sends a notification to the walker when a new walk is scheduled.
  static Future<void> sendWalkScheduledNotification({
    required String walkerId,
    required String walkId,
  }) async {
    await sendNotification(
      userId: walkerId,
      title: 'New Walk Scheduled! 🐕',
      message: 'You have a new walk scheduled. Tap to view details.',
      type: 'walk_scheduled',
      relatedEntityType: 'walk',
      relatedEntityId: walkId,
    );

    // Also send via FCM service with more specific data
    try {
      await FCMService.sendWalkScheduledNotification(
        walkerId: walkerId,
        walkId: walkId,
      );
    } catch (e) {
      print('Error sending FCM walk scheduled notification: $e');
    }
  }

  /// Sends a notification for a new message
  static Future<void> sendNewMessageNotification({
    required String receiverId,
    required String walkId,
    required String senderName,
  }) async {
    await sendNotification(
      userId: receiverId,
      title: 'New Message 💬',
      message: 'You have a new message from $senderName!',
      type: 'new_message',
      relatedEntityType: 'walk',
      relatedEntityId: walkId,
    );

    // Also send via FCM service with more specific data
    try {
      await FCMService.sendNewMessageNotification(
        receiverId: receiverId,
        walkId: walkId,
        senderName: senderName,
      );
    } catch (e) {
      print('Error sending FCM new message notification: $e');
    }
  }

  /// Sends a notification for walk reminder
  static Future<void> sendWalkReminderNotification({
    required String userId,
    required String walkId,
    required String dogName,
    required int minutesUntilWalk,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Walk Reminder ⏰',
      message: '$dogName\'s walk starts in $minutesUntilWalk minutes!',
      type: 'walk_reminder',
      relatedEntityType: 'walk',
      relatedEntityId: walkId,
    );

    // Also send via FCM service
    try {
      await FCMService.sendWalkReminderNotification(
        userId: userId,
        walkId: walkId,
        dogName: dogName,
        minutesUntilWalk: minutesUntilWalk,
      );
    } catch (e) {
      print('Error sending FCM walk reminder notification: $e');
    }
  }

  /// Sends a notification when a walk is completed
  static Future<void> sendWalkCompletedNotification({
    required String ownerId,
    required String walkId,
    required String dogName,
    required String walkerName,
  }) async {
    await sendNotification(
      userId: ownerId,
      title: 'Walk Completed! ✅',
      message: '$walkerName has completed the walk with $dogName.',
      type: 'walk_completed',
      relatedEntityType: 'walk',
      relatedEntityId: walkId,
    );

    // Also send push notification
    try {
      await FCMService.sendPushNotification(
        userId: ownerId,
        title: 'Walk Completed! ✅',
        body: '$walkerName has completed the walk with $dogName.',
        data: {
          'type': 'walk_completed',
          'walk_id': walkId,
          'dog_name': dogName,
          'walker_name': walkerName,
          'action': 'open_walk_details',
        },
      );
    } catch (e) {
      print('Error sending FCM walk completed notification: $e');
    }
  }

  /// Sends a notification when a walk is cancelled
  static Future<void> sendWalkCancelledNotification({
    required String receiverId,
    required String walkId,
    required String dogName,
    required String reason,
  }) async {
    await sendNotification(
      userId: receiverId,
      title: 'Walk Cancelled ❌',
      message: 'The walk with $dogName has been cancelled. Reason: $reason',
      type: 'walk_cancelled',
      relatedEntityType: 'walk',
      relatedEntityId: walkId,
    );

    // Also send push notification
    try {
      await FCMService.sendPushNotification(
        userId: receiverId,
        title: 'Walk Cancelled ❌',
        body: 'The walk with $dogName has been cancelled.',
        data: {
          'type': 'walk_cancelled',
          'walk_id': walkId,
          'dog_name': dogName,
          'reason': reason,
          'action': 'open_walks',
        },
      );
    } catch (e) {
      print('Error sending FCM walk cancelled notification: $e');
    }
  }

  /// Sends a notification for payment confirmation
  static Future<void> sendPaymentConfirmationNotification({
    required String userId,
    required String walkId,
    required double amount,
    required String currency,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Payment Received 💰',
      message:
          'You have received $currency${amount.toStringAsFixed(2)} for your walk service.',
      type: 'payment_received',
      relatedEntityType: 'walk',
      relatedEntityId: walkId,
    );

    // Also send push notification
    try {
      await FCMService.sendPushNotification(
        userId: userId,
        title: 'Payment Received 💰',
        body:
            'You have received $currency${amount.toStringAsFixed(2)} for your walk service.',
        data: {
          'type': 'payment_received',
          'walk_id': walkId,
          'amount': amount.toString(),
          'currency': currency,
          'action': 'open_wallet',
        },
      );
    } catch (e) {
      print('Error sending FCM payment confirmation notification: $e');
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final result = await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);

    if (result is PostgrestException) {
      print('Error marking all as read: ${result.message}');
    } else {
      _refreshUnreadCount();
    }
  }

  /// Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final result = await _supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId);

    if (result is PostgrestException) {
      print('Error deleting all notifications: ${result.message}');
    } else {
      _refreshUnreadCount();
    }
  }

  /// Get notification by ID
  Future<Map<String, dynamic>?> getNotificationById(
    String notificationId,
  ) async {
    final response =
        await _supabase
            .from('notifications')
            .select()
            .eq('id', notificationId)
            .single();

    if (response is PostgrestException) {
      print('Error fetching notification');
      return null;
    }

    return response;
  }

  /// Subscribe to push notifications for topics
  Future<void> subscribeToTopics() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Subscribe to general notifications
      await FCMService.subscribeToTopic('general_notifications');

      // Subscribe to user-specific notifications
      await FCMService.subscribeToTopic('user_$userId');

      print('Subscribed to notification topics');
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }

  /// Unsubscribe from push notification topics
  Future<void> unsubscribeFromTopics() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Unsubscribe from general notifications
      await FCMService.unsubscribeFromTopic('general_notifications');

      // Unsubscribe from user-specific notifications
      await FCMService.unsubscribeFromTopic('user_$userId');

      print('Unsubscribed from notification topics');
    } catch (e) {
      print('Error unsubscribing from topics: $e');
    }
  }

  /// Triggers a vibration pattern on devices with vibration capability.
  ///
  /// The vibration pattern consists of alternating wait and vibrate periods
  /// with varying intensities. The pattern used is [wait, vibrate, wait, vibrate],
  /// where values are specified in milliseconds. The intensities are specified for
  /// Android devices only, with iOS support pending.
  Future<void> _triggerVibration() async {
    // Check if device has vibration capability
    if (await Vibration.hasVibrator() ?? false) {
      //IMPORTANT -->vibration pattern: [wait, vibrate, wait, vibrate]
      // Values are in milliseconds!!
      await Vibration.vibrate(
        pattern: [0, 200, 100, 200], // Short app standard double vibration
        intensities: [
          0,
          128,
          0,
          255,
        ], // Varying intensities (Android only, still pending for iOS)
      );
    }
  }

  /// Disposes of the resources held by the NotificationService.
  ///
  /// This method ensures that the notification channel is unsubscribed from
  /// and that the unread count stream controller is properly closed, freeing
  /// up resources.
  void dispose() {
    _notificationChannel?.unsubscribe();
    _unreadCountController.close();
  }
}
