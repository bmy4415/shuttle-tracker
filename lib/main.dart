import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'services/location_service.dart';
import 'services/parent_location_service.dart';
import 'services/auto_location_simulator.dart';
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

  // TODO: 배포시 삭제 - 개발용 Hot Restart 확인 팝업
  void _showStartupTimestamp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final startTime = DateTime.now();
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('🔥 Hot Restart 완료'),
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
  StreamSubscription<LocationData>? _busLocationSubscription;

  // Services
  final LocationService _locationService = LocationService();
  final AutoLocationSimulator _simulator = AutoLocationSimulator();

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

    // Stop simulator and dispose resources
    _simulator.stopSimulation();
    _simulator.dispose();

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
        if (_busLocation == null) {
          final simulatedDriverLocation = LocationData(
            latitude: cachedLocation.latitude + 0.005, // ~500m north
            longitude: cachedLocation.longitude + 0.003,
            accuracy: 10.0,
            altitude: cachedLocation.altitude,
            speed: 15.0,
            timestamp: DateTime.now(),
            busId: 'BUS001',
            driverId: 'DRIVER001',
          );

          _simulator.startDriverSimulation(initialLocation: simulatedDriverLocation);
        }
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
                _simulator.startDriverSimulation(initialLocation: simulatedDriverLocation);
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
      _busLocationSubscription = _simulator.driverLocationStream.listen(
        (LocationData driverLocation) {
          if (mounted) {
            setState(() {
              _busLocation = driverLocation;
            });
          }
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

class _DriverHomeScreenState extends State<DriverHomeScreen> with TickerProviderStateMixin {
  bool _isTracking = false;
  final LocationService _locationService = LocationService();
  final ParentLocationService _parentLocationService = ParentLocationService();
  LocationData? _currentLocation;
  String? _statusMessage;
  bool _isLoadingLocation = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  // 학부모 위치 추적 관련
  List<ParentData> _parentLocations = [];
  bool _isTrackingParents = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 8), // 예상 소요시간 8초
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    // 학부모 위치 스트림 리스너 설정
    _parentLocationService.parentLocationStream.listen((parents) {
      if (mounted) {
        setState(() {
          _parentLocations = parents;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _locationService.dispose();
    _parentLocationService.dispose();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _locationService.stopLocationTracking();
      _parentLocationService.stopTrackingParents(); // 학부모 위치 추적도 중지
      setState(() {
        _isTracking = false;
        _isTrackingParents = false;
        _statusMessage = '위치 전송 중지됨';
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
        // 학부모 위치 추적도 시작 (시뮬레이션)
        setState(() {
          _isTrackingParents = true;
        });

        _locationService.locationStream.listen((LocationData location) {
          setState(() {
            _currentLocation = location;
            _statusMessage = '위치 전송 중 (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})';

            // 기사 위치를 기준으로 시뮬레이션 학부모 위치 생성
            _parentLocations = _locationService.getSimulatedParentLocations(location);
          });
        });

        setState(() {
          _isTracking = true;
        });
      } else {
        setState(() {
          _statusMessage = '위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.';
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation || !mounted) return; // 중복 클릭 방지 + mounted 체크

    setState(() {
      _isLoadingLocation = true;
      _statusMessage = '현재 위치 가져오는 중...';
    });

    try {
      // 타임아웃 3초로 단축
      LocationData? location = await LocationService().getCurrentLocation(
        busId: 'BUS001',
        driverId: 'DRIVER001',
      ).timeout(const Duration(seconds: 15));

      if (mounted && location != null) {
        setState(() {
          _currentLocation = location;
          _statusMessage = '현재 위치: (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})';
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = '위치를 가져올 수 없습니다. 권한을 확인해주세요.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '위치 요청 중 오류가 발생했습니다: $e';
        });
      }
      print('Driver location error: $e'); // 디버깅용
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
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
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
              _isTracking ? Icons.location_on : Icons.location_off,
              size: 100,
              color: _isTracking ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage ?? (_isTracking ? '위치 전송 중...' : '위치 전송 중지됨'),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            
            // 간단한 로딩 인디케이터
            if (_isLoadingLocation)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '위치 정보를 가져오고 있습니다...',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              
            // 위치 정보 표시
            if (_currentLocation != null && !_isLoadingLocation)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '최근 위치',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '위도: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '경도: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (_currentLocation!.accuracy != null)
                      Text(
                        '정확도: ${_currentLocation!.accuracy!.toStringAsFixed(1)}m',
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      '시각: ${_currentLocation!.timestamp.toString().substring(11, 19)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _toggleTracking,
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(_isTracking ? '운행 종료' : '운행 시작'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: _isLoadingLocation 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
              label: Text(_isLoadingLocation ? '위치 확인 중...' : '현재 위치 확인'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: _isLoadingLocation ? Colors.grey.shade300 : null,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('승하차 관리 기능 준비 중')),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('승하차 관리'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
            
            // 학부모 위치 지도 표시 (기사 뷰: 기사 본인 + 모든 학부모)
            if (_isTrackingParents) ...[
              const SizedBox(height: 20),
              Container(
                height: 300,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                    ? NaverMapWidget(
                        busLocation: _currentLocation,
                        parentLocations: _parentLocations,
                        showParentLocations: true,
                        isDriverView: true,
                      )
                    : NaverMapWidget(
                        busLocation: _currentLocation,
                        parentLocations: _parentLocations,
                        showParentLocations: true,
                        isDriverView: true,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              
              // 학부모 목록 (간단한 리스트)
              if (_parentLocations.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.family_restroom, color: Colors.purple.shade600, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '학부모 위치 (${_parentLocations.length}명)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 간단한 학부모 목록
                      ...(_parentLocations.map((parent) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              parent.isWaitingForPickup ? Icons.front_hand : Icons.person_pin_circle,
                              color: parent.isWaitingForPickup ? Colors.orange.shade600 : Colors.blue.shade600,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${parent.parentName} (${parent.childName})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: parent.isWaitingForPickup ? FontWeight.bold : FontWeight.normal,
                                  color: parent.isWaitingForPickup ? Colors.orange.shade800 : Colors.black87,
                                ),
                              ),
                            ),
                            if (parent.isWaitingForPickup)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '픽업 대기',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )).toList()),
                    ],
                  ),
                ),
            ],
            
            // 학부모 위치 추적 상태 메시지
            if (_isTrackingParents && _parentLocations.isEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '📱 학부모들의 위치 공유를 기다리고 있습니다...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}