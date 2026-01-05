import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/shared_location_model.dart';
import '../models/group_member_model.dart';
import '../models/location_sharing_schedule_model.dart';
import '../models/user_model.dart';

/// Service for real-time location sharing using Firebase Realtime Database
class LocationSharingService {
  static LocationSharingService? _instance;
  final FirebaseDatabase _database;

  LocationSharingService._internal(this._database);

  /// Get singleton instance
  static LocationSharingService getInstance() {
    _instance ??= LocationSharingService._internal(FirebaseDatabase.instance);
    return _instance!;
  }

  /// Reference to locations in the database
  DatabaseReference _locationsRef(String groupId) =>
      _database.ref('locations/$groupId');

  /// Reference to a specific user's location
  DatabaseReference _userLocationRef(String groupId, String odlI) =>
      _database.ref('locations/$groupId/$odlI');

  /// Reference to group settings (schedule)
  DatabaseReference _groupScheduleRef(String groupId) =>
      _database.ref('groups/$groupId/schedule');

  /// Reference to group sharing active state
  DatabaseReference _groupSharingActiveRef(String groupId) =>
      _database.ref('groups/$groupId/isSharingActive');

  /// Reference to presence data
  DatabaseReference _presenceRef(String groupId, String odlI) =>
      _database.ref('presence/$groupId/$odlI');

  // ============== Location Sharing ==============

  /// Start sharing location (set isSharing = true)
  Future<void> startSharing({
    required String groupId,
    required String odlI,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      await _userLocationRef(groupId, odlI).update({
        'isSharing': true,
        'displayName': displayName,
        'role': role.toString(),
        'timestamp': ServerValue.timestamp,
      });

      // Update presence
      await _presenceRef(groupId, odlI).update({
        'isOnline': true,
        'isSharing': true,
        'displayName': displayName,
        'role': role.toString(),
        'lastSeen': ServerValue.timestamp,
      });

      if (kDebugMode) {
        print('LocationSharing: Started sharing for $odlI in group $groupId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error starting sharing: $e');
      }
      rethrow;
    }
  }

  /// Stop sharing location (set isSharing = false)
  Future<void> stopSharing({
    required String groupId,
    required String odlI,
  }) async {
    try {
      await _userLocationRef(groupId, odlI).update({
        'isSharing': false,
        'timestamp': ServerValue.timestamp,
      });

      // Update presence
      await _presenceRef(groupId, odlI).update({
        'isSharing': false,
        'lastSeen': ServerValue.timestamp,
      });

      if (kDebugMode) {
        print('LocationSharing: Stopped sharing for $odlI in group $groupId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error stopping sharing: $e');
      }
      rethrow;
    }
  }

  /// Update user's location in Firebase
  Future<void> updateLocation({
    required String groupId,
    required SharedLocationModel location,
  }) async {
    try {
      await _userLocationRef(groupId, location.userId)
          .set(location.toRealtimeDbJson());

      if (kDebugMode) {
        print('LocationSharing: Updated location for ${location.userId}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error updating location: $e');
      }
      rethrow;
    }
  }

  /// Remove user's location data (when leaving group)
  Future<void> removeLocation({
    required String groupId,
    required String odlI,
  }) async {
    try {
      await _userLocationRef(groupId, odlI).remove();
      await _presenceRef(groupId, odlI).remove();

      if (kDebugMode) {
        print('LocationSharing: Removed location for $odlI');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error removing location: $e');
      }
      rethrow;
    }
  }

  // ============== Location Watching ==============

