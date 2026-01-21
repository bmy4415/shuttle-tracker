import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';
import '../models/user_model.dart';

/// Feedback service interface
abstract class FeedbackService {
  Future<void> submitFeedback(FeedbackModel feedback);
  Future<List<FeedbackModel>> getMyFeedbacks(String userId);
  Stream<List<FeedbackModel>> watchMyFeedbacks(String userId);
}

/// Firestore feedback service implementation
class FirestoreFeedbackService implements FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> submitFeedback(FeedbackModel feedback) async {
    final feedbackDoc = _firestore.collection('feedback').doc(feedback.id);
    await feedbackDoc.set(feedback.toJson());
    print('Submitted feedback: ${feedback.id}');
  }

  @override
  Future<List<FeedbackModel>> getMyFeedbacks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FeedbackModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting feedbacks: $e');
      return [];
    }
  }

  @override
  Stream<List<FeedbackModel>> watchMyFeedbacks(String userId) {
    return _firestore
        .collection('feedback')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Create a new feedback with auto-generated ID and context
  FeedbackModel createFeedback({
    required UserModel user,
    required String message,
    required String screenName,
    String? groupId,
  }) {
    final docId = _firestore.collection('feedback').doc().id;
    return FeedbackModel(
      id: docId,
      userId: user.id,
      userName: user.nickname,
      userRole: user.role == UserRole.driver ? 'driver' : 'parent',
      groupId: groupId,
      screenName: screenName,
      message: message,
      createdAt: DateTime.now(),
      status: FeedbackStatus.pending,
    );
  }
}

/// Factory to get feedback service instance
class FeedbackServiceFactory {
  static FeedbackService? _instance;

  static FeedbackService getInstance() {
    _instance ??= FirestoreFeedbackService();
    return _instance!;
  }
}
