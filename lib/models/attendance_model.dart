/// Attendance status enum
enum AttendanceStatus {
  riding,      // 탑승 예정
  notRiding,   // 오늘은 탑승하지 않음
  onBoard,     // 탑승 완료
  dropped,     // 하차 완료
}

/// Attendance model for tracking student boarding status
class AttendanceModel {
  final String id;
  final String groupId;
  final String studentId;   // 학생(학부모) ID
  final String studentName; // 학생(학부모) 이름
  final AttendanceStatus status;
  final DateTime date; // 날짜 (YYYY-MM-DD)
  final DateTime? updatedAt;
  final String? updatedBy; // 누가 업데이트 했는지 (기사/선생님/학부모)

  AttendanceModel({
    required this.id,
    required this.groupId,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.date,
    this.updatedAt,
    this.updatedBy,
  });

  /// Create from JSON
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => AttendanceStatus.riding,
      ),
      date: DateTime.parse(json['date'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'studentId': studentId,
      'studentName': studentName,
      'status': status.toString(),
      'date': date.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  /// Copy with
  AttendanceModel copyWith({
    String? id,
    String? groupId,
    String? studentId,
    String? studentName,
    AttendanceStatus? status,
    DateTime? date,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      status: status ?? this.status,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Get status display name in Korean
  String get statusDisplayName {
    switch (status) {
      case AttendanceStatus.riding:
        return '탑승 예정';
      case AttendanceStatus.notRiding:
        return '탑승하지 않음';
      case AttendanceStatus.onBoard:
        return '탑승 완료';
      case AttendanceStatus.dropped:
        return '하차 완료';
    }
  }

  /// Check if student is riding today
  bool get isRidingToday => status == AttendanceStatus.riding ||
                            status == AttendanceStatus.onBoard;
}