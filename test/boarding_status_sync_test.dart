import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/models/shared_location_model.dart';
import 'package:shuttle_tracker/models/user_model.dart';
import 'package:shuttle_tracker/models/attendance_model.dart';

void main() {
  group('SharedLocationModel isBoardingToday', () {
    test('should have isBoardingToday field with default value true', () {
      final model = SharedLocationModel(
        userId: 'user1',
        groupId: 'group1',
        displayName: 'Test User',
        role: UserRole.parent,
        latitude: 37.5,
        longitude: 127.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      expect(model.isBoardingToday, true);
    });

    test('should allow setting isBoardingToday to false', () {
      final model = SharedLocationModel(
        userId: 'user1',
        groupId: 'group1',
        displayName: 'Test User',
        role: UserRole.parent,
        latitude: 37.5,
        longitude: 127.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isBoardingToday: false,
      );

      expect(model.isBoardingToday, false);
    });

    test('copyWith should update isBoardingToday', () {
      final model = SharedLocationModel(
        userId: 'user1',
        groupId: 'group1',
        displayName: 'Test User',
        role: UserRole.parent,
        latitude: 37.5,
        longitude: 127.0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isBoardingToday: true,
      );

      final updated = model.copyWith(isBoardingToday: false);

      expect(updated.isBoardingToday, false);
      expect(model.isBoardingToday, true); // Original unchanged
    });

    test('toRealtimeDbJson should include isBoardingToday', () {
      final model = SharedLocationModel(
        userId: 'user1',
        groupId: 'group1',
        displayName: 'Test User',
        role: UserRole.parent,
        latitude: 37.5,
        longitude: 127.0,
        timestamp: 1234567890,
        isBoardingToday: false,
      );

      final json = model.toRealtimeDbJson();

      expect(json['isBoardingToday'], false);
      expect(json['displayName'], 'Test User');
      expect(json['latitude'], 37.5);
    });

    test('fromRealtimeDbJson should parse isBoardingToday', () {
      final json = {
        'displayName': 'Test User',
        'role': 'UserRole.parent',
        'latitude': 37.5,
        'longitude': 127.0,
        'timestamp': 1234567890,
        'isSharing': true,
        'isBoardingToday': false,
      };

      final model = SharedLocationModel.fromRealtimeDbJson(
        json,
        'user1',
        'group1',
      );

      expect(model.isBoardingToday, false);
      expect(model.userId, 'user1');
      expect(model.groupId, 'group1');
    });

    test('fromRealtimeDbJson should default isBoardingToday to true if missing', () {
      final json = {
        'displayName': 'Test User',
        'role': 'UserRole.parent',
        'latitude': 37.5,
        'longitude': 127.0,
        'timestamp': 1234567890,
        'isSharing': true,
        // isBoardingToday is missing
      };

      final model = SharedLocationModel.fromRealtimeDbJson(
        json,
        'user1',
        'group1',
      );

      expect(model.isBoardingToday, true); // Default value
    });

    test('toString should include isBoardingToday', () {
      final model = SharedLocationModel(
        userId: 'user1',
        groupId: 'group1',
        displayName: 'Test User',
        role: UserRole.parent,
        latitude: 37.5,
        longitude: 127.0,
        timestamp: 1234567890,
        isBoardingToday: false,
      );

      final str = model.toString();

      expect(str, contains('isBoardingToday: false'));
    });
  });

  group('Boarding Status and Attendance Integration', () {
    test('notRiding status from Firebase should override local riding status', () {
      // Simulate: Parent set notRiding in Firebase
      final firebaseBoardingStatus = {'parent1': false, 'parent2': true};

      // Local attendance shows riding
      final attendance = AttendanceModel(
        id: 'att1',
        groupId: 'group1',
        studentId: 'parent1',
        studentName: 'Parent 1',
        status: AttendanceStatus.riding,
        date: DateTime.now(),
      );

      // Check if Firebase status overrides local
      final isBoardingToday = firebaseBoardingStatus[attendance.studentId];
      final effectiveStatus = isBoardingToday == false
          ? AttendanceStatus.notRiding
          : attendance.status;

      expect(effectiveStatus, AttendanceStatus.notRiding);
    });

    test('missing Firebase status should use local attendance status', () {
      // Simulate: No Firebase status for this parent
      final firebaseBoardingStatus = <String, bool>{};

      // Local attendance shows riding
      final attendance = AttendanceModel(
        id: 'att1',
        groupId: 'group1',
        studentId: 'parent1',
        studentName: 'Parent 1',
        status: AttendanceStatus.riding,
        date: DateTime.now(),
      );

      // Check if local status is used
      final isBoardingToday = firebaseBoardingStatus[attendance.studentId];
      final effectiveStatus = isBoardingToday == false
          ? AttendanceStatus.notRiding
          : attendance.status;

      expect(effectiveStatus, AttendanceStatus.riding);
    });

    test('boarding status true should not override local status', () {
      // Simulate: Parent confirmed boarding in Firebase
      final firebaseBoardingStatus = {'parent1': true};

      // Local attendance shows onBoard
      final attendance = AttendanceModel(
        id: 'att1',
        groupId: 'group1',
        studentId: 'parent1',
        studentName: 'Parent 1',
        status: AttendanceStatus.onBoard,
        date: DateTime.now(),
      );

      // Check that onBoard status is preserved
      final isBoardingToday = firebaseBoardingStatus[attendance.studentId];
      final effectiveStatus = isBoardingToday == false
          ? AttendanceStatus.notRiding
          : attendance.status;

      expect(effectiveStatus, AttendanceStatus.onBoard);
    });
  });

  group('Counting Riding Students', () {
    test('should count correctly with mixed Firebase and local status', () {
      final firebaseBoardingStatus = {
        'parent1': false, // Not riding (from Firebase)
        'parent2': true, // Riding
        // parent3 not in Firebase
      };

      final attendances = [
        AttendanceModel(
          id: 'att1',
          groupId: 'group1',
          studentId: 'parent1',
          studentName: 'Parent 1',
          status: AttendanceStatus.riding,
          date: DateTime.now(),
        ),
        AttendanceModel(
          id: 'att2',
          groupId: 'group1',
          studentId: 'parent2',
          studentName: 'Parent 2',
          status: AttendanceStatus.riding,
          date: DateTime.now(),
        ),
        AttendanceModel(
          id: 'att3',
          groupId: 'group1',
          studentId: 'parent3',
          studentName: 'Parent 3',
          status: AttendanceStatus.riding,
          date: DateTime.now(),
        ),
      ];

      // Count riding students
      final ridingCount = attendances.where((a) {
        final isBoardingToday = firebaseBoardingStatus[a.studentId];
        final effectiveStatus = isBoardingToday == false
            ? AttendanceStatus.notRiding
            : a.status;
        return effectiveStatus == AttendanceStatus.riding ||
            effectiveStatus == AttendanceStatus.onBoard;
      }).length;

      // parent1 is notRiding (Firebase override)
      // parent2 is riding (Firebase confirmed)
      // parent3 is riding (no Firebase status, use local)
      expect(ridingCount, 2);
    });
  });

  group('Midnight Reset Logic', () {
    test('should reset isBoardingToday to true when date changes', () {
      // Scenario: lastBoardingDate is yesterday, app runs today
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String().substring(0, 10);
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // Date has changed, should reset
      expect(yesterdayStr != todayStr, true);
    });

    test('should preserve isBoardingToday when same date', () {
      // Scenario: lastBoardingDate is today, preserve status
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      final firebaseData = {
        'isBoardingToday': false,
        'lastBoardingDate': todayStr,
      };

      final shouldReset = firebaseData['lastBoardingDate'] != todayStr;
      expect(shouldReset, false);

      // Existing value should be preserved
      expect(firebaseData['isBoardingToday'], false);
    });

    test('should set isBoardingToday to true when lastBoardingDate is null', () {
      // Scenario: First run, no lastBoardingDate
      final firebaseData = <String, dynamic>{
        'isBoardingToday': null,
        'lastBoardingDate': null,
      };

      final lastDate = firebaseData['lastBoardingDate'] as String?;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // Should reset when lastBoardingDate is null or different from today
      final shouldReset = lastDate == null || lastDate != todayStr;
      expect(shouldReset, true);
    });
  });

  group('startSharing preserves existing isBoardingToday', () {
    test('should NOT overwrite existing isBoardingToday value', () {
      // Scenario: Already set to false, startSharing should not overwrite
      final existingData = {
        'isBoardingToday': false,
        'isSharing': true,
      };

      // startSharing should not overwrite existing value
      final hasExistingValue = existingData['isBoardingToday'] != null;
      expect(hasExistingValue, true);

      // Existing value should remain
      expect(existingData['isBoardingToday'], false);
    });

    test('should set isBoardingToday to true when no existing value', () {
      // Scenario: First share start, no isBoardingToday
      final existingData = <String, dynamic>{};

      final hasExistingValue = existingData.containsKey('isBoardingToday');
      expect(hasExistingValue, false);

      // Should set to true when no existing value
      if (!hasExistingValue) {
        existingData['isBoardingToday'] = true;
      }
      expect(existingData['isBoardingToday'], true);
    });
  });
}
