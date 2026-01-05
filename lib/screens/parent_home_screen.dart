import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/location_data.dart';
import '../models/shared_location_model.dart';
import '../models/group_member_model.dart';
import '../services/location_service.dart';
import '../services/location_sharing_service.dart';
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
  LocationData? _myLocation;
  bool _isLoadingLocation = false;
  bool _isSharing = true; // 위치 공유 상태

  // Services
  final LocationService _locationService = LocationService();
  late final LocationSharingService _sharingService;

  // Stream subscriptions
  StreamSubscription<LocationData>? _myLocationSubscription;
  StreamSubscription<SharedLocationModel?>? _driverLocationSubscription;
  StreamSubscription<List<GroupMemberModel>>? _membersSubscription;

  // Group members (names only, for dialog)
  List<GroupMemberModel> _groupMembers = [];

  // Map controller for camera movement
  NaverMapController? _mapController;

  // Button state management
  bool _isMovingToMyLocation = false;
  bool _isMovingToBusLocation = false;

  @override
  void initState() {
    super.initState();
    _sharingService = LocationSharingService.getInstance();
    _startLocationSharing();
  }

  @override
  void dispose() {
    _myLocationSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    _membersSubscription?.cancel();
    _mapController = null;
    super.dispose();
  }

  /// Start location sharing and subscribe to driver location
  Future<void> _startLocationSharing() async {
    if (widget.group == null) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final groupId = widget.group!.id;
      final userId = widget.user.id;

      // Setup disconnect handler
      await _sharingService.setupDisconnectHandler(
        groupId: groupId,
        userId: userId,
      );

      // Start sharing my location
      await _sharingService.startSharing(
        groupId: groupId,
        userId: userId,
        displayName: widget.user.nickname,
        role: widget.user.role,
      );

      setState(() {
        _isSharing = true;
      });

      // Subscribe to driver location
      _driverLocationSubscription = _sharingService
          .watchDriverLocation(
            groupId: groupId,
            driverId: widget.group!.driverId,
          )
          .listen((driverLocation) {
        if (mounted && driverLocation != null && driverLocation.isSharing) {
          setState(() {
            _busLocation = LocationData(
              latitude: driverLocation.latitude,
              longitude: driverLocation.longitude,
              accuracy: driverLocation.accuracy ?? 10.0,
              timestamp: driverLocation.dateTime,
              busId: 'driver',
              driverId: driverLocation.userId,
            );
          });
        }
      });

      // Subscribe to group members (for info dialog)
      _membersSubscription = _sharingService
          .watchGroupMembers(groupId: groupId)
          .listen((members) {
        if (mounted) {
          setState(() {
            _groupMembers = members;
          });
        }
      });

      // Start tracking my own GPS location
      _myLocationSubscription = _locationService
          .startLocationStream(busId: 'PARENT', driverId: userId)
          .listen((myLocation) async {
        if (!mounted) return;

        setState(() {
          _myLocation = myLocation;
          _isLoadingLocation = false;
        });

        // Update my location in Firebase if sharing
        if (_isSharing) {
          await _sharingService.updateLocation(
            groupId: groupId,
            location: SharedLocationModel(
              userId: userId,
              groupId: groupId,
              displayName: widget.user.nickname,
              role: widget.user.role,
              latitude: myLocation.latitude,
              longitude: myLocation.longitude,
              accuracy: myLocation.accuracy,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              isSharing: true,
            ),
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location sharing: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Toggle location sharing
  Future<void> _toggleSharing() async {
    if (widget.group == null) return;

    final groupId = widget.group!.id;
    final userId = widget.user.id;

    try {
      if (_isSharing) {
        await _sharingService.stopSharing(groupId: groupId, userId: userId);
        setState(() {
          _isSharing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 공유가 중지되었습니다')),
          );
        }
      } else {
        await _sharingService.startSharing(
          groupId: groupId,
          userId: userId,
          displayName: widget.user.nickname,
          role: widget.user.role,
        );
        setState(() {
          _isSharing = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 공유가 시작되었습니다')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling sharing: $e');
      }
    }
  }

  /// Show group info dialog
  void _showGroupInfoDialog() {
    if (widget.group == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('그룹 정보'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name
              Text(
                '이름: ${widget.group!.name}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Group code with copy button
              Row(
                children: [
                  const Text('코드: ', style: TextStyle(fontSize: 16)),
                  Text(
                    widget.group!.code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.group!.code),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('코드가 복사되었습니다')),
                      );
                    },
                    tooltip: '복사',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sharing schedule
              const Text(
                '위치 공유 시간',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.group!.sharingSchedule.timeRangeString),
              Text(widget.group!.sharingSchedule.weekdayString),
              if (widget.group!.sharingSchedule.excludeHolidays)
                const Text(
                  '공휴일 제외',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              const SizedBox(height: 12),

              // Members list
              const Text(
                '멤버',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_groupMembers.isEmpty)
                const Text(
                  '멤버 정보 로딩 중...',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...(_groupMembers.map((member) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            member.role == UserRole.driver
                                ? Icons.directions_bus
                                : Icons.person,
                            size: 16,
                            color: member.role == UserRole.driver
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(member.displayName),
                          if (member.role == UserRole.driver)
                            const Text(' (기사)',
                                style: TextStyle(color: Colors.blue)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: member.isOnline
                                  ? Colors.green.shade100
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              member.statusText,
                              style: TextStyle(
                                fontSize: 10,
                                color: member.isOnline
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
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// Move camera to my location
  Future<void> _moveToMyLocation() async {
    if (kIsWeb) return;
    if (_isMovingToMyLocation || _myLocation == null || _mapController == null) {
      return;
    }

    setState(() => _isMovingToMyLocation = true);

    try {
      await _mapController!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(_myLocation!.latitude, _myLocation!.longitude),
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

  /// Move camera to bus location
  Future<void> _moveToBusLocation() async {
    if (kIsWeb) return;
    if (_isMovingToBusLocation || _busLocation == null || _mapController == null) {
      return;
    }

    setState(() => _isMovingToBusLocation = true);

    try {
      await _mapController!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(_busLocation!.latitude, _busLocation!.longitude),
            zoom: 16,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Error moving to bus location: $e');
    } finally {
      if (mounted) setState(() => _isMovingToBusLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학부모 화면'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          // Group info button
          if (widget.group != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showGroupInfoDialog,
              tooltip: '그룹 정보',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: '설정',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: NaverMapWidget(
              busLocation: _busLocation,
              currentUserLocation: _myLocation,
              isDriverView: false,
              onMapControllerReady: (controller) {
                _mapController = controller;
              },
            ),
          ),

          // Sharing status badge (top)
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

          // Bottom control panel
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
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        widget.user.nickname,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location buttons row
                  Row(
                    children: [
                      // My location button
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
                          label: const Text('내위치', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Bus location button
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
                          label: const Text('셔틀위치', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Stop/Start sharing button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleSharing,
                      icon: Icon(_isSharing ? Icons.stop : Icons.play_arrow),
                      label: Text(_isSharing ? '공유 중지' : '공유 시작'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSharing ? Colors.red.shade700 : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoadingLocation)
            Positioned(
              top: 80,
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
                      Text('위치 확인 중...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
