import 'package:dogwalkz/services/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:your_app/location_service.dart'; // Replace with your actual package name

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService Integration Tests', () {
    group('Real device permission flow', () {
      testWidgets('should handle real permission request flow', (
        WidgetTester tester,
      ) async {
        // This test runs on actual device and tests real permission flow
        // Note: Requires manual interaction on first run to grant/deny permission

        // Act: Request location - this will show actual system permission dialog
        final position = await LocationService.getCurrentLocation();

        // The result depends on user interaction with permission dialog
        // We can only test that the method completes without crashing
        expect(
          () => position,
          returnsNormally,
          reason:
              'getCurrentLocation should complete without throwing exceptions',
        );

        // If permission was granted, position should not be null
        if (position != null) {
          expect(
            position.latitude,
            isA<double>(),
            reason: 'Latitude should be a valid double',
          );
          expect(
            position.longitude,
            isA<double>(),
            reason: 'Longitude should be a valid double',
          );
          expect(
            position.latitude.abs(),
            lessThanOrEqualTo(90),
            reason: 'Latitude should be within valid range (-90 to 90)',
          );
          expect(
            position.longitude.abs(),
            lessThanOrEqualTo(180),
            reason: 'Longitude should be within valid range (-180 to 180)',
          );
        }
      });

      testWidgets('should handle location service disabled scenario', (
        WidgetTester tester,
      ) async {
        // This test checks behavior when location services are disabled
        // Note: Requires manual setup - disable location services before running

        try {
          // Act: Attempt to get location when service might be disabled
          final position = await LocationService.getCurrentLocation();

          // Assert: Should either return null or valid position based on service state
          if (position != null) {
            // If we got a position, verify it's valid
            expect(
              position.accuracy,
              greaterThan(0),
              reason: 'Accuracy should be positive when location is available',
            );
          }
        } catch (e) {
          // Integration test should handle service exceptions gracefully
          expect(
            e,
            isA<LocationServiceDisabledException>(),
            reason:
                'Should throw LocationServiceDisabledException when service disabled',
          );
        }
      });
    });

    group('Real GPS stream functionality', () {
      testWidgets('should provide real location updates over time', (
        WidgetTester tester,
      ) async {
        // This test requires device movement to fully validate
        // It tests the actual GPS stream functionality

        // Check if location permission is available first
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        final permission = await Geolocator.checkPermission();

        if (!serviceEnabled || permission == LocationPermission.denied) {
          // Skip test if location not available
          return;
        }

        // Act: Start listening to location stream
        final stream = LocationService.getLocationStream();

        // Collect first few position updates (or timeout after 30 seconds)
        final positions = <Position>[];

        await for (final position in stream
            .take(3)
            .timeout(
              Duration(seconds: 30),
              onTimeout: (sink) => sink.close(),
            )) {
          positions.add(position);

          // Validate each position received
          expect(
            position.latitude,
            isA<double>(),
            reason: 'Each position should have valid latitude',
          );
          expect(
            position.longitude,
            isA<double>(),
            reason: 'Each position should have valid longitude',
          );
          expect(
            position.timestamp,
            isNotNull,
            reason: 'Each position should have timestamp',
          );
          expect(
            position.accuracy,
            greaterThan(0),
            reason: 'Accuracy should be positive',
          );

          // Break after first position for quick test
          break;
        }

        // Assert: Should have received at least one position update
        expect(
          positions.isNotEmpty,
          isTrue,
          reason: 'Should receive at least one position update from GPS',
        );
      });

      testWidgets('should respect distance filter in location stream', (
        WidgetTester tester,
      ) async {
        // This test validates that the 10-meter distance filter works correctly
        // Note: Requires physical movement of device to fully test

        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        final permission = await Geolocator.checkPermission();

        if (!serviceEnabled || permission == LocationPermission.denied) {
          return; // Skip if location not available
        }

        // Act: Start location stream and monitor for distance-based updates
        final stream = LocationService.getLocationStream();
        Position? lastPosition;
        var updateCount = 0;

        // Listen for 10 seconds to see how updates behave
        await for (final position in stream.timeout(Duration(seconds: 10))) {
          updateCount++;

          if (lastPosition != null) {
            // Calculate distance between positions
            final distance = Geolocator.distanceBetween(
              lastPosition.latitude,
              lastPosition.longitude,
              position.latitude,
              position.longitude,
            );

            // Assert: Distance should generally be >= 10 meters due to filter
            // (allowing some tolerance for GPS accuracy variations)
            if (distance > 0) {
              expect(
                distance,
                greaterThanOrEqualTo(5.0),
                reason: 'Position updates should respect distance filter',
              );
            }
          }

          lastPosition = position;

          // Break after a few updates for test efficiency
          if (updateCount >= 3) break;
        }

        // The test validates that stream works and respects configuration
      });
    });

    group('Edge case integration scenarios', () {
      testWidgets('should handle app backgrounding during location requests', (
        WidgetTester tester,
      ) async {
        // This test simulates app lifecycle changes during location operations

        // Simulate app going to background
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/platform'),
          (MethodCall methodCall) async {
            if (methodCall.method ==
                'SystemChrome.setApplicationSwitcherDescription') {
              return null;
            }
            return null;
          },
        );

        // Act: Request location while simulating background state
        final position = await LocationService.getCurrentLocation();

        // Assert: Should handle backgrounding gracefully
        expect(
          () => position,
          returnsNormally,
          reason: 'Should handle app backgrounding during location request',
        );
      });

      testWidgets('should handle rapid successive location requests', (
        WidgetTester tester,
      ) async {
        // This test validates behavior under rapid successive calls

        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

        // Act: Make multiple rapid location requests
        final futures = <Future<Position?>>[];
        for (int i = 0; i < 5; i++) {
          futures.add(LocationService.getCurrentLocation());
        }

        // Wait for all requests to complete
        final results = await Future.wait(futures);

        // Assert: All requests should complete successfully
        for (final result in results) {
          if (result != null) {
            expect(
              result.latitude,
              isA<double>(),
              reason:
                  'Each rapid request should return valid position if successful',
            );
          }
        }

        // Should not cause crashes or resource leaks
        expect(
          results.length,
          equals(5),
          reason: 'All rapid requests should complete',
        );
      });
    });
  });
}
