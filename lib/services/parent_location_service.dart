import 'dart:async';
import '../models/parent_data.dart';
import 'location_service.dart';

class ParentLocationService {
  static final ParentLocationService _instance = ParentLocationService._internal();
  factory ParentLocationService() => _instance;
  ParentLocationService._internal();

  final StreamController<List<ParentData>> _parentStreamController = 
      StreamController<List<ParentData>>.broadcast();
  
  final List<ParentData> _parentLocations = [];
  bool _isTrackingParents = false;
  Timer? _trackingTimer;

  Stream<List<ParentData>> get parentLocationStream => _parentStreamController.stream;
  List<ParentData> get currentParentLocations => List.unmodifiable(_parentLocations);
  bool get isTrackingParents => _isTrackingParents;

  // 학부모 위치 추적 시작 (기사용)
  void startTrackingParents() {
    if (_isTrackingParents) return;
    
    _isTrackingParents = true;
    
    // 10초마다 학부모 위치 업데이트 시뮬레이션
    // 실제로는 Firebase나 서버에서 실시간으로 받아옴
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _simulateParentLocationUpdates();
    });

    // 초기 데이터 로드
    _simulateParentLocationUpdates();
  }

  // 학부모 위치 추적 중지
  void stopTrackingParents() {
    _isTrackingParents = false;
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _parentLocations.clear();
    _parentStreamController.add(_parentLocations);
  }

  // 학부모가 자신의 위치를 업데이트 (학부모용)
  Future<void> updateParentLocation({
    required String parentName,
    required String childName,
    bool isWaitingForPickup = false,
  }) async {
    try {
      final location = await LocationService().getCurrentLocation(
        busId: 'PARENT_REQUEST',
        driverId: parentName,
      );
      
      if (location != null) {
        final parentData = ParentData(
          parentId: 'PARENT_${parentName.hashCode}',
          parentName: parentName,
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          timestamp: DateTime.now(),
          childName: childName,
          isWaitingForPickup: isWaitingForPickup,
        );

        // 기존 위치 업데이트 또는 새로 추가
        final existingIndex = _parentLocations.indexWhere((p) => p.parentId == parentData.parentId);
        if (existingIndex >= 0) {
          _parentLocations[existingIndex] = parentData;
        } else {
          _parentLocations.add(parentData);
        }

        _parentStreamController.add(_parentLocations);
        
        // 실제로는 여기서 서버에 전송
        print('Parent location updated: $parentData');
      }
    } catch (e) {
      print('Error updating parent location: $e');
    }
  }

  // 픽업 대기 상태 토글
  void toggleWaitingStatus(String parentId) {
    final index = _parentLocations.indexWhere((p) => p.parentId == parentId);
    if (index >= 0) {
      final parent = _parentLocations[index];
      _parentLocations[index] = ParentData(
        parentId: parent.parentId,
        parentName: parent.parentName,
        latitude: parent.latitude,
        longitude: parent.longitude,
        accuracy: parent.accuracy,
        timestamp: parent.timestamp,
        childName: parent.childName,
        isWaitingForPickup: !parent.isWaitingForPickup,
      );
      _parentStreamController.add(_parentLocations);
    }
  }

  // 가짜 학부모 위치 데이터 생성 (개발/테스트용)
  void _simulateParentLocationUpdates() {
    final now = DateTime.now();
    
    // 서울 시내 여러 위치의 가짜 학부모들
    final fakeParents = [
      ParentData(
        parentId: 'PARENT_001',
        parentName: '김엄마',
        latitude: 37.5665 + (0.01 * (now.second % 5 - 2)), // 서울시청 근처
        longitude: 126.9780 + (0.01 * (now.second % 3 - 1)),
        accuracy: 10.0,
        timestamp: now,
        childName: '김민수',
        isWaitingForPickup: now.second % 20 < 10, // 10초마다 대기 상태 변경
      ),
      ParentData(
        parentId: 'PARENT_002',
        parentName: '이엄마',
        latitude: 37.5758 + (0.005 * (now.second % 4 - 2)), // 명동 근처
        longitude: 126.9768 + (0.005 * (now.second % 4 - 2)),
        accuracy: 8.0,
        timestamp: now,
        childName: '이서연',
        isWaitingForPickup: now.second % 30 < 15,
      ),
      ParentData(
        parentId: 'PARENT_003',
        parentName: '박아빠',
        latitude: 37.5636 + (0.008 * (now.second % 3 - 1)), // 남산타워 근처
        longitude: 126.9756 + (0.008 * (now.second % 5 - 2)),
        accuracy: 12.0,
        timestamp: now,
        childName: '박지훈',
        isWaitingForPickup: false,
      ),
    ];

    _parentLocations.clear();
    _parentLocations.addAll(fakeParents);
    _parentStreamController.add(_parentLocations);
  }

  void dispose() {
    _trackingTimer?.cancel();
    _parentStreamController.close();
  }
}