import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/models/location_data.dart';
import 'package:shuttle_tracker/services/location_service.dart';

void main() {
  group('LocationData Model Tests', () {
    test('LocationData should create instance with required fields', () {
      final now = DateTime.now();
      final locationData = LocationData(
        latitude: 37.5665,
        longitude: 126.9780,
        timestamp: now,
        busId: 'BUS001',
        driverId: 'DRIVER001',
      );

      expect(locationData.latitude, 37.5665);
      expect(locationData.longitude, 126.9780);
      expect(locationData.timestamp, now);
      expect(locationData.busId, 'BUS001');
      expect(locationData.driverId, 'DRIVER001');
    });

    test('LocationData should convert to Map correctly', () {
      final now = DateTime.now();
      final locationData = LocationData(
        latitude: 37.5665,
        longitude: 126.9780,
        accuracy: 10.5,
        altitude: 50.0,
        speed: 30.0,
        timestamp: now,
        busId: 'BUS001',
        driverId: 'DRIVER001',
      );

      final map = locationData.toMap();

      expect(map['latitude'], 37.5665);
      expect(map['longitude'], 126.9780);
      expect(map['accuracy'], 10.5);
      expect(map['altitude'], 50.0);
      expect(map['speed'], 30.0);
      expect(map['timestamp'], now.millisecondsSinceEpoch);
      expect(map['busId'], 'BUS001');
      expect(map['driverId'], 'DRIVER001');
    });

    test('LocationData should create from Map correctly', () {
      final now = DateTime.now();
      final map = {
        'latitude': 37.5665,
        'longitude': 126.9780,
        'accuracy': 10.5,
        'altitude': 50.0,
        'speed': 30.0,
        'timestamp': now.millisecondsSinceEpoch,
        'busId': 'BUS001',
        'driverId': 'DRIVER001',
      };

      final locationData = LocationData.fromMap(map);

      expect(locationData.latitude, 37.5665);
      expect(locationData.longitude, 126.9780);
      expect(locationData.accuracy, 10.5);
      expect(locationData.altitude, 50.0);
      expect(locationData.speed, 30.0);
      expect(locationData.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(locationData.busId, 'BUS001');
      expect(locationData.driverId, 'DRIVER001');
    });

    test('LocationData should handle null optional fields', () {
      final now = DateTime.now();
      final locationData = LocationData(
        latitude: 37.5665,
        longitude: 126.9780,
        timestamp: now,
        busId: 'BUS001',
        driverId: 'DRIVER001',
      );

      expect(locationData.accuracy, null);
      expect(locationData.altitude, null);
      expect(locationData.speed, null);

      final map = locationData.toMap();
      expect(map['accuracy'], null);
      expect(map['altitude'], null);
      expect(map['speed'], null);
    });

    test('LocationData toString should contain key information', () {
      final now = DateTime.now();
      final locationData = LocationData(
        latitude: 37.5665,
        longitude: 126.9780,
        timestamp: now,
        busId: 'BUS001',
        driverId: 'DRIVER001',
      );

      final stringRepresentation = locationData.toString();

      expect(stringRepresentation, contains('37.5665'));
      expect(stringRepresentation, contains('126.978'));
      expect(stringRepresentation, contains('BUS001'));
    });
  });

  group('LocationService Tests', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    tearDown(() {
      locationService.dispose();
    });

    test('LocationService should be singleton', () {
      final instance1 = LocationService();
      final instance2 = LocationService();

      expect(identical(instance1, instance2), true);
    });

    test('LocationService should initialize with tracking stopped', () {
      expect(locationService.isTracking, false);
    });

    test('LocationService should provide location stream', () {
      final stream = locationService.locationStream;

      expect(stream, isA<Stream<LocationData>>());
    });

    test('LocationService should stop tracking correctly', () {
      locationService.stopLocationTracking();

      expect(locationService.isTracking, false);
    });
  });
}