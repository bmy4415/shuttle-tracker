import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';

class GoogleMapWidget extends StatefulWidget {
  final LocationData? busLocation;
  final List<ParentData> parentLocations;
  final bool showParentLocations;

  const GoogleMapWidget({
    super.key,
    this.busLocation,
    this.parentLocations = const [],
    this.showParentLocations = false,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(37.5665, 126.9780), // Seoul coordinates
        zoom: 14,
      ),
      onMapCreated: (GoogleMapController controller) {
        _controller = controller;
        _updateMarkers();
      },
      markers: _markers,
    );
  }

  void _updateMarkers() {
    _markers.clear();

    // Add bus marker
    if (widget.busLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('bus_${widget.busLocation!.busId}'),
          position: LatLng(
            widget.busLocation!.latitude,
            widget.busLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: '셔틀버스',
            snippet: '버스 ID: ${widget.busLocation!.busId}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Move camera to bus location
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              widget.busLocation!.latitude,
              widget.busLocation!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    }

    // Add parent markers
    if (widget.showParentLocations) {
      for (final parent in widget.parentLocations) {
        _markers.add(
          Marker(
            markerId: MarkerId('parent_${parent.parentId}'),
            position: LatLng(parent.latitude, parent.longitude),
            infoWindow: InfoWindow(
              title: parent.parentName,
              snippet: '${parent.childName} - ${parent.isWaitingForPickup ? '픽업 대기' : '일반'}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              parent.isWaitingForPickup 
                ? BitmapDescriptor.hueOrange 
                : BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busLocation != oldWidget.busLocation ||
        widget.parentLocations != oldWidget.parentLocations) {
      _updateMarkers();
    }
  }
}