  /// Watch driver's location (for parents)
  Stream<SharedLocationModel?> watchDriverLocation({
    required String groupId,
    required String driverId,
  }) {
    return _userLocationRef(groupId, driverId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;

      return SharedLocationModel.fromRealtimeDbJson(
        data as Map<dynamic, dynamic>,
        driverId,
        groupId,
      );
    });
  }

  /// Watch all members' locations (for driver)
  Stream<List<SharedLocationModel>> watchAllMemberLocations({
    required String groupId,
  }) {
    return _locationsRef(groupId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <SharedLocationModel>[];

      final locationsMap = data as Map<dynamic, dynamic>;
      return locationsMap.entries.map((entry) {
        return SharedLocationModel.fromRealtimeDbJson(
          entry.value as Map<dynamic, dynamic>,
          entry.key as String,
          groupId,
        );
      }).toList();
    });
  }

  /// Watch members who are currently sharing (for driver)
  Stream<List<SharedLocationModel>> watchSharingMembers({
    required String groupId,
  }) {
    return watchAllMemberLocations(groupId: groupId).map((locations) {
      return locations.where((loc) => loc.isSharing && loc.isRecent).toList();
    });
  }

  // ============== Presence ==============

  /// Watch group members' presence
  Stream<List<GroupMemberModel>> watchGroupMembers({
    required String groupId,
  }) {
    return _database.ref('presence/$groupId').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <GroupMemberModel>[];

      final membersMap = data as Map<dynamic, dynamic>;
      return membersMap.entries.map((entry) {
        return GroupMemberModel.fromRealtimeDbJson(
          entry.value as Map<dynamic, dynamic>,
          entry.key as String,
        );
      }).toList();
    });
  }

  /// Set user online status
  Future<void> setOnlineStatus({
    required String groupId,
    required String odlI,
    required bool isOnline,
  }) async {
    try {
      await _presenceRef(groupId, odlI).update({
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error setting online status: $e');
      }
    }
  }

  /// Setup disconnect handler (automatically set offline when disconnected)
  Future<void> setupDisconnectHandler({
    required String groupId,
    required String odlI,
  }) async {
    try {
      await _presenceRef(groupId, odlI).onDisconnect().update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
      });

      await _userLocationRef(groupId, odlI).onDisconnect().update({
        'isSharing': false,
        'timestamp': ServerValue.timestamp,
      });

      if (kDebugMode) {
        print('LocationSharing: Disconnect handler setup for $odlI');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error setting up disconnect handler: $e');
      }
    }
  }

  // ============== Schedule Management ==============

  /// Get group's sharing schedule
  Future<LocationSharingScheduleModel?> getSchedule({
    required String groupId,
  }) async {
    try {
      final snapshot = await _groupScheduleRef(groupId).get();
      if (!snapshot.exists || snapshot.value == null) return null;

      return LocationSharingScheduleModel.fromRealtimeDbJson(
        snapshot.value as Map<dynamic, dynamic>,
      );
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error getting schedule: $e');
      }
      return null;
    }
  }

  /// Update group's sharing schedule (driver only)
  Future<void> updateSchedule({
    required String groupId,
    required LocationSharingScheduleModel schedule,
  }) async {
    try {
      await _groupScheduleRef(groupId).set(schedule.toRealtimeDbJson());

      if (kDebugMode) {
        print('LocationSharing: Updated schedule for group $groupId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error updating schedule: $e');
      }
      rethrow;
    }
  }

  /// Watch group's sharing schedule
  Stream<LocationSharingScheduleModel?> watchSchedule({
    required String groupId,
  }) {
    return _groupScheduleRef(groupId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;

      return LocationSharingScheduleModel.fromRealtimeDbJson(
        data as Map<dynamic, dynamic>,
      );
    });
  }

  /// Get group's sharing active state
  Future<bool> isSharingActive({required String groupId}) async {
    try {
      final snapshot = await _groupSharingActiveRef(groupId).get();
      return snapshot.value as bool? ?? true;
    } catch (e) {
      return true;
    }
  }

  /// Toggle group's sharing active state (driver only)
  Future<void> setSharingActive({
    required String groupId,
    required bool isActive,
  }) async {
    try {
      await _groupSharingActiveRef(groupId).set(isActive);

      if (kDebugMode) {
        print('LocationSharing: Set sharing active = $isActive for $groupId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error setting sharing active: $e');
      }
      rethrow;
    }
  }

  /// Watch group's sharing active state
  Stream<bool> watchSharingActive({required String groupId}) {
    return _groupSharingActiveRef(groupId).onValue.map((event) {
      return event.snapshot.value as bool? ?? true;
    });
  }

  // ============== Cleanup ==============

  /// Clean up old location data (older than 24 hours)
  Future<void> cleanupOldLocations({required String groupId}) async {
    try {
      final snapshot = await _locationsRef(groupId).get();
      if (!snapshot.exists || snapshot.value == null) return;

      final locationsMap = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;
      final oneDayAgo = now - (24 * 60 * 60 * 1000);

      for (final entry in locationsMap.entries) {
        final locationData = entry.value as Map<dynamic, dynamic>;
        final timestamp = locationData['timestamp'] as int? ?? 0;

        if (timestamp < oneDayAgo) {
          await _userLocationRef(groupId, entry.key as String).remove();
          if (kDebugMode) {
            print('LocationSharing: Cleaned up old location for ${entry.key}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('LocationSharing: Error cleaning up: $e');
      }
    }
  }
}
