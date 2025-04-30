import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/notifications_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  /// Initializes the state of the widget.
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Loads the user's notifications from the NotificationService.
  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getUserNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notifications: $e')),
      );
    }
  }

  /// Handles the tap on a notification.
  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    // Mark as read
    if (notification['is_read'] == false) {
      await _notificationService.markAsRead(notification['id']);
      setState(() {
        notification['is_read'] = true;
      });
    }

    // Handle navigation based on notification type
    final type = notification['type'];
    final entityId = notification['related_entity_id'];

    if (type == 'walk_scheduled' &&
        entityId != null) {} // TODO: Navigate to walk details
  }

  /// Deletes a notification from the list and the server.
  /// This method is called when the user swipes a notification to delete it.
  Future<void> _deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);
      setState(() {
        _notifications.removeWhere((n) => n['id'] == id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
  }

  /// Builds the UI of the NotificationsPage.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.notifications),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? Center(
                child: Text(
                  "No Notifications",
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Dismissible(
                    key: Key(notification['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Ionicons.trash_outline,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed:
                        (direction) => _deleteNotification(notification['id']),
                    child: ListTile(
                      leading: Icon(
                        _getNotificationIcon(notification['type']),
                        color:
                            notification['is_read']
                                ? Colors.grey
                                : Colors.brown,
                      ),
                      title: Text(
                        notification['title'],
                        style: TextStyle(
                          fontWeight:
                              notification['is_read']
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notification['message']),
                      trailing: Text(
                        _formatDate(notification['created_at']),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () => _handleNotificationTap(notification),
                    ),
                  );
                },
              ),
    );
  }

  /// Returns the appropriate icon based on the notification type.
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'walk_scheduled':
        return Ionicons.walk_outline;
      case 'walk_accepted':
        return Ionicons.checkmark_done_outline;
      case 'walk_completed':
        return Ionicons.checkmark_done_outline;
      case 'payment':
        return Ionicons.wallet_outline;
      default:
        return Ionicons.notifications_outline;
    }
  }

  /// Formats the date string to a more readable format.
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
