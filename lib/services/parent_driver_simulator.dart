import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/location_data.dart';

/// Simulate driver location moving in a circular orbit around the parent location
class ParentDriverSimulator {
  static final ParentDriverSimulator _instance = ParentDriverSimulator._internal();
  factory ParentDriverSimulator() => _instance;
  ParentDriverSimulator._internal();

  Timer? _simulationTimer;
  LocationData? _parentLocation;
  LocationData? _driverLocation;
  bool _isRunning = false;

  // Simulation parameters for driver
  final double _distance = 500.0; // meters from parent (larger orbit for bus)
  final double _speed = 0.1; // angular speed (radians per update) - slower for bus
  double _currentAngle = 0.0; // starting angle

  // Stream controller
  final StreamController<LocationData> _streamController =
    StreamController<LocationData>.broadcast();

  Stream<LocationData> get driverLocationStream => _streamController.stream;
  LocationData? get currentDriverLocation => _driverLocation;

  /// Start simulation with parent's initial location
  void startSimulation(LocationData parentLocation) {
    if (_isRunning) {
      stopSimulation();
    }

    _parentLocation = parentLocation;
    _isRunning = true;

    // Initialize driver location
    _initializeDriverLocation();

    // Start periodic updates (every 2 seconds) - frequent for smooth movement
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      _updateDriverLocation();
    });

    print('ParentDriverSimulator: Started simulation with driver location');
  }

  /// Update parent location and recalculate driver position
  void updateParentLocation(LocationData newParentLocation) {
    _parentLocation = newParentLocation;
    if (_isRunning) {
      _updateDriverLocation();
    }
  }

  /// Stop simulation
  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isRunning = false;
    _driverLocation = null;

    print('ParentDriverSimulator: Stopped simulation');
  }

  /// Initialize driver location around parent
  void _initializeDriverLocation() {
    if (_parentLocation == null) return;

    _driverLocation = _calculateDriverPosition();

    if (_driverLocation != null) {
      _streamController.add(_driverLocation!);
      print('ParentDriverSimulator: Driver initialized at ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
    }
  }

  /// Update driver location (move along circular orbit)
  void _updateDriverLocation() {
    if (_parentLocation == null) return;

    // Update angle for circular motion
    _currentAngle += _speed;
    if (_currentAngle > math.pi * 2) {
      _currentAngle -= math.pi * 2;
    }

    // Calculate new position
    final newLocation = _calculateDriverPosition();

    if (newLocation != null) {
      _driverLocation = newLocation;
      _streamController.add(_driverLocation!);
      print('ParentDriverSimulator: Driver updated to ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
    }
  }

  /// Calculate driver position based on circular orbit around parent
  LocationData? _calculateDriverPosition() {
    if (_parentLocation == null) {
      return null;
    }

    // Convert distance in meters to approximate lat/lng offset
    // Rough approximation: 1 degree ≈ 111,000 meters
    final latOffset = (_distance * math.cos(_currentAngle)) / 111000;
    final lngOffset = (_distance * math.sin(_currentAngle)) / (111000 * math.cos(_parentLocation!.latitude * math.pi / 180));

    final newLatitude = _parentLocation!.latitude + latOffset;
    final newLongitude = _parentLocation!.longitude + lngOffset;

    return LocationData(
      latitude: newLatitude,
      longitude: newLongitude,
      accuracy: 10.0,
      altitude: _parentLocation!.altitude,
      speed: _speed * _distance, // Linear speed approximation
      timestamp: DateTime.now(),
      busId: 'BUS001',
      driverId: 'DRIVER001',
    );
  }

  /// Dispose resources
  void dispose() {
    stopSimulation();
    _streamController.close();
    print('ParentDriverSimulator: Disposed');
  }
}