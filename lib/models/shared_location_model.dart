import 'user_model.dart';

/// Shared location model for Firebase Realtime Database
/// Represents a user's shared location in real-time
class SharedLocationModel {
  final String userId;
  final String groupId;
  final String displayName;
  final UserRole role;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final int timestamp; // Unix timestamp in milliseconds
  final bool isSharing;
  final bool isBoardingToday; // 오늘 탑승 여부 (학부모용)

  SharedLocationModel({
    required this.userId,
    required this.groupId,
    required this.displayName,
    required this.role,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    this.isSharing = true,
    this.isBoardingToday = true, // 기본값: 탑승
  });

  /// Create from Firebase Realtime DB JSON
  factory SharedLocationModel.fromRealtimeDbJson(
    Map<dynamic, dynamic> json,
    String userId,
    String groupId,
  ) {
    return SharedLocationModel(
      userId: userId,
      groupId: groupId,
      displayName: json['displayName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.parent,
      ),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as int? ?? 0,
      isSharing: json['isSharing'] as bool? ?? true,
      isBoardingToday: json['isBoardingToday'] as bool? ?? true,
    );
  }

  /// Convert to Firebase Realtime DB JSON
  Map<String, dynamic> toRealtimeDbJson() {
    return {
      'displayName': displayName,
      'role': role.toString(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp,
      'isSharing': isSharing,
      'isBoardingToday': isBoardingToday,
    };
  }

  /// Copy with
  SharedLocationModel copyWith({
    String? userId,
    String? groupId,
    String? displayName,
    UserRole? role,
    double? latitude,
    double? longitude,
    double? accuracy,
    int? timestamp,
    bool? isSharing,
    bool? isBoardingToday,
  }) {
    return SharedLocationModel(
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isSharing: isSharing ?? this.isSharing,
      isBoardingToday: isBoardingToday ?? this.isBoardingToday,
    );
  }

  /// Get DateTime from timestamp
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Check if location is recent (within last 5 minutes)
  bool get isRecent {
    final now = DateTime.now().millisecondsSinceEpoch;
    final fiveMinutes = 5 * 60 * 1000;
    return (now - timestamp) < fiveMinutes;
  }

  @override
  String toString() {
    return 'SharedLocationModel(userId: $userId, displayName: $displayName, '
        'lat: $latitude, lng: $longitude, isSharing: $isSharing, '
        'isBoardingToday: $isBoardingToday)';
  }
}
