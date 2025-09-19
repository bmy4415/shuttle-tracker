import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'services/location_service.dart';
import 'services/parent_location_service.dart';
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

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

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
  // GoogleMapController? _mapController; // 임시 주석 처리
  // final Set<Marker> _markers = {}; // 임시 주석 처리
  LocationData? _busLocation;
  bool _isLoadingLocation = false;
  bool _isSharingLocation = false;
  bool _isWaitingForPickup = false;
  
  // 학부모 정보 (실제로는 로그인 정보에서 가져옴)
  final String _parentName = '김엄마';
  final String _childName = '김민수';

  // 서울시청 좌표 (기본 지도 중심)
  // static const CameraPosition _initialPosition = CameraPosition( // 임시 주석 처리
  //   target: LatLng(37.5665, 126.9780),
  //   zoom: 14.0,
  // );

  @override
  void initState() {
    super.initState();
    _loadBusLocation();
    _startAutoLocationSharing(); // 앱 시작과 함께 자동 위치 공유 시작
  }

  // 자동 위치 공유 시작
  Future<void> _startAutoLocationSharing() async {
    try {
      await ParentLocationService().updateParentLocation(
        parentName: _parentName,
        childName: _childName,
        isWaitingForPickup: false,
      );
      
      setState(() {
        _isSharingLocation = true;
      });
      
      // 10초마다 위치 업데이트
      Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (_isSharingLocation && mounted) {
          try {
            await ParentLocationService().updateParentLocation(
              parentName: _parentName,
              childName: _childName,
              isWaitingForPickup: _isWaitingForPickup,
            );
          } catch (e) {
            print('자동 위치 업데이트 실패: $e');
          }
        } else {
          timer.cancel();
        }
      });
      
    } catch (e) {
      print('자동 위치 공유 시작 실패: $e');
      // 실패해도 사용자에게는 알리지 않음 (자동이므로)
    }
  }

  Future<void> _loadBusLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    // 실제로는 서버에서 버스 위치를 가져오지만, 
    // 지금은 LocationService로 시뮬레이션
    final locationService = LocationService();
    
    try {
      final location = await locationService.getCurrentLocation(
        busId: 'BUS001',
        driverId: 'DRIVER001',
      );

      if (location != null) {
        setState(() {
          _busLocation = location;
          // _updateBusMarker(location); // 임시 주석 처리
        });

        // 지도 카메라를 버스 위치로 이동
        // if (_mapController != null) { // 임시 주석 처리
        //   _mapController!.animateCamera(
        //     CameraUpdate.newLatLng(
        //       LatLng(location.latitude, location.longitude),
        //     ),
        //   );
        // }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치를 가져올 수 없습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // void _updateBusMarker(LocationData location) { // 임시 주석 처리
  //   final marker = Marker(
  //     markerId: const MarkerId('bus'),
  //     position: LatLng(location.latitude, location.longitude),
  //     icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
  //     infoWindow: InfoWindow(
  //       title: '셔틀버스',
  //       snippet: '버스 ID: ${location.busId}\n시간: ${location.timestamp.toString().substring(11, 19)}',
  //     ),
  //   );

  //   setState(() {
  //     _markers.clear();
  //     _markers.add(marker);
  //   });
  // }

  // 학부모 위치 공유 시작/중지
  Future<void> _toggleLocationSharing() async {
    if (_isSharingLocation) {
      setState(() {
        _isSharingLocation = false;
        _isWaitingForPickup = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 공유를 중지했습니다')),
      );
    } else {
      try {
        await ParentLocationService().updateParentLocation(
          parentName: _parentName,
          childName: _childName,
          isWaitingForPickup: _isWaitingForPickup,
        );
        setState(() {
          _isSharingLocation = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 공유를 시작했습니다')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 공유 실패: $e')),
        );
      }
    }
  }

  // 픽업 대기 상태 토글
  Future<void> _toggleWaitingStatus() async {
    if (!_isSharingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 위치 공유를 활성화하세요')),
      );
      return;
    }

    setState(() {
      _isWaitingForPickup = !_isWaitingForPickup;
    });

    try {
      await ParentLocationService().updateParentLocation(
        parentName: _parentName,
        childName: _childName,
        isWaitingForPickup: _isWaitingForPickup,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isWaitingForPickup ? '픽업 대기 중입니다' : '픽업 대기를 해제했습니다'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상태 변경 실패: $e')),
      );
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
          // 네이버 지도 (플랫폼별 렌더링)
          Positioned.fill(
            child: kIsWeb 
              ? NaverMapWidget(
                  busLocation: _busLocation,
                )
              : NaverMapWidget(
                  busLocation: _busLocation,
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
                  
                  // 버튼들을 행으로 배치
                  Row(
                    children: [
                      // 위치 공유 토글 버튼
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleLocationSharing,
                          icon: Icon(
                            _isSharingLocation ? Icons.location_off : Icons.location_on,
                            size: 16,
                          ),
                          label: Text(
                            _isSharingLocation ? '공유 중지' : '공유 시작',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSharingLocation ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 픽업 대기 버튼
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSharingLocation ? _toggleWaitingStatus : null,
                          icon: Icon(
                            _isWaitingForPickup ? Icons.cancel : Icons.front_hand,
                            size: 16,
                          ),
                          label: Text(
                            _isWaitingForPickup ? '대기 해제' : '픽업 요청',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isWaitingForPickup ? Colors.orange : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_isWaitingForPickup)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '🚌 기사님이 확인할 수 있도록 픽업 대기 중입니다',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                        '버스 위치 확인 중...',
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
        tooltip: '버스 위치 새로고침',
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
        // 학부모 위치 추적도 시작
        _parentLocationService.startTrackingParents();
        setState(() {
          _isTrackingParents = true;
        });
        
        _locationService.locationStream.listen((LocationData location) {
          setState(() {
            _currentLocation = location;
            _statusMessage = '위치 전송 중 (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})';
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
    if (_isLoadingLocation) return; // 중복 클릭 방지

    setState(() {
      _isLoadingLocation = true;
      _statusMessage = '현재 위치 가져오는 중...';
    });

    // 진행률 애니메이션 시작
    _progressController.reset();
    _progressController.forward();

    try {
      LocationData? location = await _locationService.getCurrentLocation(
        busId: 'BUS001',
        driverId: 'DRIVER001',
      );

      // 애니메이션이 완료될 때까지 잠시 대기 (최소 시각적 피드백)
      await _progressController.forward();

      if (location != null) {
        setState(() {
          _currentLocation = location;
          _statusMessage = '현재 위치: (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})';
        });
      } else {
        setState(() {
          _statusMessage = '위치를 가져올 수 없습니다. 권한을 확인해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '위치 요청 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
      _progressController.stop();
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
            
            // 로딩 인디케이터 및 진행률 표시
            if (_isLoadingLocation)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Row(
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
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '예상 소요시간: ${((1 - _progressAnimation.value) * 8).toInt() + 1}초',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'WiFi 기반 위치 서비스를 사용하여\n시간이 다소 걸릴 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
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
            
            // 학부모 위치 지도 표시
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
                      )
                    : NaverMapWidget(
                        busLocation: _currentLocation,
                        parentLocations: _parentLocations,
                        showParentLocations: true,
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