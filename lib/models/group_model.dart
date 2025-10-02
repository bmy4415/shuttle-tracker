/// Group model for shuttle bus tracking
class GroupModel {
  final String id;
  final String code; // 6자리 그룹 코드 (예: "LION3A")
  final String name; // 그룹 이름 (예: "오전 셔틀버스")
  final String driverId; // 기사 ID
  final String driverName; // 기사 이름
  final List<String> memberIds; // 참여한 멤버 ID 목록
  final DateTime createdAt;
  final bool isActive; // 운행 중 여부

  GroupModel({
    required this.id,
    required this.code,
    required this.name,
    required this.driverId,
    required this.driverName,
    required this.memberIds,
    required this.createdAt,
    this.isActive = false,
  });

  /// Create from JSON
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      memberIds: (json['memberIds'] as List<dynamic>).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'driverId': driverId,
      'driverName': driverName,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Copy with
  GroupModel copyWith({
    String? id,
    String? code,
    String? name,
    String? driverId,
    String? driverName,
    List<String>? memberIds,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get member count
  int get memberCount => memberIds.length;
}