import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Authentication service interface
abstract class AuthService {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> createUser(UserRole role, {String? nickname});
  Future<void> updateUser(UserModel user);
  Future<void> logout();
  Future<void> resetAccount();
}

/// Firebase authentication service implementation
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserModel?> getCurrentUser() async {
    // Get Firebase Auth user
    final authUser = _auth.currentUser;
    if (authUser == null) {
      // Sign in anonymously if not authenticated
      await _auth.signInAnonymously();
      return null; // First time user, needs to select role
    }

    try {
      final doc = await _firestore.collection('users').doc(authUser.uid).get();
      if (!doc.exists) return null; // User exists in Auth but not in Firestore
      return UserModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<UserModel> createUser(UserRole role, {String? nickname}) async {
    // Ensure user is authenticated
    User? authUser = _auth.currentUser;
    if (authUser == null) {
      final credential = await _auth.signInAnonymously();
      authUser = credential.user!;
    }

    final user = UserModel(
      id: authUser.uid,
      nickname: nickname ?? _generateRandomNickname(),
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(authUser.uid).set(user.toJson());

    print('Created user: ${user.id} (${user.nickname}) - Role: ${user.role}');
    return user;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
    print('Updated user: ${user.id}');
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
    print('Logged out');
  }

  @override
  Future<void> resetAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser.uid).delete();

      // Delete Firebase Auth user
      await currentUser.delete();

      // Sign in anonymously to create new user
      await _auth.signInAnonymously();

      print('Account reset completed');
    }
  }

  /// Generate random nickname (Korean style)
  String _generateRandomNickname() {
    final adjectives = [
      '야생의', '용감한', '지혜로운', '빠른', '조용한',
      '활발한', '느긋한', '친절한', '명랑한', '씩씩한',
      '귀여운', '멋진', '강한', '날쌘', '똑똑한',
    ];

    final animals = [
      '코끼리', '사자', '호랑이', '토끼', '여우',
      '늑대', '곰', '독수리', '판다', '기린',
      '다람쥐', '펭귄', '돌고래', '고래', '사슴',
    ];

    final random = Random();
    final adjective = adjectives[random.nextInt(adjectives.length)];
    final animal = animals[random.nextInt(animals.length)];

    return '$adjective $animal';
  }
}

/// Factory to get auth service instance
class AuthServiceFactory {
  static AuthService? _instance;

  static Future<AuthService> getInstance() async {
    _instance ??= FirebaseAuthService();
    return _instance!;
  }
}