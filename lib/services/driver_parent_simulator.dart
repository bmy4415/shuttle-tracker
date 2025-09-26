import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';

/// Simulate 3 parents moving in circular orbits around the driver location
class DriverParentSimulator {
  static final DriverParentSimulator _instance = DriverParentSimulator._internal();
  factory DriverParentSimulator() => _instance;
  DriverParentSimulator._internal();

  Timer? _simulationTimer;
  LocationData? _driverLocation;
  final List<ParentData> _parentLocations = [];
  bool _isRunning = false;

  // Simulation parameters for each parent
  final List<double> _distances = [100.0, 200.0, 300.0]; // meters from driver
  final List<double> _speeds = [0.15, 0.12, 0.08]; // angular speed (radians per update) - increased for more visible movement
  final List<double> _currentAngles = [0.0, math.pi * 2/3, math.pi * 4/3]; // starting angles
  final List<String> _parentNames = ['김엄마', '이엄마', '박엄마'];
  final List<String> _childNames = ['김민수', '이영희', '박철수'];

  // Stream controller
  final StreamController<List<ParentData>> _streamController =
    StreamController<List<ParentData>>.broadcast();

  Stream<List<ParentData>> get parentLocationStream => _streamController.stream;
  List<ParentData> get currentParentLocations => List.unmodifiable(_parentLocations);

  /// Start simulation with driver's initial location
  void startSimulation(LocationData driverLocation) {
    if (_isRunning) {
      stopSimulation();
    }

    _driverLocation = driverLocation;
    _isRunning = true;

    // Initialize parent locations
    _initializeParentLocations();

    // Start periodic updates (every 1.5 seconds) - reduced for more visible changes
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _updateParentLocations();
    });

    print('DriverParentSimulator: Started simulation with ${_parentLocations.length} parents');
  }

  /// Update driver location and recalculate parent positions
  void updateDriverLocation(LocationData newDriverLocation) {
    _driverLocation = newDriverLocation;
    if (_isRunning) {
      _updateParentLocations();
    }
  }

  /// Stop simulation
  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _isRunning = false;
    _parentLocations.clear();

    // Emit empty list to update UI
    _streamController.add([]);
    print('DriverParentSimulator: Stopped simulation');
  }

  /// Initialize 3 parent locations around driver
  void _initializeParentLocations() {
    if (_driverLocation == null) return;

    _parentLocations.clear();

    for (int i = 0; i < 3; i++) {
      final parentLocation = _calculateParentPosition(i);
      final parent = ParentData(
        parentId: 'PARENT_${i + 1}',
        parentName: _parentNames[i],
        childName: _childNames[i],
        latitude: parentLocation.latitude,
        longitude: parentLocation.longitude,
        accuracy: parentLocation.accuracy,
        timestamp: DateTime.now(),
        isWaitingForPickup: false, // No parents are waiting for pickup
      );

      _parentLocations.add(parent);
    }

    _streamController.add(_parentLocations);
  }

  /// Update all parent locations (move them along circular orbits)
  void _updateParentLocations() {
    if (_driverLocation == null || _parentLocations.isEmpty) return;

    bool hasChanges = false;

    for (int i = 0; i < _parentLocations.length && i < 3; i++) {
      // Update angle for circular motion
      _currentAngles[i] += _speeds[i];
      if (_currentAngles[i] > math.pi * 2) {
        _currentAngles[i] -= math.pi * 2;
      }

      // Calculate new position
      final newLocation = _calculateParentPosition(i);

      // Update parent data
      final parent = _parentLocations[i];
      final updatedParent = ParentData(
        parentId: parent.parentId,
        parentName: parent.parentName,
        childName: parent.childName,
        latitude: newLocation.latitude,
        longitude: newLocation.longitude,
        accuracy: newLocation.accuracy,
        timestamp: DateTime.now(),
        isWaitingForPickup: parent.isWaitingForPickup,
      );

      _parentLocations[i] = updatedParent;
      hasChanges = true;
    }

    if (hasChanges) {
      _streamController.add(_parentLocations);
      print('DriverParentSimulator: Updated ${_parentLocations.length} parent locations');
    }
  }

  /// Calculate parent position based on circular orbit around driver
  LocationData _calculateParentPosition(int parentIndex) {
    if (_driverLocation == null || parentIndex >= 3) {
      throw ArgumentError('Invalid parent index or driver location');
    }

    final distance = _distances[parentIndex];
    final angle = _currentAngles[parentIndex];

    // Convert distance in meters to approximate lat/lng offset
    // Rough approximation: 1 degree ≈ 111,000 meters
    final latOffset = (distance * math.cos(angle)) / 111000;
    final lngOffset = (distance * math.sin(angle)) / (111000 * math.cos(_driverLocation!.latitude * math.pi / 180));

    final newLatitude = _driverLocation!.latitude + latOffset;
    final newLongitude = _driverLocation!.longitude + lngOffset;

    return LocationData(
      latitude: newLatitude,
      longitude: newLongitude,
      accuracy: 15.0,
      altitude: _driverLocation!.altitude,
      speed: _speeds[parentIndex] * distance, // Linear speed approximation
      timestamp: DateTime.now(),
      busId: 'PARENT_${parentIndex + 1}',
      driverId: _parentNames[parentIndex],
    );
  }

  /// Dispose resources
  void dispose() {
    stopSimulation();
    _streamController.close();
    print('DriverParentSimulator: Disposed');
  }
}