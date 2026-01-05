import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';
import '../services/location_service.dart';
import '../services/driver_parent_simulator.dart';
import '../services/auth_service.dart';
import '../widgets/naver_map_widget.dart';

/// Driver home screen - Shows driver's location and parent locations
class DriverHomeScreen extends StatefulWidget {
  final UserModel user;
  final GroupModel? group;

  const DriverHomeScreen({super.key, required this.user, this.group});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isTracking = false;
  final LocationService _locationService = LocationService();
  final DriverParentSimulator _parentSimulator = DriverParentSimulator();
  LocationData? _currentLocation;
  String? _statusMessage;

  // 학부모 위치 추적 관련
  List<ParentData> _parentLocations = [];
  bool _isTrackingParents = false;
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<List<ParentData>>? _parentSubscription;

  // Map controller for camera movement
  NaverMapController? _mapController;

  // Parent selection state
  String? _selectedParentName;
  bool _isMovingToParent = false;
  bool _isMovingToMyLocation = false;
  bool _showCurrentLocationButton = false;

  @override
  void initState() {
    super.initState();

    // 학부모 위치 스트림 리스너 설정
    _parentSubscription = _parentSimulator.parentLocationStream.listen((
      parents,
    ) {
      if (mounted) {
        print(
          'Main screen: Received ${parents.length} parent locations from simulator',
        );
        if (parents.isNotEmpty) {
          print(
            'First parent: ${parents[0].parentName} at ${parents[0].latitude.toStringAsFixed(4)}, ${parents[0].longitude.toStringAsFixed(4)}',
          );
        }
        setState(() {
          _parentLocations = parents;
        });
        print(
          'Main screen: setState called with ${_parentLocations.length} parents',
        );
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _parentSubscription?.cancel();
    _locationService.dispose();
    _parentSimulator.stopSimulation();
    _mapController = null;
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      // Stop tracking
      _locationService.stopLocationTracking();
      _parentSimulator.stopSimulation();
      _locationSubscription?.cancel();
      _locationSubscription = null;

      setState(() {
        _isTracking = false;
        _isTrackingParents = false;
        _statusMessage = '운행 중지됨';
        _parentLocations = [];
        _showCurrentLocationButton = false; // Disable current location button
        _selectedParentName = null; // Clear selection
      });
    } else {
      setState(() {
        _statusMessage = '위치 권한 확인 중...';
      });

      bool started = await _locationService.startLocationTracking(
        busId: 'BUS001',
        driverId: 'DRIVER001',
      );

      if (started) {
        setState(() {
          _isTrackingParents = true;
        });

        // Listen to driver location stream
        _locationSubscription = _locationService.locationStream.listen((
          LocationData location,
        ) {
          if (mounted) {
            setState(() {
              _currentLocation = location;
              _statusMessage = '운행 중 - 학부모 ${_parentLocations.length}명 추적 중';
            });

            // Update parent simulator with new driver location
            if (_isTracking) {
              _parentSimulator.updateDriverLocation(location);
            }
          }
        });

        // Start parent simulation with initial location
        LocationData? initialLocation = await _locationService
            .getCurrentLocation(busId: 'BUS001', driverId: 'DRIVER001');

        if (initialLocation != null && mounted) {
          _parentSimulator.startSimulation(initialLocation);
          setState(() {
            _currentLocation = initialLocation;
            _isTracking = true;
            _showCurrentLocationButton = true; // Enable current location button
          });
        } else if (mounted) {
          setState(() {
            _isTracking = true;
          });
        }
      } else {
        setState(() {
          _statusMessage = '위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.';
        });
      }
    }
  }

  /// Move camera to parent location
  Future<void> _moveToParent(ParentData parent) async {
    // Skip on web - map not available
    if (kIsWeb) return;

    if (_isMovingToParent || _mapController == null) {
      return;
    }

    setState(() {
      _isMovingToParent = true;
      _selectedParentName = parent.parentName;
    });

    try {
      await _mapController!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(parent.latitude, parent.longitude),
            zoom: 17,
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${parent.parentName} 위치로 이동'),
            duration: const Duration(seconds: 1),
          ),
        );

        // Keep parent selected for 3 seconds
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _selectedParentName = null;
            });
          }
        });
      }
    } catch (e) {
      print('Error moving to parent location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMovingToParent = false;
        });
      }
    }
  }

  /// Move camera to my (driver) location
  Future<void> _moveToMyLocation() async {
    // Skip on web - map not available
    if (kIsWeb) return;

    if (_isMovingToMyLocation ||
        _currentLocation == null ||
        _mapController == null) {
      return;
    }

    setState(() {
      _isMovingToMyLocation = true;
    });

    try {
      await _mapController!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
            ),
            zoom: 16,
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('내 위치로 이동'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error moving to my location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMovingToMyLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            tooltip: '뒤로가기',
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('기사 화면'),
              if (widget.group != null)
                Text(
                  '그룹: ${widget.group!.code}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          backgroundColor: Colors.green.shade100,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
              tooltip: '설정',
            ),
            if (widget.group != null)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('그룹 정보'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('그룹명: ${widget.group!.name}'),
                          const SizedBox(height: 8),
                          Text(
                            '그룹 코드: ${widget.group!.code}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('참여 인원: ${widget.group!.memberCount}명'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
        body: Stack(
          children: [
            // 메인 지도 화면
            Positioned.fill(
              child: _isTracking && _currentLocation != null
                  ? kIsWeb
                        ? NaverMapWidget(
                            busLocation: _currentLocation,
                            parentLocations: _parentLocations,
                            showParentLocations: true,
                            isDriverView: true,
                            onMapControllerReady: (controller) {
                              _mapController = controller;
                            },
                          )
                        : NaverMapWidget(
                            busLocation: _currentLocation,
                            parentLocations: _parentLocations,
                            showParentLocations: true,
                            isDriverView: true,
                            onMapControllerReady: (controller) {
                              _mapController = controller;
                            },
                          )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isTracking
                                  ? Icons.location_searching
                                  : Icons.location_off,
                              size: 100,
                              color: _isTracking ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _statusMessage ??
                                  (_isTracking ? '위치 확인 중...' : '운행을 시작해주세요'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // 학부모 목록 (왼쪽 사이드바)
            if (_isTracking && _parentLocations.isNotEmpty)
              Positioned(
                left: 16,
                top: 20,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade600,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.family_restroom,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '학부모 목록 (${_parentLocations.length})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 학부모 리스트 (클릭 가능)
                      ...(_parentLocations.map((parent) {
                        final bool isSelected =
                            _selectedParentName == parent.parentName;
                        final bool isMoving = _isMovingToParent && isSelected;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isMoving
                                ? null
                                : () => _moveToParent(parent),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isMoving
                                    ? Colors.grey.shade300
                                    : isSelected
                                    ? Colors.green.shade100
                                    : Colors.transparent,
                                border: isSelected && !isMoving
                                    ? Border.all(
                                        color: Colors.green.shade400,
                                        width: 2,
                                      )
                                    : null,
                                borderRadius: isSelected && !isMoving
                                    ? BorderRadius.circular(6)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // 상태 아이콘
                                  if (isMoving)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.purple,
                                            ),
                                      ),
                                    )
                                  else
                                    Icon(
                                      parent.isWaitingForPickup
                                          ? Icons.front_hand
                                          : Icons.person_pin_circle,
                                      color: parent.isWaitingForPickup
                                          ? Colors.orange.shade600
                                          : Colors.green.shade600,
                                      size: 14,
                                    ),
                                  const SizedBox(width: 8),
                                  // 학부모 정보
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          parent.parentName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isMoving
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                            color: isMoving
                                                ? Colors.grey.shade600
                                                : Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          parent.childName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMoving
                                                ? Colors.grey.shade500
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 픽업 대기 배지
                                  if (parent.isWaitingForPickup && !isMoving)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '대기',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ),

            // 하단 버튼들
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 내 위치 버튼 (운행 중일 때만 표시)
                  if (_showCurrentLocationButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed:
                            (_currentLocation != null && !_isMovingToMyLocation)
                            ? _moveToMyLocation
                            : null,
                        icon: _isMovingToMyLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.my_location, size: 20),
                        label: Text(
                          _isMovingToMyLocation ? '이동중...' : '내 위치',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMovingToMyLocation
                              ? Colors.grey
                              : Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(140, 40),
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),
                  // 운행 시작/종료 버튼
                  ElevatedButton.icon(
                    onPressed: _toggleTracking,
                    icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                    label: Text(_isTracking ? '운행 종료' : '운행 시작'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
