import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';

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

  // 기사 마커 (파란색)
  Future<void> _addDriverMarker(LocationData busLocation) async {
    if (_controller == null) return;

    print('Adding driver marker at: ${busLocation.latitude}, ${busLocation.longitude}');

    final marker = NMarker(
      id: 'driver_${busLocation.busId}',
      position: NLatLng(busLocation.latitude, busLocation.longitude),
    );

    try {
      // 파란색으로 설정
      marker.setIconTintColor(Colors.blue);
      await _controller!.addOverlay(marker);
      _markers.add(marker);
      print('Driver marker added successfully');
    } catch (e) {
      print('Error adding driver marker: $e');
    }
  }

  // 학부모 마커 (초록색/주황색)
  Future<void> _addParentMarker(ParentData parent) async {
    if (_controller == null) return;

    print('Adding parent marker: ${parent.parentName} at ${parent.latitude}, ${parent.longitude}');

    final marker = NMarker(
      id: 'parent_${parent.parentId}',
      position: NLatLng(parent.latitude, parent.longitude),
    );

    try {
      // 픽업 대기 중이면 주황색, 아니면 초록색
      marker.setIconTintColor(
        parent.isWaitingForPickup ? Colors.orange : Colors.green
      );
      await _controller!.addOverlay(marker);
      _markers.add(marker);
      print('Parent marker added successfully: ${parent.parentName}');
    } catch (e) {
      print('Error adding parent marker: $e');
    }
  }

  // 현재 사용자 마커 (내 위치, 빨간색)
  Future<void> _addCurrentUserMarker(LocationData userLocation) async {
    if (_controller == null) return;

    print('Adding current user marker at: ${userLocation.latitude}, ${userLocation.longitude}');

    final marker = NMarker(
      id: 'current_user',
      position: NLatLng(userLocation.latitude, userLocation.longitude),
    );

    try {
      // 빨간색으로 설정 (내 위치)
      marker.setIconTintColor(Colors.red);
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
    }

    if (shouldUpdate) {
      // Debounce rapid updates to prevent excessive rendering
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _updateMarkers();
        }
      });
    }
  }
}