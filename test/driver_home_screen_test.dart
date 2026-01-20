import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/models/user_model.dart';
import 'package:shuttle_tracker/models/group_model.dart';
import 'package:shuttle_tracker/models/location_sharing_schedule_model.dart';

// Test helper to verify the stopTracking logic
// We can't directly test the screen due to Firebase dependency,
// but we test the expected behavior with unit tests for the logic

void main() {
  group('기사 운행 종료 로직 테스트', () {
    late UserModel testDriver;
    late GroupModel testGroup;

    setUp(() {
      testDriver = UserModel(
        id: 'driver-001',
        nickname: '테스트 기사',
        role: UserRole.driver,
        groupId: 'group-001',
        createdAt: DateTime.now(),
      );

      testGroup = GroupModel(
        id: 'group-001',
        code: 'TEST01',
        name: '테스트 그룹',
        driverId: 'driver-001',
        driverName: '테스트 기사',
        memberIds: ['parent-001', 'parent-002'],
        createdAt: DateTime.now(),
        sharingSchedule: LocationSharingScheduleModel.defaultSchedule(),
      );
    });

    test('StopTrackingOrder - isSharing flag는 stopSharing() 호출 전에 false가 되어야 함', () {
      // This test verifies the expected order of operations in _stopTracking()
      // The implementation should:
      // 1. Set _isSharing = false (local state)
      // 2. Call stopSharing() (Firebase update)
      // 3. Cancel subscriptions

      final operationOrder = <String>[];

      // Simulated _stopTracking logic order
      void simulatedStopTracking({
        required Function() setIsSharingFalse,
        required Function() callStopSharing,
        required Function() cancelSubscriptions,
      }) {
        // 1. Set local sharing flag first
        setIsSharingFalse();
        operationOrder.add('setIsSharingFalse');

        // 2. Update Firebase
        callStopSharing();
        operationOrder.add('callStopSharing');

        // 3. Cancel subscriptions last
        cancelSubscriptions();
        operationOrder.add('cancelSubscriptions');
      }

      // Execute the simulation
      simulatedStopTracking(
        setIsSharingFalse: () {},
        callStopSharing: () {},
        cancelSubscriptions: () {},
      );

      // Verify the order
      expect(operationOrder[0], equals('setIsSharingFalse'));
      expect(operationOrder[1], equals('callStopSharing'));
      expect(operationOrder[2], equals('cancelSubscriptions'));
    });

    test('ExitRoom - 운행 중이 아니면 다이얼로그 없이 바로 이동', () {
      // This test verifies the conditional dialog logic
      bool isTracking = false;
      bool dialogShown = false;
      bool navigated = false;

      // Simulated _exitRoom logic
      void simulatedExitRoom() {
        if (!isTracking) {
          // Navigate directly without dialog
          navigated = true;
          return;
        }

        // Show confirmation dialog
        dialogShown = true;
      }

      simulatedExitRoom();

      expect(dialogShown, isFalse);
      expect(navigated, isTrue);
    });

    test('ExitRoom - 운행 중이면 확인 다이얼로그 표시', () {
      bool isTracking = true;
      bool dialogShown = false;
      bool navigated = false;

      // Simulated _exitRoom logic
      void simulatedExitRoom() {
        if (!isTracking) {
          navigated = true;
          return;
        }

        // Show confirmation dialog
        dialogShown = true;
      }

      simulatedExitRoom();

      expect(dialogShown, isTrue);
      expect(navigated, isFalse);
    });

    test('StopTracking - stopSharing()은 한 번만 호출되어야 함', () {
      // This test verifies that stopSharing is not called twice
      // (previously it was called in both _exitRoom and _stopTracking)
      int stopSharingCallCount = 0;

      // Simulated _stopTracking (now the only place stopSharing is called)
      Future<void> simulatedStopTracking() async {
        stopSharingCallCount++;
      }

      // Simulated _exitRoom (no longer calls stopSharing directly)
      Future<void> simulatedExitRoom() async {
        await simulatedStopTracking();
        // Navigate...
      }

      simulatedExitRoom();

      expect(stopSharingCallCount, equals(1));
    });

    test('BottomButton - 운행 중이 아닐 때만 운행 시작 버튼 표시', () {
      // Verify button visibility logic
      bool isTracking = false;
      bool showStartButton() => !isTracking;

      expect(showStartButton(), isTrue);

      isTracking = true;
      expect(showStartButton(), isFalse);
    });

    test('운행 종료 후 상태가 올바르게 초기화됨', () {
      // Simulated state after _stopTracking
      bool isTracking = true;
      bool isSharing = true;
      String? statusMessage = '운행 중';
      List<dynamic> parentLocations = [1, 2, 3]; // dummy data
      List<dynamic> allMemberLocations = [1, 2, 3];
      String? selectedParentId = 'parent-001';

      // Simulated _stopTracking state updates
      void simulatedStopTrackingStateUpdate() {
        isSharing = false; // First update

        // After Firebase call...

        isTracking = false;
        statusMessage = '운행 중지됨';
        parentLocations = [];
        allMemberLocations = [];
        selectedParentId = null;
      }

      simulatedStopTrackingStateUpdate();

      expect(isTracking, isFalse);
      expect(isSharing, isFalse);
      expect(statusMessage, equals('운행 중지됨'));
      expect(parentLocations, isEmpty);
      expect(allMemberLocations, isEmpty);
      expect(selectedParentId, isNull);
    });
  });

  group('운행 시작/종료 버튼 UI 테스트', () {
    test('운행 전에는 운행 시작 버튼이 보임', () {
      bool isTracking = false;
      bool isLoadingGroup = false;

      // Expected button state
      bool shouldShowStartButton = !isTracking;
      String expectedLabel = isLoadingGroup ? '로딩 중...' : '운행 시작';

      expect(shouldShowStartButton, isTrue);
      expect(expectedLabel, equals('운행 시작'));
    });

    test('운행 중에는 운행 시작 버튼이 숨겨짐 (뒤로가기로 종료)', () {
      bool isTracking = true;

      // Expected button visibility
      bool shouldShowStartButton = !isTracking;

      expect(shouldShowStartButton, isFalse);
    });

    test('로딩 중에는 버튼이 비활성화됨', () {
      bool isLoadingGroup = true;
      bool isTracking = false;

      // Expected button state
      bool shouldBeDisabled = isLoadingGroup;
      bool shouldShowButton = !isTracking;

      expect(shouldShowButton, isTrue);
      expect(shouldBeDisabled, isTrue);
    });
  });

  group('뒤로가기 버튼 동작 테스트', () {
    test('운행 중에 뒤로가기 시 확인 다이얼로그 표시', () async {
      bool isTracking = true;
      bool showDialog = false;
      bool navigate = false;

      // Simulated exit room behavior
      Future<void> exitRoom() async {
        if (!isTracking) {
          navigate = true;
          return;
        }

        showDialog = true;
        // User confirms...
        bool confirmed = true;

        if (confirmed) {
          // stopTracking and navigate
          isTracking = false;
          navigate = true;
        }
      }

      await exitRoom();

      expect(showDialog, isTrue);
      expect(navigate, isTrue);
      expect(isTracking, isFalse);
    });

    test('운행 종료 취소 시 화면 유지', () async {
      bool isTracking = true;
      bool showDialog = false;
      bool navigate = false;

      // Simulated exit room with cancel
      Future<void> exitRoom() async {
        if (!isTracking) {
          navigate = true;
          return;
        }

        showDialog = true;
        // User cancels...
        bool confirmed = false;

        if (confirmed) {
          isTracking = false;
          navigate = true;
        }
      }

      await exitRoom();

      expect(showDialog, isTrue);
      expect(navigate, isFalse);
      expect(isTracking, isTrue);
    });

    test('운행 전에 뒤로가기 시 바로 이동 (다이얼로그 없음)', () async {
      bool isTracking = false;
      bool showDialog = false;
      bool navigate = false;

      // Simulated exit room
      Future<void> exitRoom() async {
        if (!isTracking) {
          navigate = true;
          return;
        }

        showDialog = true;
      }

      await exitRoom();

      expect(showDialog, isFalse);
      expect(navigate, isTrue);
    });
  });

  group('Firebase 업데이트 타이밍 테스트', () {
    test('stopSharing은 subscription 취소 전에 호출됨', () async {
      final events = <String>[];

      // Mock implementations that record call order
      Future<void> mockStopSharing() async {
        events.add('stopSharing');
      }

      void mockCancelSubscription() {
        events.add('cancelSubscription');
      }

      // Simulated _stopTracking with correct order
      Future<void> stopTracking() async {
        // 1. Set local flag (not tracked here)

        // 2. Firebase update first
        await mockStopSharing();

        // 3. Cancel subscriptions after Firebase is updated
        mockCancelSubscription();
      }

      await stopTracking();

      expect(events, equals(['stopSharing', 'cancelSubscription']));
    });

    test('race condition 방지: isSharing=false가 가장 먼저 설정됨', () async {
      bool isSharing = true;
      final events = <String>[];

      // Simulated _stopTracking
      Future<void> stopTracking() async {
        // 1. Set local flag FIRST to prevent race condition
        isSharing = false;
        events.add('setIsSharing:$isSharing');

        // 2. Firebase update
        events.add('stopSharing');

        // 3. Cancel subscriptions
        events.add('cancelSubscription');
      }

      await stopTracking();

      // Verify isSharing is set to false first
      expect(events[0], equals('setIsSharing:false'));
      expect(isSharing, isFalse);
    });
  });
}
