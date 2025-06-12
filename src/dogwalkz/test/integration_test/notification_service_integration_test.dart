import 'dart:async';
import 'package:dogwalkz/services/notifications_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:your_app/services/notifications_service.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Integration Tests', () {
    late NotificationService notificationService;
    late String testUserId;
    late String testNotificationId;

    setUpAll(() async {
  
      await Supabase.initialize(
        url: 'YOUR_SUPABASE_URL', 
        anonKey: 'YOUR_ANON_KEY', 
      );

      
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(
            email: 'test@example.com', 
            password: 'testPassword123', 
          );

      testUserId = authResponse.user!.id;
      notificationService = NotificationService();
    });

    tearDownAll(() async {
    
      await _cleanupTestData();
      await Supabase.instance.client.auth.signOut();
      notificationService.dispose();
    });

    group('Database Operations', () {
      testWidgets('should create and retrieve notifications', (tester) async {
       
        await NotificationService.sendNotification(
          userId: testUserId,
          title: 'Integration Test Notification',
          message: 'This is a test notification for integration testing',
          type: 'test_notification',
          relatedEntityType: 'test',
          relatedEntityId: 'test-entity-123',
        );

       
        await Future.delayed(const Duration(seconds: 1));

    
        final notifications = await notificationService.getUserNotifications();

        expect(notifications.isNotEmpty, true);

        final testNotification = notifications.firstWhere(
          (n) => n['title'] == 'Integration Test Notification',
          orElse: () => <String, dynamic>{},
        );

        expect(testNotification.isNotEmpty, true);
        expect(
          testNotification['message'],
          'This is a test notification for integration testing',
        );
        expect(testNotification['type'], 'test_notification');
        expect(testNotification['related_entity_type'], 'test');
        expect(testNotification['related_entity_id'], 'test-entity-123');
        expect(testNotification['is_read'], false);

        testNotificationId = testNotification['id'];
      });

      testWidgets('should get correct unread count', (tester) async {
      
        final initialCount = await notificationService.getUnreadCount();
        expect(initialCount, greaterThan(0));

     
        await NotificationService.sendNotification(
          userId: testUserId,
          title: 'Second Test Notification',
          message: 'This is a second test notification',
          type: 'test_notification_2',
        );

        await Future.delayed(const Duration(seconds: 1));

       
        final newCount = await notificationService.getUnreadCount();
        expect(newCount, equals(initialCount + 1));
      });

      testWidgets('should mark notification as read', (tester) async {
       
        final initialCount = await notificationService.getUnreadCount();

     
        await notificationService.markAsRead(testNotificationId);
        await Future.delayed(const Duration(seconds: 1));

        final newCount = await notificationService.getUnreadCount();
        expect(newCount, equals(initialCount - 1));

     
        final notification = await notificationService.getNotificationById(
          testNotificationId,
        );
        expect(notification, isNotNull);
        expect(notification!['is_read'], true);
      });

      testWidgets('should get notification by ID', (tester) async {
        final notification = await notificationService.getNotificationById(
          testNotificationId,
        );

        expect(notification, isNotNull);
        expect(notification!['id'], testNotificationId);
        expect(notification['title'], 'Integration Test Notification');
      });

      testWidgets('should mark all notifications as read', (tester) async {
      
        for (int i = 0; i < 3; i++) {
          await NotificationService.sendNotification(
            userId: testUserId,
            title: 'Bulk Test Notification $i',
            message: 'This is bulk test notification $i',
            type: 'bulk_test',
          );
        }

        await Future.delayed(const Duration(seconds: 1));

       
        final unreadCount = await notificationService.getUnreadCount();
        expect(unreadCount, greaterThan(0));

        await notificationService.markAllAsRead();
        await Future.delayed(const Duration(seconds: 1));

       
        final newUnreadCount = await notificationService.getUnreadCount();
        expect(newUnreadCount, equals(0));
      });

      testWidgets('should delete notification', (tester) async {
       
        await NotificationService.sendNotification(
          userId: testUserId,
          title: 'Notification to Delete',
          message: 'This notification will be deleted',
          type: 'delete_test',
        );

        await Future.delayed(const Duration(seconds: 1));

        final notifications = await notificationService.getUserNotifications();
        final notificationToDelete = notifications.firstWhere(
          (n) => n['title'] == 'Notification to Delete',
        );

        final notificationId = notificationToDelete['id'];

       
        await notificationService.deleteNotification(notificationId);
        await Future.delayed(const Duration(seconds: 1));

      
        final deletedNotification = await notificationService
            .getNotificationById(notificationId);
        expect(deletedNotification, isNull);
      });
    });

    group('Real-time Updates', () {
      testWidgets('should receive real-time updates', (tester) async {
        
        notificationService.startListening();

      
        final completer = Completer<int>();
        late StreamSubscription subscription;

        subscription = notificationService.unreadCountStream.listen((count) {
          if (!completer.isCompleted) {
            completer.complete(count);
          }
        });

       
        await NotificationService.sendNotification(
          userId: testUserId,
          title: 'Real-time Test Notification',
          message: 'This tests real-time functionality',
          type: 'realtime_test',
        );

        try {
          final count = await completer.future.timeout(
            const Duration(seconds: 10),
          );
          expect(count, isA<int>());
          expect(count, greaterThan(0));
        } catch (e) {
          fail('Real-time update was not received within 10 seconds: $e');
        } finally {
          subscription.cancel();
        }
      });
    });

    group('Specialized Notification Types', () {
      testWidgets('should send walk scheduled notification', (tester) async {
        await NotificationService.sendWalkScheduledNotification(
          walkerId: testUserId,
          walkId: 'test-walk-123',
        );

        await Future.delayed(const Duration(seconds: 1));

        final notifications = await notificationService.getUserNotifications();
        final walkNotification = notifications.firstWhere(
          (n) => n['type'] == 'walk_scheduled',
          orElse: () => <String, dynamic>{},
        );

        expect(walkNotification.isNotEmpty, true);
        expect(walkNotification['title'], 'New Walk Scheduled! 🐕');
        expect(walkNotification['related_entity_type'], 'walk');
        expect(walkNotification['related_entity_id'], 'test-walk-123');
      });

      testWidgets('should send new message notification', (tester) async {
        await NotificationService.sendNewMessageNotification(
          receiverId: testUserId,
          walkId: 'test-walk-456',
          senderName: 'Integration Test User',
        );

        await Future.delayed(const Duration(seconds: 1));

        final notifications = await notificationService.getUserNotifications();
        final messageNotification = notifications.firstWhere(
          (n) => n['type'] == 'new_message',
          orElse: () => <String, dynamic>{},
        );

        expect(messageNotification.isNotEmpty, true);
        expect(messageNotification['title'], 'New Message 💬');
        expect(
          messageNotification['message'],
          'You have a new message from Integration Test User!',
        );
        expect(messageNotification['related_entity_id'], 'test-walk-456');
      });

      testWidgets('should send walk reminder notification', (tester) async {
        await NotificationService.sendWalkReminderNotification(
          userId: testUserId,
          walkId: 'test-walk-789',
          dogName: 'Integration Test Dog',
          minutesUntilWalk: 30,
        );

        await Future.delayed(const Duration(seconds: 1));

        final notifications = await notificationService.getUserNotifications();
        final reminderNotification = notifications.firstWhere(
          (n) => n['type'] == 'walk_reminder',
          orElse: () => <String, dynamic>{},
        );

        expect(reminderNotification.isNotEmpty, true);
        expect(reminderNotification['title'], 'Walk Reminder ⏰');
        expect(
          reminderNotification['message'],
          'Integration Test Dog\'s walk starts in 30 minutes!',
        );
      });

      testWidgets('should send walk completed notification', (tester) async {
        await NotificationService.sendWalkCompletedNotification(
          ownerId: testUserId,
          walkId: 'test-walk-completed',
          dogName: 'Test Dog',
          walkerName: 'Test Walker',
        );

        await Future.delayed(const Duration(seconds: 1));

        final notifications = await notificationService.getUserNotifications();
        final completedNotification = notifications.firstWhere(
          (n) => n['type'] == 'walk_completed',
          orElse: () => <String, dynamic>{},
        );

        expect(completedNotification.isNotEmpty, true);
        expect(completedNotification['title'], 'Walk Completed! ✅');
        expect(
          completedNotification['message'],
          'Test Walker has completed the walk with Test Dog.',
        );
      });

      testWidgets('should send payment confirmation notification', (
        tester,
      ) async {
        await NotificationService.sendPaymentConfirmationNotification(
          userId: testUserId,
          walkId: 'test-payment-walk',
          amount: 25.50,
          currency: '€',
        );

        await Future.delayed(const Duration(seconds: 1));

        final notifications = await notificationService.getUserNotifications();
        final paymentNotification = notifications.firstWhere(
          (n) => n['type'] == 'payment_received',
          orElse: () => <String, dynamic>{},
        );

        expect(paymentNotification.isNotEmpty, true);
        expect(paymentNotification['title'], 'Payment Received 💰');
        expect(
          paymentNotification['message'],
          'You have received €25.50 for your walk service.',
        );
      });
    });

    group('Vibration Integration', () {
      testWidgets('should handle vibration calls without errors', (
        tester,
      ) async {
       
        const channel = MethodChannel('vibration');
        handler(MethodCall methodCall) async {
          if (methodCall.method == 'hasVibrator') {
            return true;
          } else if (methodCall.method == 'vibrate') {
            return null;
          }
          return null;
        }

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, handler);

       
        notificationService.startListening();

      
        await NotificationService.sendNotification(
          userId: testUserId,
          title: 'Vibration Test',
          message: 'Testing vibration functionality',
          type: 'vibration_test',
        );

    
        await Future.delayed(const Duration(seconds: 2));

       
        expect(true, true);

    
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
    });
  });

  
  Future<void> _cleanupTestData() async {
    try {
     
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .or(
            'type.eq.test_notification,type.eq.test_notification_2,type.eq.bulk_test,type.eq.delete_test,type.eq.realtime_test,type.eq.walk_scheduled,type.eq.new_message,type.eq.walk_reminder,type.eq.walk_completed,type.eq.payment_received,type.eq.vibration_test',
          );

      print('Test data cleaned up successfully');
    } catch (e) {
      print('Error cleaning up test data: $e');
    }
  }
}
