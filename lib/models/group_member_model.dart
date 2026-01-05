import 'user_model.dart';

/// Group member model
/// Represents a member in a group (for member list display)
class GroupMemberModel {
  final String userId;
  final String displayName;
  final UserRole role;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isSharing; // Currently sharing location

  GroupMemberModel({
    required this.userId,
    required this.displayName,
    required this.role,
    this.isOnline = false,
    this.lastSeen,
    this.isSharing = false,
  });

  /// Create from Firebase Realtime DB JSON (presence data)
  factory GroupMemberModel.fromRealtimeDbJson(
    Map<dynamic, dynamic> json,
    String odlI,
  ) {
    return GroupMemberModel(
      userId: odlI,
      displayName: json['displayName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.parent,
      ),
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int)
          : null,
      isSharing: json['isSharing'] as bool? ?? false,
    );
  }

  /// Convert to Firebase Realtime DB JSON
  Map<String, dynamic> toRealtimeDbJson() {
    return {
      'displayName': displayName,
      'role': role.toString(),
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isSharing': isSharing,
    };
  }

  /// Copy with
  GroupMemberModel copyWith({
    String? userId,
    String? displayName,
    UserRole? role,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isSharing,
  }) {
    return GroupMemberModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isSharing: isSharing ?? this.isSharing,
    );
  }

  /// Get role display name in Korean
  String get roleDisplayName {
    switch (role) {
      case UserRole.driver:
        return '기사';
      case UserRole.teacher:
        return '선생님';
      case UserRole.parent:
        return '학부모';
    }
  }

  /// Check if member was seen recently (within last 5 minutes)
  bool get isRecentlyActive {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    return now.difference(lastSeen!).inMinutes < 5;
  }

  /// Get status text
  String get statusText {
    if (isOnline && isSharing) return '위치 공유 중';
    if (isOnline) return '접속 중';
    if (isRecentlyActive) return '최근 접속';
    return '오프라인';
  }

  @override
  String toString() {
    return 'GroupMemberModel(userId: $userId, displayName: $displayName, '
        'role: $role, isOnline: $isOnline, isSharing: $isSharing)';
  }
}
