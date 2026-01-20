import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/models/user_model.dart';
import 'package:shuttle_tracker/models/group_model.dart';
import 'package:shuttle_tracker/models/location_sharing_schedule_model.dart';
import 'package:shuttle_tracker/screens/parent_boarding_screen.dart';
import 'package:shuttle_tracker/screens/driver_student_list_screen.dart';
import 'package:shuttle_tracker/models/attendance_model.dart';

void main() {
  group('새 화면 네비게이션 테스트', () {
    late UserModel testParent;
    late UserModel testDriver;
    late GroupModel testGroup;

    setUp(() {
      testParent = UserModel(
        id: 'parent-001',
        nickname: '테스트 학부모',
        role: UserRole.parent,
        groupId: 'group-001',
        createdAt: DateTime.now(),
      );

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
        memberIds: ['parent-001', 'driver-001'],
        createdAt: DateTime.now(),
        sharingSchedule: LocationSharingScheduleModel.defaultSchedule(),
      );
    });

    testWidgets('ParentBoardingScreen이 정상적으로 렌더링됨', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(user: testParent, group: testGroup),
        ),
      );
      await tester.pumpAndSettle();

      // 화면이 정상적으로 렌더링되는지 확인
      expect(find.text('탑승 설정'), findsOneWidget);
      expect(find.text('테스트 학부모'), findsOneWidget);
    });

    testWidgets('DriverStudentListScreen이 정상적으로 렌더링됨', (WidgetTester tester) async {
      final testAttendances = [
        AttendanceModel(
          id: 'att-001',
          groupId: 'group-001',
          studentId: 'parent-001',
          studentName: '김학생',
          status: AttendanceStatus.riding,
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: DriverStudentListScreen(
            driver: testDriver,
            group: testGroup,
            attendances: testAttendances,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 화면이 정상적으로 렌더링되는지 확인
      expect(find.text('학생 목록'), findsOneWidget);
      expect(find.text('김학생'), findsOneWidget);
    });

    testWidgets('ParentBoardingScreen에서 탑승 상태 토글 가능', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ParentBoardingScreen(user: testParent, group: testGroup),
        ),
      );
      await tester.pumpAndSettle();

      // 초기 상태: 탑승 예정
      expect(find.text('오늘은 탑승하지 않아요'), findsOneWidget);

      // 버튼 클릭
      await tester.tap(find.text('오늘은 탑승하지 않아요'));
      await tester.pumpAndSettle();

      // 확인 다이얼로그가 표시됨
      expect(find.text('탑승 취소 확인'), findsOneWidget);
    });

    testWidgets('DriverStudentListScreen에서 탑승 버튼이 표시됨', (WidgetTester tester) async {
      final testAttendances = [
        AttendanceModel(
          id: 'att-001',
          groupId: 'group-001',
          studentId: 'parent-001',
          studentName: '김학생',
          status: AttendanceStatus.riding,
          date: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: DriverStudentListScreen(
            driver: testDriver,
            group: testGroup,
            attendances: testAttendances,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // riding 상태의 학생에게 탑승 버튼이 있어야 함
      expect(find.text('탑승'), findsOneWidget);
    });

    testWidgets('DriverStudentListScreen 빈 목록 처리', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DriverStudentListScreen(
            driver: testDriver,
            group: testGroup,
            attendances: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 빈 목록 메시지
      expect(find.text('등록된 학생이 없습니다'), findsOneWidget);
    });
  });
}
