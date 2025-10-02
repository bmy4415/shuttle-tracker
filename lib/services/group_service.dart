import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';

/// Group service interface
/// Can be replaced with Firebase Firestore later
abstract class GroupService {
  Future<GroupModel> createGroup(UserModel driver, String groupName);
  Future<GroupModel?> getGroup(String groupId);
  Future<GroupModel?> getGroupByCode(String code);
  Future<void> joinGroup(String code, UserModel user);
  Future<void> leaveGroup(String groupId, String userId);
  Future<void> updateGroup(GroupModel group);
  Future<List<GroupModel>> getAllGroups();
  Future<void> deleteGroup(String groupId);
}

/// Local group service implementation
class LocalGroupService implements GroupService {
  static const String _groupsKey = 'groups';
  final LocalStorageService _storage;

  LocalGroupService(this._storage);

  @override
  Future<GroupModel> createGroup(UserModel driver, String groupName) async {
    const uuid = Uuid();
    final group = GroupModel(
      id: uuid.v4(),
      code: _generateGroupCode(),
      name: groupName,
      driverId: driver.id,
      driverName: driver.nickname,
      memberIds: [driver.id], // Driver is automatically a member
      createdAt: DateTime.now(),
      isActive: false,
    );

    // Save group
    final groups = await getAllGroups();
    groups.add(group);
    await _saveAllGroups(groups);

    return group;
  }

  @override
  Future<GroupModel?> getGroup(String groupId) async {
    final groups = await getAllGroups();
    try {
      return groups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<GroupModel?> getGroupByCode(String code) async {
    final groups = await getAllGroups();
    try {
      return groups.firstWhere(
        (g) => g.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
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
    final updatedGroup = group.copyWith(
      memberIds: [...group.memberIds, user.id],
    );

    await updateGroup(updatedGroup);
  }

  @override
  Future<void> leaveGroup(String groupId, String userId) async {
    final group = await getGroup(groupId);
    if (group == null) {
      throw Exception('그룹을 찾을 수 없습니다.');
    }

    // Remove user from group
    final updatedMemberIds = group.memberIds.where((id) => id != userId).toList();
    final updatedGroup = group.copyWith(memberIds: updatedMemberIds);

    await updateGroup(updatedGroup);
  }

  @override
  Future<void> updateGroup(GroupModel group) async {
    final groups = await getAllGroups();
    final index = groups.indexWhere((g) => g.id == group.id);

    if (index == -1) {
      throw Exception('그룹을 찾을 수 없습니다.');
    }

    groups[index] = group;
    await _saveAllGroups(groups);
  }

  @override
  Future<List<GroupModel>> getAllGroups() async {
    final jsonList = _storage.getJsonList(_groupsKey);
    if (jsonList == null) return [];

    return jsonList.map((json) => GroupModel.fromJson(json)).toList();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final groups = await getAllGroups();
    final updatedGroups = groups.where((g) => g.id != groupId).toList();
    await _saveAllGroups(updatedGroups);
  }

  /// Save all groups to storage
  Future<void> _saveAllGroups(List<GroupModel> groups) async {
    final jsonList = groups.map((g) => g.toJson()).toList();
    await _storage.saveJsonList(_groupsKey, jsonList);
  }

  /// Generate random group code (6 characters)
  /// Format: WORD-NN (예: "LION-3A")
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
    if (_instance == null) {
      final storage = await LocalStorageService.getInstance();
      _instance = LocalGroupService(storage);
    }
    return _instance!;
  }
}