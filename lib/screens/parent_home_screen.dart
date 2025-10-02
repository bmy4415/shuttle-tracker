import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/location_data.dart';
import '../services/location_service.dart';
import '../services/parent_driver_simulator.dart';
import '../services/auth_service.dart';
import '../widgets/naver_map_widget.dart';

/// Parent home screen - Shows bus location and parent's own location
class ParentHomeScreen extends StatefulWidget {
  final UserModel user;
  final GroupModel? group;

  const ParentHomeScreen({super.key, required this.user, this.group});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  LocationData? _busLocation;
  LocationData? _myLocation; // 학부모 본인의 위치
  bool _isLoadingLocation = false;

  // 학부모 정보 (실제로는 로그인 정보에서 가져옴)
  final String _parentName = '김엄마';
  final String _childName = '김민수';

  // Stream subscriptions
  StreamSubscription<LocationData>? _myLocationSubscription;

  // Driver simulation
  final ParentDriverSimulator _driverSimulator = ParentDriverSimulator();
  StreamSubscription<LocationData>? _driverLocationSubscription;
  StreamSubscription<LocationData>? _busLocationSubscription;

  // Services
  final LocationService _locationService = LocationService();

  // Map controller for camera movement
  NaverMapController? _mapController;

  // Button state management
  bool _isMovingToMyLocation = false;
  bool _isMovingToBusLocation = false;

  @override
  void initState() {
    super.initState();
    _startRealTimeLocationTracking();
  }

  @override
  void dispose() {
    // Cancel all subscriptions to prevent memory leaks
    _myLocationSubscription?.cancel();
    _myLocationSubscription = null;

    _busLocationSubscription?.cancel();
    _busLocationSubscription = null;

    // Stop driver simulation and dispose resources
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    _driverSimulator.stopSimulation();

    // Clear map controller reference
    _mapController = null;

    super.dispose();
  }

  /// Start real-time location tracking using streams
  Future<void> _startRealTimeLocationTracking() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      print('Starting real-time location tracking for parent...');

      // Try to get last known position first for immediate loading
      LocationData? cachedLocation = await _locationService.getCurrentLocation(
        busId: 'PARENT_LOCATION',
        driverId: _parentName,
      );

      if (cachedLocation != null && mounted) {
        print('Using cached location for immediate display');
        setState(() {
          _myLocation = cachedLocation;
          _isLoadingLocation = false; // Remove loading state immediately
        });

        // Start driver simulation immediately with cached location
        _driverSimulator.startSimulation(cachedLocation);
      }

      // Continue with real-time location stream for updates
      _myLocationSubscription = _locationService
          .startLocationStream(busId: 'PARENT_LOCATION', driverId: _parentName)
          .listen(
            (LocationData myLocation) {
              if (!mounted) return; // Early return if widget disposed

              try {
                setState(() {
                  _myLocation = myLocation;
                  // Don't set _isLoadingLocation = false here since we already set it with cached data
                });

                // Update driver simulation with real location
                if (mounted) {
                  final simulatedDriverLocation = LocationData(
                    latitude: myLocation.latitude + 0.005, // ~500m north
                    longitude: myLocation.longitude + 0.003,
                    accuracy: 10.0,
                    altitude: myLocation.altitude,
                    speed: 15.0,
                    timestamp: DateTime.now(),
                    busId: 'BUS001',
                    driverId: 'DRIVER001',
                  );

                  // Update existing simulation or start new one
                  if (_busLocation == null) {
                    _driverSimulator.startSimulation(myLocation);
                  } else {
                    _driverSimulator.updateParentLocation(myLocation);
                  }
                }
              } catch (e) {
                print('Error updating location state: $e');
              }
            },
            onError: (error) {
              print('Error in my location stream: $error');
              if (mounted && _myLocation == null) {
                // Only set loading to false if we don't have cached location
                try {
                  setState(() {
                    _isLoadingLocation = false;
                  });
                } catch (e) {
                  print('Error updating loading state: $e');
                }
              }
              // Don't show error messages to user - just log them
              // Only log errors silently for debugging
            },
          );

