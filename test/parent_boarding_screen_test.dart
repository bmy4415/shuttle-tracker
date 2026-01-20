import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/models/attendance_model.dart';
import 'package:shuttle_tracker/models/user_model.dart';
import 'package:shuttle_tracker/models/group_model.dart';
import 'package:shuttle_tracker/models/location_sharing_schedule_model.dart';
import 'package:shuttle_tracker/screens/parent_boarding_screen.dart';

void main() {
  group('학부모 탑승 설정 화면 테스트', () {
    late UserModel testUser;
    late GroupModel testGroup;

    setUp(() {
      testUser = UserModel(
        id: 'parent-001',
        nickname: '테스트 학부모',
        role: UserRole.parent,
        groupId: 'group-001',
        createdAt: DateTime.now(),
      );

      testGroup = GroupModel(
        id: 'group-001',
        code: 'TEST01',
        name: '테스트 그룹',
        driverId: 'driver-001',
        driverName: '테스트 기사',
        memberIds: ['parent-001'],
        createdAt: DateTime.now(),
        sharingSchedule: LocationSharingScheduleModel.defaultSchedule(),
      );
    });

    testWidgets('화면 타이틀과 기본 요소가 표시됨', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(user: testUser, group: testGroup),
        ),
      );
      await tester.pumpAndSettle();

      // 화면 타이틀
      expect(find.text('탑승 설정'), findsOneWidget);

      // 사용자 이름 표시
      expect(find.text('테스트 학부모'), findsOneWidget);
    });

    testWidgets('탑승 예정 상태에서 "오늘은 탑승하지 않아요" 버튼이 표시됨',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(user: testUser, group: testGroup),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘은 탑승하지 않아요'), findsOneWidget);
    });

    testWidgets('"오늘은 탑승하지 않아요" 버튼 탭 시 확인 다이얼로그 표시',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(user: testUser, group: testGroup),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('오늘은 탑승하지 않아요'));
      await tester.pumpAndSettle();

      // 확인 다이얼로그 표시
      expect(find.text('탑승 취소 확인'), findsOneWidget);
      expect(find.text('오늘 셔틀버스를 이용하지 않으시겠어요?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('확인 다이얼로그에서 취소 버튼 탭 시 다이얼로그 닫힘',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(user: testUser, group: testGroup),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('오늘은 탑승하지 않아요'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // 다이얼로그가 닫힘
      expect(find.text('탑승 취소 확인'), findsNothing);
    });

    testWidgets('탑승하지 않음 상태에서 "탑승 예정으로 변경" 버튼이 표시됨',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(
            user: testUser,
            group: testGroup,
            initialStatus: AttendanceStatus.notRiding,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('탑승 예정으로 변경'), findsOneWidget);
    });

    testWidgets('현재 상태가 적절한 아이콘과 함께 표시됨', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(user: testUser, group: testGroup),
        ),
      );
      await tester.pumpAndSettle();

      // 탑승 예정 상태 아이콘
      expect(find.byIcon(Icons.directions_bus), findsWidgets);
    });

    testWidgets('날짜 정보가 표시됨', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(user: testUser, group: testGroup),
        ),
      );
      await tester.pumpAndSettle();

      // 오늘 날짜가 표시됨
      final today = DateTime.now();
      final dateText = '${today.month}월 ${today.day}일';
      expect(find.textContaining(dateText), findsOneWidget);
    });
  });
}
