import 'package:flutter/material.dart';
import 'services/location_service.dart';
import 'models/location_data.dart';

void main() {
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

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학부모 화면'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              '버스 위치가 여기에 표시됩니다',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('지도 기능 준비 중')),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('위치 새로고침'),
            ),
          ],
        ),
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
  LocationData? _currentLocation;
  String? _statusMessage;
  bool _isLoadingLocation = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

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
  }

  @override
  void dispose() {
    _progressController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _locationService.stopLocationTracking();
      setState(() {
        _isTracking = false;
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
      body: Center(
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
          ],
        ),
      ),
    );
  }
}