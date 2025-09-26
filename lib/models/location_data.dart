class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;
  final String busId;
  final String driverId;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
    required this.busId,
    required this.driverId,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'busId': busId,
      'driverId': driverId,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      accuracy: map['accuracy']?.toDouble(),
      altitude: map['altitude']?.toDouble(),
      speed: map['speed']?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      busId: map['busId'] ?? '',
      driverId: map['driverId'] ?? '',
    );
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    DateTime? timestamp,
    String? busId,
    String? driverId,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      busId: busId ?? this.busId,
      driverId: driverId ?? this.driverId,
    );
  }

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, timestamp: $timestamp, busId: $busId)';
  }
}