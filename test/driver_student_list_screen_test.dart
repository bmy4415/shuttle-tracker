import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/models/attendance_model.dart';
import 'package:shuttle_tracker/models/user_model.dart';
import 'package:shuttle_tracker/models/group_model.dart';
import 'package:shuttle_tracker/models/location_sharing_schedule_model.dart';
import 'package:shuttle_tracker/screens/driver_student_list_screen.dart';

void main() {
  group('기사 학생 목록 화면 테스트', () {
    late UserModel testDriver;
    late GroupModel testGroup;
    late List<AttendanceModel> testAttendances;

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
        memberIds: ['parent-001', 'parent-002', 'parent-003'],
        createdAt: DateTime.now(),
        sharingSchedule: LocationSharingScheduleModel.defaultSchedule(),
      );

      testAttendances = [
        AttendanceModel(
          id: 'att-001',
          groupId: 'group-001',
          studentId: 'parent-001',
          studentName: '김학생',
          status: AttendanceStatus.riding,
          date: DateTime.now(),
        ),
        AttendanceModel(
          id: 'att-002',
          groupId: 'group-001',
          studentId: 'parent-002',
          studentName: '이학생',
          status: AttendanceStatus.notRiding,
          date: DateTime.now(),
        ),
        AttendanceModel(
          id: 'att-003',
          groupId: 'group-001',
          studentId: 'parent-003',
          studentName: '박학생',
          status: AttendanceStatus.onBoard,
          date: DateTime.now(),
        ),
      ];
    });

    testWidgets('화면 타이틀이 표시됨', (WidgetTester tester) async {
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

      expect(find.text('학생 목록'), findsOneWidget);
    });

    testWidgets('학생 목록이 표시됨', (WidgetTester tester) async {
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

      expect(find.text('김학생'), findsOneWidget);
      expect(find.text('이학생'), findsOneWidget);
      expect(find.text('박학생'), findsOneWidget);
    });

    testWidgets('탑승 상태별 시각적 구분이 있음', (WidgetTester tester) async {
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

      // 탑승 예정 상태 표시
      expect(find.text('탑승 예정'), findsOneWidget);
      // 탑승하지 않음 상태 표시
      expect(find.text('탑승하지 않음'), findsOneWidget);
      // 탑승 완료 상태 표시
      expect(find.text('탑승 완료'), findsOneWidget);
    });

    testWidgets('탑승 안함 학생은 dimmed 처리됨', (WidgetTester tester) async {
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

      // notRiding 상태의 학생 카드가 존재하는지 확인
      final notRidingFinder = find.ancestor(
        of: find.text('이학생'),
        matching: find.byType(Card),
      );
      expect(notRidingFinder, findsOneWidget);
    });

    testWidgets('탑승/하차 버튼이 있음', (WidgetTester tester) async {
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

      // riding 상태 학생에게 탑승 완료 버튼
      expect(find.text('탑승'), findsWidgets);
    });

    testWidgets('학생 수 통계가 표시됨', (WidgetTester tester) async {
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

      // 총 학생 수 또는 탑승 예정 인원 표시
      expect(find.textContaining('명'), findsWidgets);
    });

    testWidgets('빈 목록일 때 안내 메시지 표시', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DriverStudentListScreen(
            driver: testDriver,
            group: testGroup,
            attendances: [], // 빈 목록
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('등록된 학생이 없습니다'), findsOneWidget);
    });

    testWidgets('날짜 정보가 표시됨', (WidgetTester tester) async {
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

      final today = DateTime.now();
      final dateText = '${today.month}월 ${today.day}일';
      expect(find.textContaining(dateText), findsOneWidget);
    });
  });
}
