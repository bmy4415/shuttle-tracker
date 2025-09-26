import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'services/location_service.dart';
import 'services/parent_driver_simulator.dart';
import 'services/auto_location_simulator.dart';
import 'services/driver_parent_simulator.dart';
import 'dart:async';
import 'models/location_data.dart';
import 'models/parent_data.dart';
import 'widgets/naver_map_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 로드
  await dotenv.load(fileName: ".env");
  
  // 네이버 지도 초기화 (모바일에서만)
  if (!kIsWeb) {
    final clientId = dotenv.env['NAVER_MAPS_CLIENT_ID'];
    if (clientId != null && clientId != 'your_client_id_here') {
      await FlutterNaverMap().init(
        clientId: clientId,
        onAuthFailed: (ex) {
          print('Naver Map 인증 실패: ${ex.toString()}');
        },
      );
    }
  }
  
  runApp(const ShuttleTrackerApp());
}

class ShuttleTrackerApp extends StatelessWidget {
  const ShuttleTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '셔틀 트래커',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RoleSelectorScreen(),
    );
  }
}

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {

  @override
  void initState() {
    super.initState();
    // TODO: 배포시 삭제 - 개발용 앱 시작시간 팝업
    _showStartupTimestamp();
  }

  @override
  void didUpdateWidget(RoleSelectorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO: 배포시 삭제 - Hot Reload 시에도 타임스탬프 팝업
    _showStartupTimestamp();
  }

  // TODO: 배포시 삭제 - 개발용 Hot Restart 확인 팝업
  void _showStartupTimestamp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final startTime = DateTime.now();
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('✅ Hot Reload 성공!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('앱 시작시간:'),
                const SizedBox(height: 8),
                Text(
                  '${startTime.toString().substring(0, 19)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('셔틀 트래커'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 40),
            const Text(
              '사용자 유형을 선택하세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ParentHomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('학부모'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverHomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.drive_eta),
              label: const Text('기사'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

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
      _myLocationSubscription = _locationService.startLocationStream(
        busId: 'PARENT_LOCATION',
        driverId: _parentName,
      ).listen(
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
            print('Updated driver location: ${driverLocation.latitude}, ${driverLocation.longitude}');
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
    if (_isMovingToMyLocation || _myLocation == null || _mapController == null) {
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
    if (_isMovingToBusLocation || _busLocation == null || _mapController == null) {
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
      myLocation = await locationService.getCurrentLocation(
        busId: 'PARENT_LOCATION',
        driverId: _parentName,
      ).timeout(const Duration(seconds: 15));

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
                      Icon(Icons.person_pin_circle, color: Colors.green.shade600),
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
                          onPressed: (_myLocation != null && !_isMovingToMyLocation)
                              ? _moveToMyLocation
                              : null,
                          icon: _isMovingToMyLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 16),
                          label: Text(
                            _isMovingToMyLocation ? '이동중...' : '내위치',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMovingToMyLocation ? Colors.grey : Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 셔틀위치 버튼
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_busLocation != null && !_isMovingToBusLocation)
                              ? _moveToBusLocation
                              : null,
                          icon: _isMovingToBusLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.directions_bus, size: 16),
                          label: Text(
                            _isMovingToBusLocation ? '이동중...' : '셔틀위치',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isMovingToBusLocation ? Colors.grey : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

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
    _parentSubscription = _parentSimulator.parentLocationStream.listen((parents) {
      if (mounted) {
        print('Main screen: Received ${parents.length} parent locations from simulator');
        if (parents.isNotEmpty) {
          print('First parent: ${parents[0].parentName} at ${parents[0].latitude.toStringAsFixed(4)}, ${parents[0].longitude.toStringAsFixed(4)}');
        }
        setState(() {
          _parentLocations = parents;
        });
        print('Main screen: setState called with ${_parentLocations.length} parents');
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
        _locationSubscription = _locationService.locationStream.listen((LocationData location) {
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
        LocationData? initialLocation = await _locationService.getCurrentLocation(
          busId: 'BUS001',
          driverId: 'DRIVER001',
        );

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
    if (_isMovingToMyLocation || _currentLocation == null || _mapController == null) {
      return;
    }

    setState(() {
      _isMovingToMyLocation = true;
    });

    try {
      await _mapController!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(_currentLocation!.latitude, _currentLocation!.longitude),
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
        title: const Text('기사 화면'),
        backgroundColor: Colors.green.shade100,
        centerTitle: true,
        // actions 제거 - 하단에 별도 버튼으로 이동
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
                            _isTracking ? Icons.location_searching : Icons.location_off,
                            size: 100,
                            color: _isTracking ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _statusMessage ?? (_isTracking ? '위치 확인 중...' : '운행을 시작해주세요'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                          const Icon(Icons.family_restroom, color: Colors.white, size: 16),
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
                      final bool isSelected = _selectedParentName == parent.parentName;
                      final bool isMoving = _isMovingToParent && isSelected;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isMoving ? null : () => _moveToParent(parent),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMoving
                                  ? Colors.grey.shade300
                                  : isSelected
                                      ? Colors.green.shade100
                                      : Colors.transparent,
                              border: isSelected && !isMoving
                                  ? Border.all(color: Colors.green.shade400, width: 2)
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                                    ),
                                  )
                                else
                                  Icon(
                                    parent.isWaitingForPickup ? Icons.front_hand : Icons.person_pin_circle,
                                    color: parent.isWaitingForPickup ? Colors.orange.shade600 : Colors.green.shade600,
                                    size: 14,
                                  ),
                                const SizedBox(width: 8),
                                // 학부모 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        parent.parentName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isMoving ? FontWeight.normal : FontWeight.bold,
                                          color: isMoving ? Colors.grey.shade600 : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        parent.childName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMoving ? Colors.grey.shade500 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 픽업 대기 배지
                                if (parent.isWaitingForPickup && !isMoving)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                      onPressed: (_currentLocation != null && !_isMovingToMyLocation)
                          ? _moveToMyLocation
                          : null,
                      icon: _isMovingToMyLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      label: Text(
                        _isMovingToMyLocation ? '이동중...' : '내 위치',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMovingToMyLocation ? Colors.grey : Colors.blue.shade600,
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