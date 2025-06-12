import 'package:dogwalkz/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:your_app/location_service.dart'; 


class MockGeolocator extends Mock implements GeolocatorPlatform {}

class MockPermission extends Mock {}

void main() {
  group('LocationService Unit Tests', () {
    late MockGeolocator mockGeolocator;

    setUp(() {
    
      mockGeolocator = MockGeolocator();

     
      GeolocatorPlatform.instance = mockGeolocator;
    });

    group('getCurrentLocation method tests', () {
      test(
        'should return Position when permission is granted and location is available',
        () async {
          
          final mockPosition = Position(
            latitude: 37.7749, 
            longitude: -122.4194, 
            timestamp: DateTime.now(),
            accuracy: 5.0, 
            altitude: 10.0,
            altitudeAccuracy: 3.0,
            heading: 90.0, 
            headingAccuracy: 1.0,
            speed: 0.0, /
            speedAccuracy: 0.5,
          );

          
          when(
            mockGeolocator.requestPermission(),
          ).thenAnswer((_) async => LocationPermission.whileInUse);

          
          when(
            mockGeolocator.getCurrentPosition(
              locationSettings: anyNamed('locationSettings'),
            ),
          ).thenAnswer((_) async => mockPosition);

         
          final result = await LocationService.getCurrentLocation();

         
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
     
        when(
          mockGeolocator.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

       
        final result = await LocationService.getCurrentLocation();

        // Assert: Should return null when permission is denied
        expect(
          result,
          isNull,
          reason: 'Should return null when location permission is denied',
        );

        
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
        
          when(
            mockGeolocator.requestPermission(),
          ).thenAnswer((_) async => LocationPermission.deniedForever);

          
          final result = await LocationService.getCurrentLocation();

         
          expect(
            result,
            isNull,
            reason: 'Should return null when permission is permanently denied',
          );
        },
      );

      test('should handle Geolocator exceptions gracefully', () async {
       
        when(
          mockGeolocator.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);

        when(
          mockGeolocator.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenThrow(LocationServiceDisabledException());

        final result = await LocationService.getCurrentLocation();

      
        expect(
          result,
          isNull,
          reason: 'Should return null when location service throws exception',
        );
      });

      test('should handle permission request exceptions gracefully', () async {
       
        when(
          mockGeolocator.requestPermission(),
        ).thenThrow(Exception('Permission service unavailable'));

     
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
            speed: 2.5, 
            speedAccuracy: 0.5,
          ),
        ]);

        
        when(
          mockGeolocator.getPositionStream(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) => mockStream);

       
        final stream = LocationService.getLocationStream();

     
        expect(
          stream,
          isA<Stream<Position>>(),
          reason: 'Should return a Stream of Position objects',
        );

       
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
            latitude: 37.7750, 
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

       
        final stream = LocationService.getLocationStream();
        final receivedPositions = await stream.take(2).toList();

       
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
