/// Feedback status enum
enum FeedbackStatus {
  pending,   // 접수됨
  reviewing, // 확인중
  resolved,  // 해결됨
}

/// Feedback model for beta testing
class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;      // 'parent' | 'driver'
  final String? groupId;
  final String screenName;    // Screen where feedback was submitted
  final String message;       // Feedback content
  final DateTime createdAt;
  final FeedbackStatus status;
  final String? reply;        // Developer reply (manually entered via Firebase Console)
  final DateTime? repliedAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.groupId,
    required this.screenName,
    required this.message,
    required this.createdAt,
    this.status = FeedbackStatus.pending,
    this.reply,
    this.repliedAt,
  });

  /// Create from JSON
  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userRole: json['userRole'] as String,
      groupId: json['groupId'] as String?,
      screenName: json['screenName'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: FeedbackStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FeedbackStatus.pending,
      ),
      reply: json['reply'] as String?,
      repliedAt: json['repliedAt'] != null
          ? DateTime.parse(json['repliedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'groupId': groupId,
      'screenName': screenName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'reply': reply,
      'repliedAt': repliedAt?.toIso8601String(),
    };
  }

  /// Copy with
  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userRole,
    String? groupId,
    String? screenName,
    String? message,
    DateTime? createdAt,
    FeedbackStatus? status,
    String? reply,
    DateTime? repliedAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      groupId: groupId ?? this.groupId,
      screenName: screenName ?? this.screenName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      reply: reply ?? this.reply,
      repliedAt: repliedAt ?? this.repliedAt,
    );
  }

  /// Get status display name in Korean
  String get statusDisplayName {
    switch (status) {
      case FeedbackStatus.pending:
        return '접수됨';
      case FeedbackStatus.reviewing:
        return '확인중';
      case FeedbackStatus.resolved:
        return '해결됨';
    }
  }

  /// Check if feedback has a reply
  bool get hasReply => reply != null && reply!.isNotEmpty;
}
