import 'dart:async';
import 'package:dogwalkz/services/notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:your_app/services/notifications_service.dart'; // Update with your actual path
import 'package:your_app/services/fcm_service.dart'; // Update with your actual path

// Generate mocks using build_runner: flutter packages pub run build_runner build
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  SupabaseQueryBuilder,
  SupabaseFilterBuilder,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
  RealtimeClient,
  RealtimeChannel,
  User,
])
import 'notification_service_test.mocks.dart';

void main() {
  group('NotificationService Unit Tests', () {
    late NotificationService notificationService;
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuthClient;
    late MockUser mockUser;
    late MockRealtimeChannel mockChannel;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockSupabaseFilterBuilder mockFilterBuilder;
    late MockPostgrestFilterBuilder mockPostgrestFilterBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;

    setUp(() {
      // Initialize mocks
      mockSupabaseClient = MockSupabaseClient();
      mockAuthClient = MockGoTrueClient();
      mockUser = MockUser();
      mockChannel = MockRealtimeChannel();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockSupabaseFilterBuilder();
      mockPostgrestFilterBuilder = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();

      // Setup Supabase instance mock
      when(mockSupabaseClient.auth).thenReturn(mockAuthClient);
      when(mockAuthClient.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('test-user-id');

      // Mock Supabase.instance.client
      final mockSupabase = MockSupabaseClient();
      when(mockSupabase.auth).thenReturn(mockAuthClient);

      notificationService = NotificationService();
    });

    tearDown(() {
      notificationService.dispose();
    });

    group('getUnreadCount', () {
      test('should return 0 when user is not authenticated', () async {
        when(mockAuthClient.currentUser).thenReturn(null);

        final count = await notificationService.getUnreadCount();

        expect(count, equals(0));
      });

      test(
        'should return correct unread count for authenticated user',
        () async {
          // Mock the query chain
          when(
            mockSupabaseClient.from('notifications'),
          ).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
          when(
            mockFilterBuilder.eq('user_id', 'test-user-id'),
          ).thenReturn(mockFilterBuilder);
          when(
            mockFilterBuilder.eq('is_read', false),
          ).thenReturn(mockFilterBuilder);

          // Mock response data
          final mockData = [
            {'id': '1'},
            {'id': '2'},
            {'id': '3'},
          ];
          when(mockFilterBuilder.select()).thenAnswer((_) async => mockData);

          final count = await notificationService.getUnreadCount();

          expect(count, equals(3));
        },
      );
    });

    group('getUserNotifications', () {
      test('should return empty list when user is not authenticated', () async {
        when(mockAuthClient.currentUser).thenReturn(null);

        final notifications = await notificationService.getUserNotifications();

        expect(notifications, isEmpty);
      });

      test('should return notifications for authenticated user', () async {
        // Mock the query chain
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('user_id', 'test-user-id'),
        ).thenReturn(mockTransformBuilder);
        when(
          mockTransformBuilder.order('created_at', ascending: false),
        ).thenReturn(mockTransformBuilder);

        final mockData = [
          {
            'id': '1',
            'title': 'Test Notification',
            'message': 'Test message',
            'is_read': false,
            'created_at': '2024-01-01T10:00:00Z',
          },
        ];
        when(mockTransformBuilder.select()).thenAnswer((_) async => mockData);

        final notifications = await notificationService.getUserNotifications();

        expect(notifications, isNotEmpty);
        expect(notifications.length, equals(1));
        expect(notifications.first['title'], equals('Test Notification'));
      });

      test('should return empty list when PostgrestException occurs', () async {
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('user_id', 'test-user-id'),
        ).thenReturn(mockTransformBuilder);
        when(
          mockTransformBuilder.order('created_at', ascending: false),
        ).thenReturn(mockTransformBuilder);

        // Mock PostgrestException
        when(
          mockTransformBuilder.select(),
        ).thenAnswer((_) async => PostgrestException(message: ''));

        final notifications = await notificationService.getUserNotifications();

        expect(notifications, isEmpty);
      });
    });

    group('markAsRead', () {
      test('should call update with correct parameters', () async {
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(
          mockQueryBuilder.update({'is_read': true}),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', 'notification-id'),
        ).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenAnswer((_) async => []);

        await notificationService.markAsRead('notification-id');

        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(mockQueryBuilder.update({'is_read': true})).called(1);
        verify(mockFilterBuilder.eq('id', 'notification-id')).called(1);
      });
    });

    group('deleteNotification', () {
      test('should call delete with correct parameters', () async {
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', 'notification-id'),
        ).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenAnswer((_) async => []);

        await notificationService.deleteNotification('notification-id');

        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(mockQueryBuilder.delete()).called(1);
        verify(mockFilterBuilder.eq('id', 'notification-id')).called(1);
      });
    });

    group('sendNotification', () {
      test('should insert notification with correct data', () async {
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenAnswer((_) async => []);

        await NotificationService.sendNotification(
          userId: 'user-123',
          title: 'Test Title',
          message: 'Test Message',
          type: 'test_type',
          relatedEntityType: 'test_entity',
          relatedEntityId: 'entity-123',
        );

        verify(mockSupabaseClient.from('notifications')).called(1);
        verify(
          mockQueryBuilder.insert({
            'user_id': 'user-123',
            'title': 'Test Title',
            'message': 'Test Message',
            'type': 'test_type',
            'related_entity_type': 'test_entity',
            'related_entity_id': 'entity-123',
          }),
        ).called(1);
      });
    });

    group('markAllAsRead', () {
      test('should update all unread notifications for current user', () async {
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(
          mockQueryBuilder.update({'is_read': true}),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('user_id', 'test-user-id'),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('is_read', false),
        ).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenAnswer((_) async => []);

        await notificationService.markAllAsRead();

        verify(mockQueryBuilder.update({'is_read': true})).called(1);
        verify(mockFilterBuilder.eq('user_id', 'test-user-id')).called(1);
        verify(mockFilterBuilder.eq('is_read', false)).called(1);
      });

      test('should not update when user is not authenticated', () async {
        when(mockAuthClient.currentUser).thenReturn(null);

        await notificationService.markAllAsRead();

        verifyNever(mockSupabaseClient.from('notifications'));
      });
    });

    group('deleteAllNotifications', () {
      test('should delete all notifications for current user', () async {
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('user_id', 'test-user-id'),
        ).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenAnswer((_) async => []);

        await notificationService.deleteAllNotifications();

        verify(mockQueryBuilder.delete()).called(1);
        verify(mockFilterBuilder.eq('user_id', 'test-user-id')).called(1);
      });
    });

    group('getNotificationById', () {
      test('should return notification data for valid ID', () async {
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', 'notification-id'),
        ).thenReturn(mockPostgrestFilterBuilder);
        when(mockPostgrestFilterBuilder.single()).thenAnswer(
          (_) async => {
            'id': 'notification-id',
            'title': 'Test Notification',
            'message': 'Test message',
          },
        );

        final result = await notificationService.getNotificationById(
          'notification-id',
        );

        expect(result, isNotNull);
        expect(result!['id'], equals('notification-id'));
        expect(result['title'], equals('Test Notification'));
      });

      test('should return null when PostgrestException occurs', () async {
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('id', 'notification-id'),
        ).thenReturn(mockPostgrestFilterBuilder);
        when(
          mockPostgrestFilterBuilder.single(),
        ).thenAnswer((_) async => PostgrestException());

        final result = await notificationService.getNotificationById(
          'notification-id',
        );

        expect(result, isNull);
      });
    });

    group('unreadCountStream', () {
      test('should emit count when _refreshUnreadCount is called', () async {
        // Mock the unread count query
        when(
          mockSupabaseClient.from('notifications'),
        ).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select('id')).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('user_id', 'test-user-id'),
        ).thenReturn(mockFilterBuilder);
        when(
          mockFilterBuilder.eq('is_read', false),
        ).thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select()).thenAnswer(
          (_) async => [
            {'id': '1'},
            {'id': '2'},
          ],
        );

        // Listen to the stream
        final streamValues = <int>[];
        final subscription = notificationService.unreadCountStream.listen(
          streamValues.add,
        );

        // Trigger refresh (this would normally be called internally)
        await notificationService.getUnreadCount();

        await Future.delayed(Duration(milliseconds: 100));

        expect(streamValues, isNotEmpty);
        subscription.cancel();
      });
    });

    group('Static notification methods', () {
      test(
        'sendWalkScheduledNotification should call sendNotification with correct parameters',
        () async {
          when(
            mockSupabaseClient.from('notifications'),
          ).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.insert(any)).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.select()).thenAnswer((_) async => []);

          await NotificationService.sendWalkScheduledNotification(
            walkerId: 'walker-123',
            walkId: 'walk-456',
          );

          verify(
            mockQueryBuilder.insert(
              argThat(containsPair('user_id', 'walker-123')),
            ),
          ).called(1);
          verify(
            mockQueryBuilder.insert(
              argThat(containsPair('type', 'walk_scheduled')),
            ),
          ).called(1);
          verify(
            mockQueryBuilder.insert(
              argThat(containsPair('related_entity_id', 'walk-456')),
            ),
          ).called(1);
        },
      );

      test(
        'sendNewMessageNotification should include sender name in message',
        () async {
          when(
            mockSupabaseClient.from('notifications'),
          ).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.insert(any)).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.select()).thenAnswer((_) async => []);

          await NotificationService.sendNewMessageNotification(
            receiverId: 'receiver-123',
            walkId: 'walk-456',
            senderName: 'John Doe',
          );

          verify(
            mockQueryBuilder.insert(
              argThat(
                containsPair(
                  'message',
                  'You have a new message from John Doe!',
                ),
              ),
            ),
          ).called(1);
        },
      );

      test(
        'sendWalkReminderNotification should include minutes and dog name',
        () async {
          when(
            mockSupabaseClient.from('notifications'),
          ).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.insert(any)).thenReturn(mockQueryBuilder);
          when(mockQueryBuilder.select()).thenAnswer((_) async => []);

          await NotificationService.sendWalkReminderNotification(
            userId: 'user-123',
            walkId: 'walk-456',
            dogName: 'Buddy',
            minutesUntilWalk: 15,
          );

          verify(
            mockQueryBuilder.insert(
              argThat(
                containsPair('message', 'Buddy\'s walk starts in 15 minutes!'),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('dispose', () {
      test('should unsubscribe channel and close stream controller', () {
        // Setup a mock channel
        notificationService.startListening();

        // Mock the channel unsubscribe
        when(
          mockChannel.unsubscribe(),
        ).thenAnswer((_) async => RealtimeSubscribeStatus.subscribed);

        notificationService.dispose();

        // Verify the stream controller is closed by trying to add to it
        expect(
          () => notificationService.unreadCountStream.listen((_) {}),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
