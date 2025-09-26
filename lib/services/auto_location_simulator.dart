import 'dart:async';
import 'dart:math';
import '../models/location_data.dart';
import '../models/parent_data.dart';

/// Auto-moving location simulator for remote users
/// This will be replaced with real server communication later
class AutoLocationSimulator {
  static final AutoLocationSimulator _instance = AutoLocationSimulator._internal();
  factory AutoLocationSimulator() => _instance;
  AutoLocationSimulator._internal();

  Timer? _updateTimer;
  final Random _random = Random();

  // Movement parameters - optimized for battery life
  static const double _movementSpeed = 0.0003; // ~30m per update (bigger jumps for less updates)
  static const Duration _updateInterval = Duration(seconds: 5); // Update every 5 seconds for better battery life

  // Current simulated locations
  LocationData? _currentDriverLocation;
  List<ParentData> _currentParentLocations = [];

  // Stream controllers
  final StreamController<LocationData> _driverLocationController =
      StreamController<LocationData>.broadcast();
  final StreamController<List<ParentData>> _parentLocationsController =
      StreamController<List<ParentData>>.broadcast();

  // Getters for streams
  Stream<LocationData> get driverLocationStream => _driverLocationController.stream;
  Stream<List<ParentData>> get parentLocationsStream => _parentLocationsController.stream;

  /// Start simulating driver location movement
  void startDriverSimulation({
    required LocationData initialLocation,
  }) {
    _currentDriverLocation = initialLocation;
    print('Starting driver simulation from: ${initialLocation.latitude}, ${initialLocation.longitude}');

    _startMovementTimer();
  }

  /// Start simulating parent locations movement
  void startParentSimulation({
    required LocationData centerLocation,
  }) {
    // Create initial parent locations around the center
    _currentParentLocations = _generateInitialParentLocations(centerLocation);
    print('Starting parent simulation with ${_currentParentLocations.length} parents');

    if (_updateTimer == null) {
      _startMovementTimer();
    }
  }

  /// Generate initial parent locations around a center point
  List<ParentData> _generateInitialParentLocations(LocationData centerLocation) {
    final now = DateTime.now();

    return [
      ParentData(
        parentId: 'PARENT_001',
        parentName: '김엄마',
        latitude: centerLocation.latitude + 0.003 + (_random.nextDouble() - 0.5) * 0.002,
        longitude: centerLocation.longitude + 0.004 + (_random.nextDouble() - 0.5) * 0.002,
        accuracy: 10.0,
        timestamp: now,
        childName: '김민수',
        isWaitingForPickup: _random.nextBool(),
      ),
      ParentData(
        parentId: 'PARENT_002',
        parentName: '이엄마',
        latitude: centerLocation.latitude - 0.002 + (_random.nextDouble() - 0.5) * 0.002,
        longitude: centerLocation.longitude - 0.003 + (_random.nextDouble() - 0.5) * 0.002,
        accuracy: 8.0,
        timestamp: now,
        childName: '이서연',
        isWaitingForPickup: _random.nextBool(),
      ),
      ParentData(
        parentId: 'PARENT_003',
        parentName: '박아빠',
        latitude: centerLocation.latitude + 0.001 + (_random.nextDouble() - 0.5) * 0.002,
        longitude: centerLocation.longitude - 0.002 + (_random.nextDouble() - 0.5) * 0.002,
        accuracy: 12.0,
        timestamp: now,
        childName: '박지훈',
        isWaitingForPickup: _random.nextBool(),
      ),
    ];
  }

  /// Start the movement timer
  void _startMovementTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateInterval, (_) {
      _updateLocations();
    });
  }

  /// Update all simulated locations with small movements
  void _updateLocations() {
    final now = DateTime.now();

    // Update driver location
    if (_currentDriverLocation != null) {
      _currentDriverLocation = LocationData(
        latitude: _currentDriverLocation!.latitude + _generateMovement(),
        longitude: _currentDriverLocation!.longitude + _generateMovement(),
        accuracy: _currentDriverLocation!.accuracy,
        altitude: _currentDriverLocation!.altitude,
        speed: 5.0 + _random.nextDouble() * 10.0, // 5-15 km/h
        timestamp: now,
        busId: _currentDriverLocation!.busId,
        driverId: _currentDriverLocation!.driverId,
      );

      _driverLocationController.add(_currentDriverLocation!);
      print('Driver moved to: ${_currentDriverLocation!.latitude.toStringAsFixed(6)}, ${_currentDriverLocation!.longitude.toStringAsFixed(6)}');
    }

    // Update parent locations
    if (_currentParentLocations.isNotEmpty) {
      _currentParentLocations = _currentParentLocations.map((parent) {
        return ParentData(
          parentId: parent.parentId,
          parentName: parent.parentName,
          latitude: parent.latitude + _generateMovement() * 0.5, // Parents move slower
          longitude: parent.longitude + _generateMovement() * 0.5,
          accuracy: parent.accuracy,
          timestamp: now,
          childName: parent.childName,
          isWaitingForPickup: _random.nextInt(100) < 5 ? !parent.isWaitingForPickup : parent.isWaitingForPickup, // 5% chance to toggle waiting status
        );
      }).toList();

      _parentLocationsController.add(_currentParentLocations);
      print('Updated ${_currentParentLocations.length} parent locations');
    }
  }

  /// Generate small movement delta (±5-10m)
  double _generateMovement() {
    return (_random.nextDouble() - 0.5) * _movementSpeed * 2; // ±_movementSpeed
  }

  /// Stop all simulations
  void stopSimulation() {
    print('Stopping location simulation');
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Get current simulated driver location (one-time)
  LocationData? getCurrentDriverLocation() {
    return _currentDriverLocation;
  }

  /// Get current simulated parent locations (one-time)
  List<ParentData> getCurrentParentLocations() {
    return List.unmodifiable(_currentParentLocations);
  }

  /// Dispose resources
  void dispose() {
    stopSimulation();
    _driverLocationController.close();
    _parentLocationsController.close();
  }
}