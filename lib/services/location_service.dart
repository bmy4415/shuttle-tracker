import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';

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


  /// Get current location once
  Future<LocationData?> getCurrentLocation({
    required String busId,
    required String driverId,
  }) async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // 속도 최적화
          distanceFilter: 0,
          timeLimit: Duration(seconds: 5), // 5초 제한
        ),
      );

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
        distanceFilter: 10, // 10m 이동 시 업데이트 (low accuracy에 맞게 조정)
        timeLimit: Duration(seconds: 10), // 10초 제한
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

  /// Clean up resources
  void dispose() {
    stopLocationTracking();
    _locationController?.close();
    _locationController = null;
  }
}