      // Listen to simulated driver location updates
      _driverLocationSubscription = _driverSimulator.driverLocationStream.listen(
        (LocationData driverLocation) {
          if (mounted) {
            setState(() {
              _busLocation = driverLocation;
            });
            print(
              'Updated driver location: ${driverLocation.latitude}, ${driverLocation.longitude}',
            );
          }
        },
        onError: (error) {
          print('Error in driver location stream: $error');
        },
      );
    } catch (e) {
      print('Error starting real-time tracking: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        // Don't show error messages to user - just log them
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('실시간 위치 추적 시작 실패: $e')),
        // );
      }
    }
  }

  /// Move camera to my location
  Future<void> _moveToMyLocation() async {
    if (_isMovingToMyLocation ||
        _myLocation == null ||
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
            target: NLatLng(_myLocation!.latitude, _myLocation!.longitude),
            zoom: 16,
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars(); // 기존 스낵바 제거
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

  /// Move camera to bus location
  Future<void> _moveToBusLocation() async {
    if (_isMovingToBusLocation ||
        _busLocation == null ||
        _mapController == null) {
      return;
    }

    setState(() {
      _isMovingToBusLocation = true;
    });

    try {
      await _mapController!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(_busLocation!.latitude, _busLocation!.longitude),
            zoom: 16,
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars(); // 기존 스낵바 제거
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('셔틀 위치로 이동'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error moving to bus location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMovingToBusLocation = false;
        });
      }
    }
  }

  /// Fallback method for manual refresh
  Future<void> _loadBusLocation() async {
    if (!mounted) return; // 화면이 살아있는지 확인

    setState(() {
      _isLoadingLocation = true;
    });

    final locationService = LocationService();
    LocationData? myLocation;
    LocationData? busLocation;

    try {
      // 내 위치 가져오기 (타임아웃 3초)
      myLocation = await locationService
          .getCurrentLocation(busId: 'PARENT_LOCATION', driverId: _parentName)
          .timeout(const Duration(seconds: 15));

      // 내 위치 성공 시 버스 위치 생성
      if (myLocation != null) {
        busLocation = await locationService.getSimulatedBusLocation(
          busId: 'BUS001',
          driverId: 'DRIVER001',
          userLocation: myLocation,
        );
      }
    } catch (e) {
      print('Parent location error: $e');

      // GPS 실패 시 에러만 표시하고 기본값 사용 안함
      if (mounted) {
        // Don't show timeout errors to user - they can be frequent and annoying
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('위치를 가져올 수 없습니다: $e'),
        //     duration: const Duration(seconds: 2),
        //   ),
        // );
      }
      return; // 기본 위치 사용하지 않음
    }

    // 화면이 살아있을 때만 업데이트
    if (mounted && myLocation != null) {
      setState(() {
        _myLocation = myLocation;
        _busLocation = busLocation;
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('학부모 화면'),
          backgroundColor: Colors.blue.shade100,
          actions: [
            IconButton(
              onPressed: _isLoadingLocation ? null : _loadBusLocation,
              icon: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Stack(
          children: [
            // 네이버 지도 (학부모 뷰: 본인 위치 + 버스 기사 위치)
            Positioned.fill(
              child: kIsWeb
                  ? NaverMapWidget(
                      busLocation: _busLocation,
                      currentUserLocation: _myLocation,
                      isDriverView: false,
                      onMapControllerReady: (controller) {
                        _mapController = controller;
                      },
                    )
                  : NaverMapWidget(
                      busLocation: _busLocation,
                      currentUserLocation: _myLocation,
                      isDriverView: false,
                      onMapControllerReady: (controller) {
                        _mapController = controller;
                      },
                    ),
            ),

            // 학부모 위치 공유 컨트롤 (지도 위에 오버레이)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_pin_circle,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '나의 위치 공유',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_parentName ($_childName)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 첫 번째 행: 내위치/셔틀위치 버튼
                    Row(
                      children: [
                        // 내위치 버튼
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (_myLocation != null && !_isMovingToMyLocation)
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
                                : const Icon(Icons.my_location, size: 16),
                            label: Text(
                              _isMovingToMyLocation ? '이동중...' : '내위치',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isMovingToMyLocation
                                  ? Colors.grey
                                  : Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 셔틀위치 버튼
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (_busLocation != null &&
                                    !_isMovingToBusLocation)
                                ? _moveToBusLocation
                                : null,
                            icon: _isMovingToBusLocation
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
                                : const Icon(Icons.directions_bus, size: 16),
                            label: Text(
                              _isMovingToBusLocation ? '이동중...' : '셔틀위치',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isMovingToBusLocation
                                  ? Colors.grey
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 로딩 인디케이터
            if (_isLoadingLocation)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          '위치 확인 중...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isLoadingLocation ? null : _loadBusLocation,
          child: const Icon(Icons.my_location),
          tooltip: '위치 새로고침',
        ),
    );
  }
}
