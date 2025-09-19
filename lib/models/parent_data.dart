class ParentData {
  final String parentId;
  final String parentName;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final String childName;
  final bool isWaitingForPickup;

  ParentData({
    required this.parentId,
    required this.parentName,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    required this.childName,
    this.isWaitingForPickup = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'parentName': parentName,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'childName': childName,
      'isWaitingForPickup': isWaitingForPickup,
    };
  }

  factory ParentData.fromMap(Map<String, dynamic> map) {
    return ParentData(
      parentId: map['parentId'] ?? '',
      parentName: map['parentName'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      accuracy: map['accuracy']?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      childName: map['childName'] ?? '',
      isWaitingForPickup: map['isWaitingForPickup'] ?? false,
    );
  }

  @override
  String toString() {
    return 'ParentData(parentName: $parentName, childName: $childName, lat: ${latitude.toStringAsFixed(4)}, lng: ${longitude.toStringAsFixed(4)}, waiting: $isWaitingForPickup)';
  }
}