import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';
import 'custom_marker_widgets.dart';

class NaverMapWidget extends StatefulWidget {
  final LocationData? busLocation;
  final List<ParentData> parentLocations;
  final bool showParentLocations;
  final LocationData? currentUserLocation; // 현재 사용자 위치 (학부모인 경우)
  final bool isDriverView; // 기사 뷰인지 학부모 뷰인지
  final Function(NaverMapController)? onMapControllerReady; // 컨트롤러 콜백

  const NaverMapWidget({
    super.key,
    this.busLocation,
    this.parentLocations = const [],
    this.showParentLocations = false,
    this.currentUserLocation,
    this.isDriverView = false,
    this.onMapControllerReady,
  });

  @override
  State<NaverMapWidget> createState() => _NaverMapWidgetState();
}

class _NaverMapWidgetState extends State<NaverMapWidget> {
  NaverMapController? _controller;
  final Set<NMarker> _markers = {};
  bool _isInitialCameraSet = false;

  @override
  Widget build(BuildContext context) {
    // Web does not support Naver Maps - show placeholder
    if (kIsWeb) {
      return _buildWebPlaceholder();
    }

    // Force update markers whenever parentLocations change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateMarkers();
      }
    });

    return NaverMap(
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(37.5665, 126.9780), // Seoul coordinates
          zoom: 14,
        ),
        mapType: NMapType.basic,
      ),
      onMapReady: (NaverMapController controller) async {
        _controller = controller;
        await _updateMarkers();
        // 부모 위젯에 컨트롤러 전달
        widget.onMapControllerReady?.call(controller);
      },
    );
  }

  /// Web placeholder for Naver Map (not supported on web)
  Widget _buildWebPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '웹에서는 지도가 지원되지 않습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '모바일 앱에서 지도를 확인하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            // Show location info if available
            if (widget.busLocation != null || widget.currentUserLocation != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (widget.currentUserLocation != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.person_pin_circle, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            '내 위치: ${widget.currentUserLocation!.latitude.toStringAsFixed(4)}, ${widget.currentUserLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.busLocation != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.directions_bus, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '셔틀 위치: ${widget.busLocation!.latitude.toStringAsFixed(4)}, ${widget.busLocation!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                    if (widget.parentLocations.isNotEmpty) ...[
                      const Divider(),
                      Text(
                        '학부모 ${widget.parentLocations.length}명 접속 중',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateMarkers() async {
    if (_controller == null) return;

    // Clear existing markers
    for (final marker in _markers) {
      await _controller!.deleteOverlay(marker.info);
    }
    _markers.clear();

    if (widget.isDriverView) {
      // 기사 뷰: 기사 위치 + 모든 학부모 위치
      if (widget.busLocation != null) {
        await _addDriverMarker(widget.busLocation!);
      }

      if (widget.showParentLocations) {
        for (final parent in widget.parentLocations) {
          await _addParentMarker(parent);
        }
      }
    } else {
      // 학부모 뷰: 학부모 본인 위치 + 기사 위치
      if (widget.currentUserLocation != null) {
        await _addCurrentUserMarker(widget.currentUserLocation!);
      }

      if (widget.busLocation != null) {
        await _addDriverMarker(widget.busLocation!);
      }
    }

    // Only move camera on initial load, not on every marker update
    // This prevents overriding user's manual camera movements
    if (!_isInitialCameraSet && _controller != null) {
      if (widget.isDriverView && widget.busLocation != null) {
        await _moveCameraTo(widget.busLocation!.latitude, widget.busLocation!.longitude);
        _isInitialCameraSet = true;
      } else if (!widget.isDriverView && widget.currentUserLocation != null) {
        await _moveCameraTo(widget.currentUserLocation!.latitude, widget.currentUserLocation!.longitude);
        _isInitialCameraSet = true;
      } else if (widget.busLocation != null) {
        await _moveCameraTo(widget.busLocation!.latitude, widget.busLocation!.longitude);
        _isInitialCameraSet = true;
      }
    }
  }

  // 기사 마커 (커스텀 위젯)
  Future<void> _addDriverMarker(LocationData busLocation) async {
    if (_controller == null) return;

    print('Adding driver marker at: ${busLocation.latitude}, ${busLocation.longitude}');

    try {
      // 커스텀 위젯으로 마커 아이콘 생성 (핀 모양)
      final markerIcon = await NOverlayImage.fromWidget(
        widget: CustomMarkerWidgets.driverMarker(
          label: widget.isDriverView ? '내 위치' : '셔틀버스',
        ),
        size: const Size(80, 90),
        context: context,
      );

      final marker = NMarker(
        id: 'driver_${busLocation.busId}',
        position: NLatLng(busLocation.latitude, busLocation.longitude),
        icon: markerIcon,
      );

      await _controller!.addOverlay(marker);
      _markers.add(marker);
      print('Driver marker added successfully');
    } catch (e) {
      print('Error adding driver marker: $e');
    }
  }

  // 학부모 마커 (커스텀 위젯)
  Future<void> _addParentMarker(ParentData parent) async {
    if (_controller == null) return;

    print('Adding parent marker: ${parent.parentName} at ${parent.latitude}, ${parent.longitude}');

    try {
      // 커스텀 위젯으로 마커 아이콘 생성 (핀 모양)
      final markerIcon = await NOverlayImage.fromWidget(
        widget: CustomMarkerWidgets.parentMarker(
          name: parent.parentName,
          isWaitingForPickup: parent.isWaitingForPickup,
        ),
        size: const Size(80, 100),
        context: context,
      );

      final marker = NMarker(
        id: 'parent_${parent.parentId}',
        position: NLatLng(parent.latitude, parent.longitude),
        icon: markerIcon,
      );

      await _controller!.addOverlay(marker);
      _markers.add(marker);
      print('Parent marker added successfully: ${parent.parentName}');
    } catch (e) {
      print('Error adding parent marker: $e');
    }
  }

  // 현재 사용자 마커 (내 위치, 커스텀 위젯)
  Future<void> _addCurrentUserMarker(LocationData userLocation) async {
    if (_controller == null) return;

    print('Adding current user marker at: ${userLocation.latitude}, ${userLocation.longitude}');

    try {
      // 커스텀 위젯으로 마커 아이콘 생성 (핀 모양 - 학부모용이므로 isDriver = false)
      final markerIcon = await NOverlayImage.fromWidget(
        widget: CustomMarkerWidgets.currentUserMarker(isDriver: false),
        size: const Size(80, 90),
        context: context,
      );

      final marker = NMarker(
        id: 'current_user',
        position: NLatLng(userLocation.latitude, userLocation.longitude),
        icon: markerIcon,
      );

      await _controller!.addOverlay(marker);
      _markers.add(marker);
      print('Current user marker added successfully');
    } catch (e) {
      print('Error adding current user marker: $e');
    }
  }

  // 카메라 이동 함수
  Future<void> _moveCameraTo(double latitude, double longitude) async {
    if (_controller == null) return;

    await _controller!.updateCamera(
      NCameraUpdate.fromCameraPosition(
        NCameraPosition(
          target: NLatLng(latitude, longitude),
          zoom: 15,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(NaverMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update markers if there are significant changes to reduce rendering load
    bool shouldUpdate = false;

    // Check if driver view mode changed
    if (widget.isDriverView != oldWidget.isDriverView) {
      shouldUpdate = true;
    }

    // Check if bus location changed significantly (more than ~20m to reduce updates)
    if (widget.busLocation != null && oldWidget.busLocation != null) {
      double latDiff = (widget.busLocation!.latitude - oldWidget.busLocation!.latitude).abs();
      double lngDiff = (widget.busLocation!.longitude - oldWidget.busLocation!.longitude).abs();
      if (latDiff > 0.0002 || lngDiff > 0.0002) { // ~20m threshold (increased from 10m)
        shouldUpdate = true;
      }
    } else if (widget.busLocation != oldWidget.busLocation) {
      shouldUpdate = true;
    }

    // Check if user location changed significantly (20m threshold)
    if (widget.currentUserLocation != null && oldWidget.currentUserLocation != null) {
      double latDiff = (widget.currentUserLocation!.latitude - oldWidget.currentUserLocation!.latitude).abs();
      double lngDiff = (widget.currentUserLocation!.longitude - oldWidget.currentUserLocation!.longitude).abs();
      if (latDiff > 0.0002 || lngDiff > 0.0002) { // ~20m threshold
        shouldUpdate = true;
      }
    } else if (widget.currentUserLocation != oldWidget.currentUserLocation) {
      shouldUpdate = true;
    }

    // Check if parent locations changed
    if (widget.parentLocations.length != oldWidget.parentLocations.length) {
      shouldUpdate = true;
      print('Parent count changed: ${oldWidget.parentLocations.length} -> ${widget.parentLocations.length}');
    } else if (widget.parentLocations.isNotEmpty && oldWidget.parentLocations.isNotEmpty) {
      // Check if any parent location changed significantly
      for (int i = 0; i < widget.parentLocations.length && i < oldWidget.parentLocations.length; i++) {
        final newParent = widget.parentLocations[i];
        final oldParent = oldWidget.parentLocations[i];

        // Check if the same parent moved significantly (using parent ID)
        if (newParent.parentId == oldParent.parentId) {
          double latDiff = (newParent.latitude - oldParent.latitude).abs();
          double lngDiff = (newParent.longitude - oldParent.longitude).abs();
          if (latDiff > 0.00005 || lngDiff > 0.00005) { // ~5m threshold for more responsive updates
            shouldUpdate = true;
            print('Parent ${newParent.parentName} moved: lat diff: $latDiff, lng diff: $lngDiff');
            print('New position: ${newParent.latitude}, ${newParent.longitude}');
            print('Old position: ${oldParent.latitude}, ${oldParent.longitude}');
            break;
          }
        }
      }
    } else if (widget.parentLocations.isNotEmpty && oldWidget.parentLocations.isEmpty) {
      shouldUpdate = true;
      print('Parents added: ${widget.parentLocations.length} parents');
    }

    if (shouldUpdate) {
      // Debounce rapid updates to prevent excessive rendering
      Future.delayed(const Duration(milliseconds: 200), () { // Reduced from 500ms to 200ms for more responsiveness
        if (mounted) {
          _updateMarkers();
        }
      });
    }
  }
}