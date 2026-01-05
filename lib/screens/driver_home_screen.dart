import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';
import '../models/shared_location_model.dart';
import '../models/group_member_model.dart';
import '../services/location_service.dart';
import '../services/location_sharing_service.dart';
import '../services/group_service.dart';
import '../widgets/naver_map_widget.dart';

/// Driver home screen - Shows driver's location and all members' locations
class DriverHomeScreen extends StatefulWidget {
  final UserModel user;
  final String? groupId; // Group ID from route parameter

  const DriverHomeScreen({super.key, required this.user, this.groupId});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isTracking = false;
  bool _isSharing = true;
  final LocationService _locationService = LocationService();
  late final LocationSharingService _sharingService;
  GroupService? _groupService;
  GroupModel? _group;
  LocationData? _currentLocation;
  String? _statusMessage;
  bool _isLoadingGroup = true;

  // All member locations (including those not sharing)
  List<SharedLocationModel> _allMemberLocations = [];
  // Parent locations for map (only sharing ones)
  List<ParentData> _parentLocations = [];
  List<GroupMemberModel> _groupMembers = [];

  // Stream subscriptions
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<List<SharedLocationModel>>? _membersLocationSubscription;
  StreamSubscription<List<GroupMemberModel>>? _membersSubscription;

  // Map controller
  NaverMapController? _mapController;

  // UI state
  String? _selectedParentId;
  bool _isMovingToParent = false;
  bool _isMovingToMyLocation = false;

  @override
  void initState() {
    super.initState();
    _sharingService = LocationSharingService.getInstance();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _groupService = await GroupServiceFactory.getInstance();
    await _loadGroup();
  }

