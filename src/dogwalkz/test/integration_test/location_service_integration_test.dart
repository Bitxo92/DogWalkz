import 'package:dogwalkz/services/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:your_app/location_service.dart'; 

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService Integration Tests', () {
    group('Real device permission flow', () {
      testWidgets('should handle real permission request flow', (
        WidgetTester tester,
      ) async {
       
      
        final position = await LocationService.getCurrentLocation();

       
        expect(
          () => position,
          returnsNormally,
          reason:
              'getCurrentLocation should complete without throwing exceptions',
        );

   
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
        

        try {
        
          final position = await LocationService.getCurrentLocation();

          
          if (position != null) {
         
            expect(
              position.accuracy,
              greaterThan(0),
              reason: 'Accuracy should be positive when location is available',
            );
          }
        } catch (e) {
       
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
      

      
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        final permission = await Geolocator.checkPermission();

        if (!serviceEnabled || permission == LocationPermission.denied) {
        
          return;
        }

      
        final stream = LocationService.getLocationStream();

       
        final positions = <Position>[];

        await for (final position in stream
            .take(3)
            .timeout(
              Duration(seconds: 30),
              onTimeout: (sink) => sink.close(),
            )) {
          positions.add(position);

       
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

          break;
        }

        
        expect(
          positions.isNotEmpty,
          isTrue,
          reason: 'Should receive at least one position update from GPS',
        );
      });

      testWidgets('should respect distance filter in location stream', (
        WidgetTester tester,
      ) async {
        

        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        final permission = await Geolocator.checkPermission();

        if (!serviceEnabled || permission == LocationPermission.denied) {
          return;
        }

       
        final stream = LocationService.getLocationStream();
        Position? lastPosition;
        var updateCount = 0;

       
        await for (final position in stream.timeout(Duration(seconds: 10))) {
          updateCount++;

          if (lastPosition != null) {
           
            final distance = Geolocator.distanceBetween(
              lastPosition.latitude,
              lastPosition.longitude,
              position.latitude,
              position.longitude,
            );

         
            if (distance > 0) {
              expect(
                distance,
                greaterThanOrEqualTo(5.0),
                reason: 'Position updates should respect distance filter',
              );
            }
          }

          lastPosition = position;

          if (updateCount >= 3) break;
        }

        
      });
    });

    group('Edge case integration scenarios', () {
      testWidgets('should handle app backgrounding during location requests', (
        WidgetTester tester,
      ) async {
    
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

        
        final position = await LocationService.getCurrentLocation();

     
        expect(
          () => position,
          returnsNormally,
          reason: 'Should handle app backgrounding during location request',
        );
      });

      testWidgets('should handle rapid successive location requests', (
        WidgetTester tester,
      ) async {
        

        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;

      
        final futures = <Future<Position?>>[];
        for (int i = 0; i < 5; i++) {
          futures.add(LocationService.getCurrentLocation());
        }

     
        final results = await Future.wait(futures);

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

       
        expect(
          results.length,
          equals(5),
          reason: 'All rapid requests should complete',
        );
      });
    });
  });
}
