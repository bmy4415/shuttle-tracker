import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/location_sharing_schedule_model.dart';

/// Group service interface
abstract class GroupService {
  Future<GroupModel> createGroup(
    UserModel driver,
    String groupName, {
    required LocationSharingScheduleModel schedule,
  });
  Future<GroupModel?> getGroup(String groupId);
  Future<GroupModel?> getGroupByCode(String code);
  Future<void> joinGroup(String code, UserModel user);
  Future<void> leaveGroup(String groupId, String userId);
  Future<void> updateGroup(GroupModel group);
  Future<List<GroupModel>> getAllGroups();
  Future<List<GroupModel>> getGroupsByDriver(String driverId);
  Future<List<GroupModel>> getGroupsByMember(String userId);
  Future<void> deleteGroup(String groupId);
}

/// Firestore group service implementation
class FirestoreGroupService implements GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<GroupModel> createGroup(
    UserModel driver,
    String groupName, {
    required LocationSharingScheduleModel schedule,
  }) async {
    final groupDoc = _firestore.collection('groups').doc();
    final group = GroupModel(
      id: groupDoc.id,
      code: _generateGroupCode(),
      name: groupName,
      driverId: driver.id,
      driverName: driver.nickname,
      memberIds: [driver.id], // Driver is automatically a member
      createdAt: DateTime.now(),
      isActive: false,
      sharingSchedule: schedule,
    );

    await groupDoc.set(group.toJson());
    print('Created group: ${group.id} (${group.code})');
    return group;
  }

  @override
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  @override
  Future<GroupModel?> getGroupByCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return GroupModel.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      print('Error getting group by code: $e');
      return null;
    }
  }

  @override
  Future<void> joinGroup(String code, UserModel user) async {
    final group = await getGroupByCode(code);
    if (group == null) {
      throw Exception('그룹을 찾을 수 없습니다.');
    }

    // Check if user is already a member
    if (group.memberIds.contains(user.id)) {
      throw Exception('이미 이 그룹에 참여하고 있습니다.');
    }

    // Add user to group
    await _firestore.collection('groups').doc(group.id).update({
      'memberIds': FieldValue.arrayUnion([user.id]),
    });

    print('User ${user.id} joined group ${group.id}');
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    print('User $userId left group $groupId');
  }

  @override
  Future<void> updateGroup(GroupModel group) async {
    await _firestore.collection('groups').doc(group.id).update(group.toJson());
    print('Updated group: ${group.id}');
  }

  @override
  Future<List<GroupModel>> getAllGroups() async {
    try {
      final querySnapshot = await _firestore.collection('groups').get();
      return querySnapshot.docs
          .map((doc) => GroupModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting all groups: $e');
      return [];
    }
  }

  @override
  Future<List<GroupModel>> getGroupsByDriver(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => GroupModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting groups by driver: $e');
      return [];
    }
  }

  @override
  Future<List<GroupModel>> getGroupsByMember(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => GroupModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting groups by member: $e');
      return [];
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
    print('Deleted group: $groupId');
  }

  /// Generate random group code (6 characters)
  /// Format: WORDNC (예: "LION3A")
  String _generateGroupCode() {
    final words = [
      'LION', 'BEAR', 'WOLF', 'DEER', 'HAWK',
      'STAR', 'MOON', 'SUN', 'CLOUD', 'RAIN',
    ];

    final random = Random();
    final word = words[random.nextInt(words.length)];
    final num1 = random.nextInt(10);
    final char = String.fromCharCode(65 + random.nextInt(26)); // A-Z

    return '$word$num1$char';
  }
}

/// Factory to get group service instance
class GroupServiceFactory {
  static GroupService? _instance;

  static Future<GroupService> getInstance() async {
    _instance ??= FirestoreGroupService();
    return _instance!;
  }
}
