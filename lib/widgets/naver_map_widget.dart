import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';

class NaverMapWidget extends StatefulWidget {
  final LocationData? busLocation;
  final List<ParentData> parentLocations;
  final bool showParentLocations;

  const NaverMapWidget({
    super.key,
    this.busLocation,
    this.parentLocations = const [],
    this.showParentLocations = false,
  });

  @override
  State<NaverMapWidget> createState() => _NaverMapWidgetState();
}

class _NaverMapWidgetState extends State<NaverMapWidget> {
  NaverMapController? _controller;
  final Set<NMarker> _markers = {};

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

    // Add basic markers (simplified version)
    if (widget.busLocation != null) {
      await _addSimpleBusMarker(widget.busLocation!);
    }

    if (widget.showParentLocations) {
      for (final parent in widget.parentLocations) {
        await _addSimpleParentMarker(parent);
      }
    }

    // Move camera to bus location if available
    if (widget.busLocation != null) {
      await _controller!.updateCamera(
        NCameraUpdate.fromCameraPosition(
          NCameraPosition(
            target: NLatLng(
              widget.busLocation!.latitude,
              widget.busLocation!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  Future<void> _addSimpleBusMarker(LocationData busLocation) async {
    if (_controller == null) return;

    final marker = NMarker(
      id: 'bus_${busLocation.busId}',
      position: NLatLng(busLocation.latitude, busLocation.longitude),
    );

    await _controller!.addOverlay(marker);
    _markers.add(marker);
  }

  Future<void> _addSimpleParentMarker(ParentData parent) async {
    if (_controller == null) return;

    final marker = NMarker(
      id: 'parent_${parent.parentId}',
      position: NLatLng(parent.latitude, parent.longitude),
    );

    await _controller!.addOverlay(marker);
    _markers.add(marker);
  }

  @override
  void didUpdateWidget(NaverMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busLocation != oldWidget.busLocation ||
        widget.parentLocations != oldWidget.parentLocations) {
      _updateMarkers();
    }
  }
}