  Future<void> _loadGroup() async {
    print('[DriverHome] _loadGroup called, groupId: ${widget.groupId}');

    if (widget.groupId == null) {
      print('[DriverHome] groupId is null!');
      setState(() {
        _isLoadingGroup = false;
        _statusMessage = '그룹 ID가 없습니다';
      });
      return;
    }

    try {
      print('[DriverHome] Loading group: ${widget.groupId}');
      final group = await _groupService!.getGroup(widget.groupId!);
      print('[DriverHome] Group loaded: ${group?.name ?? "null"}');
      setState(() {
        _group = group;
        _isLoadingGroup = false;
        if (group == null) {
          _statusMessage = '그룹을 찾을 수 없습니다';
        }
      });
    } catch (e) {
      print('[DriverHome] Error loading group: $e');
      setState(() {
        _isLoadingGroup = false;
        _statusMessage = '그룹 로드 실패: $e';
      });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _membersLocationSubscription?.cancel();
    _membersSubscription?.cancel();
    _locationService.dispose();
    _mapController = null;
    super.dispose();
  }

  /// Start tracking and sharing
  Future<void> _startTracking() async {
    if (_group == null) {
      setState(() {
        _statusMessage = '그룹 정보가 없습니다';
      });
      return;
    }

    setState(() {
      _statusMessage = '위치 권한 확인 중...';
      _isTracking = true; // Show tracking UI immediately
    });

    bool started = await _locationService.startLocationTracking(
      busId: 'BUS001',
      driverId: widget.user.id,
    );

    if (!started) {
      setState(() {
        _isTracking = false;
        _statusMessage = '위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.';
      });
      return;
    }

    setState(() {
      _statusMessage = '위치 서비스 연결 중...';
    });

    final groupId = _group!.id;
    final userId = widget.user.id;

    try {
      // Setup disconnect handler
      await _sharingService.setupDisconnectHandler(
        groupId: groupId,
        userId: userId,
      );

      // Start sharing location
      await _sharingService.startSharing(
        groupId: groupId,
        userId: userId,
        displayName: widget.user.nickname,
        role: widget.user.role,
      );

      setState(() {
        _isSharing = true;
        _statusMessage = '운행 시작됨 - 위치 대기 중...';
      });

      // Listen to my location
      _locationSubscription = _locationService.locationStream.listen(
        (LocationData location) async {
          if (!mounted) return;

          setState(() {
            _currentLocation = location;
            _statusMessage = '운행 중 - 학부모 ${_parentLocations.length}명';
          });

          // Update location in Firebase
          if (_isSharing) {
            await _sharingService.updateLocation(
              groupId: groupId,
              location: SharedLocationModel(
                userId: userId,
                groupId: groupId,
                displayName: widget.user.nickname,
                role: widget.user.role,
                latitude: location.latitude,
                longitude: location.longitude,
                accuracy: location.accuracy,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                isSharing: true,
              ),
            );
          }
        },
      );

      // Subscribe to ALL members' locations (including those not sharing)
      _membersLocationSubscription = _sharingService
          .watchAllMemberLocations(groupId: groupId)
          .listen((members) {
        if (!mounted) return;

        // Store all member locations
        final allNonDriverMembers = members
            .where((m) => m.role != UserRole.driver)
            .toList();

        // Filter for map display (only sharing ones)
        final sharingParentLocations = allNonDriverMembers
            .where((m) => m.isSharing && m.isRecent)
            .map((m) => ParentData(
                  parentId: m.userId,
                  parentName: m.displayName,
                  childName: '',
                  latitude: m.latitude,
                  longitude: m.longitude,
                  timestamp: m.dateTime,
                  isWaitingForPickup: false,
                ))
            .toList();

        setState(() {
          _allMemberLocations = allNonDriverMembers;
          _parentLocations = sharingParentLocations;
          _statusMessage = '운행 중 - 학부모 ${sharingParentLocations.length}명 공유중';
        });
      });

      // Subscribe to members list (for info)
      _membersSubscription = _sharingService
          .watchGroupMembers(groupId: groupId)
          .listen((members) {
        if (mounted) {
          setState(() {
            _groupMembers = members;
          });
        }
      });

      // Get initial location
      LocationData? initialLocation = await _locationService.getCurrentLocation(
        busId: 'BUS001',
        driverId: userId,
      );

      if (initialLocation != null && mounted) {
        setState(() {
          _currentLocation = initialLocation;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting tracking: $e');
      }
      setState(() {
        _isTracking = false;
        _isSharing = false;
        _statusMessage = '위치 공유 시작 실패: $e';
      });
    }
  }

  /// Stop tracking
  Future<void> _stopTracking() async {
    _locationService.stopLocationTracking();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _membersLocationSubscription?.cancel();
    _membersLocationSubscription = null;

    if (_group != null) {
      await _sharingService.stopSharing(
        groupId: _group!.id,
        userId: widget.user.id,
      );
    }

    setState(() {
      _isTracking = false;
      _isSharing = false;
      _statusMessage = '운행 중지됨';
      _parentLocations = [];
      _allMemberLocations = [];
      _selectedParentId = null;
    });
  }

  /// Toggle tracking
  Future<void> _toggleTracking() async {
    if (_isTracking) {
      await _stopTracking();
    } else {
      await _startTracking();
    }
  }

  /// Toggle sharing (while tracking)
  Future<void> _toggleSharing() async {
    if (_group == null) return;

    try {
      if (_isSharing) {
        await _sharingService.stopSharing(
          groupId: _group!.id,
          userId: widget.user.id,
        );
        setState(() => _isSharing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 공유가 중지되었습니다')),
          );
        }
      } else {
        await _sharingService.startSharing(
          groupId: _group!.id,
          userId: widget.user.id,
          displayName: widget.user.nickname,
          role: widget.user.role,
        );
        setState(() => _isSharing = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 공유가 시작되었습니다')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error toggling sharing: $e');
    }
  }

  /// Move camera to parent location
  Future<void> _moveToParent(SharedLocationModel member) async {
    if (kIsWeb || _isMovingToParent || _mapController == null) return;
    if (!member.isSharing) return; // Can't move to non-sharing member

    setState(() {
      _isMovingToParent = true;
      _selectedParentId = member.userId;
    });

    try {
      await _mapController!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(member.latitude, member.longitude),
            zoom: 17,
          ),
        ),
      );

      // Clear selection after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _selectedParentId = null);
      });
    } catch (e) {
      if (kDebugMode) print('Error moving to parent: $e');
    } finally {
      if (mounted) setState(() => _isMovingToParent = false);
    }
  }

  /// Move camera to my location
  Future<void> _moveToMyLocation() async {
    if (kIsWeb || _isMovingToMyLocation || _currentLocation == null || _mapController == null) {
      return;
    }

    setState(() => _isMovingToMyLocation = true);

    try {
      await _mapController!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(_currentLocation!.latitude, _currentLocation!.longitude),
            zoom: 16,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Error moving to my location: $e');
    } finally {
      if (mounted) setState(() => _isMovingToMyLocation = false);
    }
  }

  /// Show group settings dialog (driver only)
  void _showGroupSettingsDialog() {
    if (_group == null) return;

    final schedule = _group!.sharingSchedule;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('그룹 설정'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name
              Text(
                '그룹명: ${_group!.name}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Group code with copy
              Row(
                children: [
                  const Text('코드: ', style: TextStyle(fontSize: 16)),
                  Text(
                    _group!.code,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _group!.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('코드가 복사되었습니다')),
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // Sharing schedule
              const Text(
                '위치 공유 시간',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          schedule.timeRangeString,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(schedule.weekdayString),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '* 설정 변경은 추후 업데이트 예정',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Divider(height: 24),

              // Members
              Text(
                '멤버 (${_groupMembers.length}명)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_groupMembers.isEmpty)
                const Text('멤버 정보 로딩 중...', style: TextStyle(color: Colors.grey))
              else
                ...(_groupMembers.map((member) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            member.role == UserRole.driver
                                ? Icons.directions_bus
                                : Icons.person,
                            size: 18,
                            color: member.role == UserRole.driver
                                ? Colors.green
                                : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(member.displayName)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: member.isSharing
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              member.statusText,
                              style: TextStyle(
                                fontSize: 11,
                                color: member.isSharing
                                    ? Colors.green.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingGroup) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('로딩 중...'),
          backgroundColor: Colors.green.shade100,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver-groups'),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_group?.name ?? '기사 화면'),
            if (_group != null)
              Text(
                '코드: ${_group!.code}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.green.shade100,
        centerTitle: true,
        actions: [
          // Group settings button
          if (_group != null)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showGroupSettingsDialog,
              tooltip: '그룹 설정',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Map or placeholder
          Positioned.fill(
            child: _isTracking && _currentLocation != null
                ? NaverMapWidget(
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
                            _statusMessage ?? '운행을 시작해주세요',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Sharing status badge (top)
          if (_isTracking)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isSharing ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSharing ? Icons.location_on : Icons.location_off,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isSharing ? '위치 공유 중' : '공유 중지됨',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Parent list (left sidebar) - shows ALL members including dimmed ones
          if (_isTracking && _allMemberLocations.isNotEmpty)
            Positioned(
              left: 16,
              top: 60,
              child: Container(
                width: 200,
                constraints: const BoxConstraints(maxHeight: 350),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade600,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '학부모 (${_allMemberLocations.length}명)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '공유: ${_parentLocations.length}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List - shows ALL members with dimmed for non-sharing
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allMemberLocations.length,
                        itemBuilder: (context, index) {
                          final member = _allMemberLocations[index];
                          final isSharing = member.isSharing && member.isRecent;
                          final isSelected = _selectedParentId == member.userId;

                          return Material(
                            color: isSelected
                                ? Colors.green.shade100
                                : (isSharing ? Colors.transparent : Colors.grey.shade100),
                            child: InkWell(
                              onTap: isSharing ? () => _moveToParent(member) : null,
                              child: Opacity(
                                opacity: isSharing ? 1.0 : 0.5,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSharing
                                            ? Icons.person_pin_circle
                                            : Icons.person_off,
                                        color: isSelected
                                            ? Colors.green.shade700
                                            : (isSharing
                                                ? Colors.blue.shade600
                                                : Colors.grey.shade500),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member.displayName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSharing
                                                    ? Colors.black87
                                                    : Colors.grey.shade600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              isSharing ? '공유 중' : '공유 중지됨',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isSharing
                                                    ? Colors.green.shade600
                                                    : Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSharing)
                                        Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: Colors.grey.shade400,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // My location button (when tracking)
                if (_isTracking && _currentLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton.icon(
                      onPressed: !_isMovingToMyLocation ? _moveToMyLocation : null,
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
                      label: Text(_isMovingToMyLocation ? '이동중...' : '내 위치'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(140, 40),
                      ),
                    ),
                  ),

                // Start/Stop tracking button
                ElevatedButton.icon(
                  onPressed: _isLoadingGroup
                      ? null
                      : () {
                          print('[DriverHome] Button pressed! _group: ${_group?.name ?? "null"}, _isTracking: $_isTracking');
                          if (_group == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_statusMessage ?? '그룹 정보가 없습니다'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          _toggleTracking();
                        },
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_isLoadingGroup
                      ? '로딩 중...'
                      : (_isTracking ? '운행 종료' : '운행 시작')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoadingGroup
                        ? Colors.grey
                        : (_isTracking ? Colors.red : Colors.green),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 50),
                    elevation: 8,
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
