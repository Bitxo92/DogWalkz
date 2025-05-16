import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _supabase = Supabase.instance.client;

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

  /// Sends a notification to a user.
  /// [userId] is the ID of the user to whom the notification is sent.
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedEntityType,
    String? relatedEntityId,
  }) async {
    final supabase = Supabase.instance.client;

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
    }
  }

  /// Sends a notification to the walker when a new walk is scheduled.
  static Future<void> sendWalkScheduledNotification({
    required String walkerId,
    required String walkId,
  }) async {
    await sendNotification(
      userId: walkerId,
      title: 'New Walk Scheduled!',
      message: 'You have a new walk scheduled. Tap to view details.',
      type: 'walk_scheduled',
      relatedEntityType: 'walk',
      relatedEntityId: walkId,
    );
  }
}
