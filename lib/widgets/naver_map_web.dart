import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:js' as js;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/location_data.dart';
import '../models/parent_data.dart';

class NaverMapWebWidget extends StatefulWidget {
  final LocationData? busLocation;
  final List<ParentData> parentLocations;
  final bool showParentLocations;

  const NaverMapWebWidget({
    super.key,
    this.busLocation,
    this.parentLocations = const [],
    this.showParentLocations = false,
  });

  @override
  State<NaverMapWebWidget> createState() => _NaverMapWebWidgetState();
}

class _NaverMapWebWidgetState extends State<NaverMapWebWidget> {
  late String _mapId;
  
  @override
  void initState() {
    super.initState();
    _mapId = 'map_${DateTime.now().millisecondsSinceEpoch}';
    
    if (kIsWeb) {
      _registerWebView();
    }
  }

  void _registerWebView() {
    final html.DivElement mapElement = html.DivElement()
      ..id = _mapId
      ..style.width = '100%'
      ..style.height = '100%';

    ui.platformViewRegistry.registerViewFactory(
      _mapId,
      (int viewId) {
        _initializeMap(mapElement);
        return mapElement;
      },
    );
  }

  void _initializeMap(html.DivElement mapElement) {
    html.window.onMessage.listen((event) {
      if (event.data is Map && event.data['type'] == 'mapReady') {
        _updateMapMarkers();
      }
    });

    // 네이버 지도 초기화 JavaScript 코드
    final initScript = '''
      (function() {
        function initMap() {
          if (typeof naver === 'undefined' || !naver.maps) {
            setTimeout(initMap, 100);
            return;
          }
          
          var mapOptions = {
            center: new naver.maps.LatLng(37.5665, 126.9780),
            zoom: 14,
            mapTypeControl: true,
            mapTypeControlOptions: {
              style: naver.maps.MapTypeControlStyle.BUTTON,
              position: naver.maps.Position.TOP_LEFT
            },
            zoomControl: true,
            zoomControlOptions: {
              style: naver.maps.ZoomControlStyle.SMALL,
              position: naver.maps.Position.TOP_RIGHT
            }
          };
          
          var map = new naver.maps.Map('$_mapId', mapOptions);
          window.naverMap_$_mapId = map;
          window.naverMarkers_$_mapId = [];
          
          // 지도 준비 완료 알림
          window.parent.postMessage({type: 'mapReady', mapId: '$_mapId'}, '*');
        }
        
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', initMap);
        } else {
          initMap();
        }
      })();
    ''';

    final scriptElement = html.ScriptElement();
    scriptElement.text = initScript;
    mapElement.append(scriptElement);
  }

  void _updateMapMarkers() {
    if (!kIsWeb) return;

    final updateScript = '''
      (function() {
        var map = window.naverMap_$_mapId;
        var markers = window.naverMarkers_$_mapId;
        
        if (!map) return;
        
        // 기존 마커 제거
        for (var i = 0; i < markers.length; i++) {
          markers[i].setMap(null);
        }
        markers.length = 0;
        
        ${_generateBusMarkerScript()}
        ${_generateParentMarkersScript()}
        
        ${_generateCameraUpdateScript()}
      })();
    ''';

    final scriptElement = html.ScriptElement();
    scriptElement.text = updateScript;
    html.document.head!.append(scriptElement);
    
    // 스크립트 실행 후 제거
    Future.delayed(const Duration(milliseconds: 100), () {
      scriptElement.remove();
    });
  }

  String _generateBusMarkerScript() {
    if (widget.busLocation == null) return '';
    
    return '''
      // 버스 마커 추가
      var busMarker = new naver.maps.Marker({
        position: new naver.maps.LatLng(${widget.busLocation!.latitude}, ${widget.busLocation!.longitude}),
        map: map,
        title: '셔틀버스',
        icon: {
          content: '<div style="background-color: blue; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px;">🚌</div>',
          anchor: new naver.maps.Point(15, 15)
        }
      });
      markers.push(busMarker);
      
      var busInfoWindow = new naver.maps.InfoWindow({
        content: '<div style="padding: 10px; font-size: 12px;"><strong>셔틀버스</strong><br/>버스 ID: ${widget.busLocation!.busId}</div>'
      });
      
      naver.maps.Event.addListener(busMarker, 'click', function() {
        if (busInfoWindow.getMap()) {
          busInfoWindow.close();
        } else {
          busInfoWindow.open(map, busMarker);
        }
      });
    ''';
  }

  String _generateParentMarkersScript() {
    if (!widget.showParentLocations || widget.parentLocations.isEmpty) return '';
    
    String script = '';
    for (final parent in widget.parentLocations) {
      final emoji = parent.isWaitingForPickup ? '🚏' : '👨‍👩‍👧‍👦';
      final bgColor = parent.isWaitingForPickup ? 'orange' : 'green';
      
      script += '''
        var parentMarker_${parent.parentId} = new naver.maps.Marker({
          position: new naver.maps.LatLng(${parent.latitude}, ${parent.longitude}),
          map: map,
          title: '${parent.parentName}',
          icon: {
            content: '<div style="background-color: $bgColor; color: white; padding: 4px 8px; border-radius: 4px; font-size: 12px;">$emoji</div>',
            anchor: new naver.maps.Point(15, 15)
          }
        });
        markers.push(parentMarker_${parent.parentId});
        
        var parentInfoWindow_${parent.parentId} = new naver.maps.InfoWindow({
          content: '<div style="padding: 10px; font-size: 12px;"><strong>${parent.parentName}</strong><br/>(${parent.childName})<br/>${parent.isWaitingForPickup ? '픽업 대기 중' : '일반'}</div>'
        });
        
        naver.maps.Event.addListener(parentMarker_${parent.parentId}, 'click', function() {
          if (parentInfoWindow_${parent.parentId}.getMap()) {
            parentInfoWindow_${parent.parentId}.close();
          } else {
            parentInfoWindow_${parent.parentId}.open(map, parentMarker_${parent.parentId});
          }
        });
      ''';
    }
    return script;
  }

  String _generateCameraUpdateScript() {
    if (widget.busLocation != null) {
      return '''
        // 버스 위치로 지도 중심 이동
        map.setCenter(new naver.maps.LatLng(${widget.busLocation!.latitude}, ${widget.busLocation!.longitude}));
        map.setZoom(15);
      ''';
    }
    return '';
  }

  @override
  void didUpdateWidget(NaverMapWebWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb && 
        (widget.busLocation != oldWidget.busLocation ||
         widget.parentLocations != oldWidget.parentLocations)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _updateMapMarkers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: HtmlElementView(viewType: _mapId),
    );
  }
}