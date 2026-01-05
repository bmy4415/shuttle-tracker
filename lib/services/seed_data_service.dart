import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

/// Seed data service for local development
/// Creates test data only in local environment
class SeedDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test group code that parents can use to join
  static const String testGroupCode = 'TEST01';

  /// Test driver ID
  static const String testDriverId = 'test-driver-001';

  /// Initialize seed data (only in local environment)
  static Future<void> initialize() async {
    if (!EnvConfig.isLocal) {
      if (kDebugMode) {
        print('SeedData: Skipping seed data (not local environment)');
      }
      return;
    }

    if (kDebugMode) {
      print('SeedData: Initializing test data for local development...');
    }

    await _createTestDriver();
    await _createTestGroup();
    await _createTestParents();

    if (kDebugMode) {
      print('SeedData: ✅ Test data ready!');
      print('SeedData: 📋 Test group code: $testGroupCode');
    }
  }

  /// Create test driver account
  static Future<void> _createTestDriver() async {
    final driverDoc = _firestore.collection('users').doc(testDriverId);
    final snapshot = await driverDoc.get();

    if (!snapshot.exists) {
      final testDriver = UserModel(
        id: testDriverId,
        nickname: '테스트 기사님',
        role: UserRole.driver,
        createdAt: DateTime.now(),
        groupId: 'test-group-001',
      );

      await driverDoc.set(testDriver.toJson());
      if (kDebugMode) {
        print('SeedData: Created test driver: ${testDriver.nickname}');
      }
    }
  }

  /// Create test group
  static Future<void> _createTestGroup() async {
    final groupDoc = _firestore.collection('groups').doc('test-group-001');
    final snapshot = await groupDoc.get();

    if (!snapshot.exists) {
      final testGroup = GroupModel(
        id: 'test-group-001',
        code: testGroupCode,
        name: '테스트 셔틀버스',
        driverId: testDriverId,
        driverName: '테스트 기사님',
        memberIds: [],
        createdAt: DateTime.now(),
        isActive: true,
      );

      await groupDoc.set(testGroup.toJson());
      if (kDebugMode) {
        print('SeedData: Created test group: ${testGroup.name} (code: $testGroupCode)');
      }
    }
  }

  /// Create test parent accounts
  static Future<void> _createTestParents() async {
    final testParents = [
      UserModel(
        id: 'test-parent-001',
        nickname: '김민수 학부모',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        groupId: 'test-group-001',
      ),
      UserModel(
        id: 'test-parent-002',
        nickname: '이영희 학부모',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        groupId: 'test-group-001',
      ),
      UserModel(
        id: 'test-parent-003',
        nickname: '박철수 학부모',
        role: UserRole.parent,
        createdAt: DateTime.now(),
        groupId: 'test-group-001',
      ),
    ];

    for (final parent in testParents) {
      final parentDoc = _firestore.collection('users').doc(parent.id);
      final snapshot = await parentDoc.get();

      if (!snapshot.exists) {
        await parentDoc.set(parent.toJson());
        if (kDebugMode) {
          print('SeedData: Created test parent: ${parent.nickname}');
        }
      }
    }

    // Update group memberIds
    final groupDoc = _firestore.collection('groups').doc('test-group-001');
    await groupDoc.update({
      'memberIds': testParents.map((p) => p.id).toList(),
    });
  }

  /// Get test group info (for display in UI)
  static Map<String, String> getTestInfo() {
    return {
      'groupCode': testGroupCode,
      'groupName': '테스트 셔틀버스',
      'driverName': '테스트 기사님',
    };
  }
}
