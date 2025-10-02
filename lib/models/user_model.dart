/// User role enum
enum UserRole {
  driver,   // 기사
  teacher,  // 선생님
  parent,   // 학부모
}

/// User model
class UserModel {
  final String id;
  final String nickname;
  final UserRole role;
  final DateTime createdAt;
  String? groupId; // 참여한 그룹 ID

  UserModel({
    required this.id,
    required this.nickname,
    required this.role,
    required this.createdAt,
    this.groupId,
  });

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.parent,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      groupId: json['groupId'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'role': role.toString(),
      'createdAt': createdAt.toIso8601String(),
      'groupId': groupId,
    };
  }

  /// Copy with
  UserModel copyWith({
    String? id,
    String? nickname,
    UserRole? role,
    DateTime? createdAt,
    String? groupId,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
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
}