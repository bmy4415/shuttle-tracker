import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';

class LocationService {
  static LocationService? _instance;
  LocationService._internal();
  
  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  StreamController<LocationData>? _locationController;
  StreamSubscription<Position>? _locationSubscription;
  bool _isTracking = false;

  Stream<LocationData> get locationStream {
    _locationController ??= StreamController<LocationData>.broadcast();
    return _locationController!.stream;
  }

  bool get isTracking => _isTracking;

  /// Check if location services are enabled and permissions are granted
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }


  /// Get simulated bus location (500m away from user)
  Future<LocationData?> getSimulatedBusLocation({
    required String busId,
    required String driverId,
    required LocationData userLocation,
  }) async {
    // 사용자 위치에서 북쪽으로 500m 떨어진 지점 (대략 0.0045도)
    final busLatitude = userLocation.latitude + 0.0045;
    final busLongitude = userLocation.longitude + 0.002;

    return LocationData(
      latitude: busLatitude,
      longitude: busLongitude,
      accuracy: 10.0,
      altitude: userLocation.altitude,
      speed: 20.0, // 20km/h로 설정
      timestamp: DateTime.now(),
      busId: busId,
      driverId: driverId,
    );
  }

  /// Get simulated parent locations (around 500m from driver)
  List<ParentData> getSimulatedParentLocations(LocationData driverLocation) {
    final now = DateTime.now();

    return [
      ParentData(
        parentId: 'PARENT_001',
        parentName: '김엄마',
        latitude: driverLocation.latitude + 0.003, // 북동쪽 300m
        longitude: driverLocation.longitude + 0.004,
        accuracy: 10.0,
        timestamp: now,
        childName: '김민수',
        isWaitingForPickup: now.second % 20 < 10, // 주기적으로 변경
      ),
      ParentData(
        parentId: 'PARENT_002',
        parentName: '이엄마',
        latitude: driverLocation.latitude - 0.002, // 남서쪽 200m
        longitude: driverLocation.longitude - 0.003,
        accuracy: 8.0,
        timestamp: now,
        childName: '이서연',
        isWaitingForPickup: now.second % 30 < 15,
      ),
      ParentData(
        parentId: 'PARENT_003',
        parentName: '박아빠',
        latitude: driverLocation.latitude + 0.001, // 북서쪽 100m
        longitude: driverLocation.longitude - 0.002,
        accuracy: 12.0,
        timestamp: now,
        childName: '박지훈',
        isWaitingForPickup: false,
      ),
    ];
  }

  /// Get current location once (fallback method)
  Future<LocationData?> getCurrentLocation({
    required String busId,
    required String driverId,
  }) async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      // Try to get last known position first for immediate response
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        print('Using last known position: ${position?.latitude}, ${position?.longitude}');
      } catch (e) {
        print('No last known position available, getting current: $e');
      }

      // If no last known position, get current position
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            distanceFilter: 0,
            timeLimit: Duration(seconds: 5),
          ),
        );
        print('Got current position: ${position.latitude}, ${position.longitude}');
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
        busId: busId,
        driverId: driverId,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Start real-time location stream (new primary method)
  Stream<LocationData> startLocationStream({
    required String busId,
    required String driverId,
  }) async* {
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    print('Starting real-time location stream...');

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.low, // 배터리 최적화
      distanceFilter: 15, // 15m 이동시 업데이트 (5m에서 증가)
      timeLimit: Duration(seconds: 15), // 15초로 증가
    );

    // Convert Position stream to LocationData stream
    await for (final Position position in Geolocator.getPositionStream(locationSettings: locationSettings)) {
      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: DateTime.now(),
        busId: busId,
        driverId: driverId,
      );

      print('Location stream update: ${locationData.latitude.toStringAsFixed(6)}, ${locationData.longitude.toStringAsFixed(6)}');
      yield locationData;
    }
  }

  /// Start real-time location tracking
  Future<bool> startLocationTracking({
    required String busId,
    required String driverId,
    int intervalSeconds = 10,
  }) async {
    if (_isTracking) {
      return true;
    }

    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return false;
      }

      _locationController ??= StreamController<LocationData>.broadcast();

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.low, // 속도 최적화
        distanceFilter: 20, // 20m 이동 시 업데이트 (배터리 최적화)
        timeLimit: Duration(seconds: 30), // 30초로 증가
      );

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        final locationData = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          timestamp: DateTime.now(),
          busId: busId,
          driverId: driverId,
        );

        _locationController?.add(locationData);
      });

      _isTracking = true;
      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
  }

  /// Check if location is too old (older than 5 minutes)
  bool _isLocationTooOld(DateTime? timestamp) {
    if (timestamp == null) return true;
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes > 5; // 5분 이상 오래된 위치는 새로 획득
  }

  /// Clean up resources
  void dispose() {
    stopLocationTracking();
    _locationController?.close();
    _locationController = null;
  }
}