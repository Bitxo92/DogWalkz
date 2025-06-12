import 'package:dogwalkz/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:your_app/location_service.dart'; // Replace with your actual package name

// Mock classes for external dependencies
class MockGeolocator extends Mock implements GeolocatorPlatform {}

class MockPermission extends Mock {}

void main() {
  group('LocationService Unit Tests', () {
    late MockGeolocator mockGeolocator;

    setUp(() {
      // Initialize mocks before each test to ensure clean state
      mockGeolocator = MockGeolocator();

      // Set up Geolocator to use our mock
      GeolocatorPlatform.instance = mockGeolocator;
    });

    group('getCurrentLocation method tests', () {
      test(
        'should return Position when permission is granted and location is available',
        () async {
          // Arrange: Create a mock position with realistic GPS coordinates
          final mockPosition = Position(
            latitude: 37.7749, // San Francisco latitude
            longitude: -122.4194, // San Francisco longitude
            timestamp: DateTime.now(),
            accuracy: 5.0, // 5 meter accuracy
            altitude: 10.0,
            altitudeAccuracy: 3.0,
            heading: 90.0, // Facing east
            headingAccuracy: 1.0,
            speed: 0.0, // Stationary
            speedAccuracy: 0.5,
          );

          // Mock successful permission grant
          when(
            mockGeolocator.requestPermission(),
          ).thenAnswer((_) async => LocationPermission.whileInUse);

          // Mock successful location retrieval
          when(
            mockGeolocator.getCurrentPosition(
              locationSettings: anyNamed('locationSettings'),
            ),
          ).thenAnswer((_) async => mockPosition);

          // Act: Call the method under test
          final result = await LocationService.getCurrentLocation();

          // Assert: Verify the result matches our expectations
          expect(
            result,
            isNotNull,
            reason: 'Should return a Position object when permission granted',
          );
          expect(
            result!.latitude,
            equals(37.7749),
            reason: 'Latitude should match the mocked value',
          );
          expect(
            result.longitude,
            equals(-122.4194),
            reason: 'Longitude should match the mocked value',
          );
          expect(
            result.accuracy,
            equals(5.0),
            reason: 'Accuracy should match the mocked value',
          );
        },
      );

      test('should return null when location permission is denied', () async {
        // Arrange: Mock permission denial scenario
        when(
          mockGeolocator.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

        // Act: Attempt to get location without permission
        final result = await LocationService.getCurrentLocation();

        // Assert: Should return null when permission is denied
        expect(
          result,
          isNull,
          reason: 'Should return null when location permission is denied',
        );

        // Verify that permission was requested but location was not
        verify(mockGeolocator.requestPermission()).called(1);
        verifyNever(
          mockGeolocator.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        );
      });

      test(
        'should return null when location permission is permanently denied',
        () async {
          // Arrange: Mock permanent permission denial
          when(
            mockGeolocator.requestPermission(),
          ).thenAnswer((_) async => LocationPermission.deniedForever);

          // Act: Attempt to get location with permanently denied permission
          final result = await LocationService.getCurrentLocation();

          // Assert: Should handle permanent denial gracefully
          expect(
            result,
            isNull,
            reason: 'Should return null when permission is permanently denied',
          );
        },
      );

      test('should handle Geolocator exceptions gracefully', () async {
        // Arrange: Mock permission granted but location service throws exception
        when(
          mockGeolocator.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);

        when(
          mockGeolocator.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenThrow(LocationServiceDisabledException());

        // Act: Call method that should handle the exception
        final result = await LocationService.getCurrentLocation();

        // Assert: Should not throw exception, should return null
        expect(
          result,
          isNull,
          reason: 'Should return null when location service throws exception',
        );
      });

      test('should handle permission request exceptions gracefully', () async {
        // Arrange: Mock permission request throwing an exception
        when(
          mockGeolocator.requestPermission(),
        ).thenThrow(Exception('Permission service unavailable'));

        // Act & Assert: Should not throw unhandled exception
        final result = await LocationService.getCurrentLocation();
        expect(
          result,
          isNull,
          reason: 'Should return null when permission request fails',
        );
      });
    });

    group('getLocationStream method tests', () {
      test('should return a Stream<Position> with correct configuration', () {
        // Arrange: Create a mock stream controller for position updates
        final mockStream = Stream<Position>.fromIterable([
          Position(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 10.0,
            altitudeAccuracy: 3.0,
            heading: 90.0,
            headingAccuracy: 1.0,
            speed: 2.5, // 2.5 m/s movement
            speedAccuracy: 0.5,
          ),
        ]);

        // Mock the position stream with expected settings
        when(
          mockGeolocator.getPositionStream(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) => mockStream);

        // Act: Get the location stream
        final stream = LocationService.getLocationStream();

        // Assert: Verify stream is returned and has expected type
        expect(
          stream,
          isA<Stream<Position>>(),
          reason: 'Should return a Stream of Position objects',
        );

        // Verify that the stream was created with correct settings
        verify(
          mockGeolocator.getPositionStream(
            locationSettings: argThat(
              isA<LocationSettings>()
                  .having((s) => s.accuracy, 'accuracy', LocationAccuracy.best)
                  .having((s) => s.distanceFilter, 'distanceFilter', 10),
              named: 'locationSettings',
            ),
          ),
        ).called(1);
      });

      test('should emit position updates when device moves', () async {
        // Arrange: Create multiple position updates simulating movement
        final positions = [
          Position(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 10.0,
            altitudeAccuracy: 3.0,
            heading: 90.0,
            headingAccuracy: 1.0,
            speed: 2.5,
            speedAccuracy: 0.5,
          ),
          Position(
            latitude: 37.7750, // Slight movement north
            longitude: -122.4194,
            timestamp: DateTime.now().add(Duration(seconds: 5)),
            accuracy: 5.0,
            altitude: 10.0,
            altitudeAccuracy: 3.0,
            heading: 90.0,
            headingAccuracy: 1.0,
            speed: 2.5,
            speedAccuracy: 0.5,
          ),
        ];

        final mockStream = Stream<Position>.fromIterable(positions);
        when(
          mockGeolocator.getPositionStream(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) => mockStream);

        // Act: Listen to the stream and collect positions
        final stream = LocationService.getLocationStream();
        final receivedPositions = await stream.take(2).toList();

        // Assert: Should receive all position updates
        expect(
          receivedPositions.length,
          equals(2),
          reason: 'Should receive both position updates',
        );
        expect(
          receivedPositions[0].latitude,
          equals(37.7749),
          reason: 'First position should have correct latitude',
        );
        expect(
          receivedPositions[1].latitude,
          equals(37.7750),
          reason: 'Second position should show movement',
        );
      });
    });
  });
}
