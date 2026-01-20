import 'package:flutter_test/flutter_test.dart';
import 'package:shuttle_tracker/models/attendance_model.dart';

void main() {
  group('AttendanceModel 테스트', () {
    test('기본 생성 테스트', () {
      final attendance = AttendanceModel(
        id: 'att-001',
        groupId: 'group-001',
        studentId: 'student-001',
        studentName: '김학생',
        status: AttendanceStatus.riding,
        date: DateTime(2025, 1, 14),
      );

      expect(attendance.id, 'att-001');
      expect(attendance.groupId, 'group-001');
      expect(attendance.studentId, 'student-001');
      expect(attendance.studentName, '김학생');
      expect(attendance.status, AttendanceStatus.riding);
      expect(attendance.statusDisplayName, '탑승 예정');
    });

    test('상태별 displayName 테스트', () {
      expect(
        AttendanceModel(
          id: '1',
          groupId: 'g1',
          studentId: 's1',
          studentName: 'n1',
          status: AttendanceStatus.riding,
          date: DateTime.now(),
        ).statusDisplayName,
        '탑승 예정',
      );

      expect(
        AttendanceModel(
          id: '2',
          groupId: 'g1',
          studentId: 's1',
          studentName: 'n1',
          status: AttendanceStatus.notRiding,
          date: DateTime.now(),
        ).statusDisplayName,
        '탑승하지 않음',
      );

      expect(
        AttendanceModel(
          id: '3',
          groupId: 'g1',
          studentId: 's1',
          studentName: 'n1',
          status: AttendanceStatus.onBoard,
          date: DateTime.now(),
        ).statusDisplayName,
        '탑승 완료',
      );

      expect(
        AttendanceModel(
          id: '4',
          groupId: 'g1',
          studentId: 's1',
          studentName: 'n1',
          status: AttendanceStatus.dropped,
          date: DateTime.now(),
        ).statusDisplayName,
        '하차 완료',
      );
    });

    test('isRidingToday 테스트', () {
      final ridingAttendance = AttendanceModel(
        id: '1',
        groupId: 'g1',
        studentId: 's1',
        studentName: 'n1',
        status: AttendanceStatus.riding,
        date: DateTime.now(),
      );
      expect(ridingAttendance.isRidingToday, true);

      final onBoardAttendance = AttendanceModel(
        id: '2',
        groupId: 'g1',
        studentId: 's1',
        studentName: 'n1',
        status: AttendanceStatus.onBoard,
        date: DateTime.now(),
      );
      expect(onBoardAttendance.isRidingToday, true);

      final notRidingAttendance = AttendanceModel(
        id: '3',
        groupId: 'g1',
        studentId: 's1',
        studentName: 'n1',
        status: AttendanceStatus.notRiding,
        date: DateTime.now(),
      );
      expect(notRidingAttendance.isRidingToday, false);

      final droppedAttendance = AttendanceModel(
        id: '4',
        groupId: 'g1',
        studentId: 's1',
        studentName: 'n1',
        status: AttendanceStatus.dropped,
        date: DateTime.now(),
      );
      expect(droppedAttendance.isRidingToday, false);
    });

    test('JSON 직렬화/역직렬화 테스트', () {
      final original = AttendanceModel(
        id: 'att-001',
        groupId: 'group-001',
        studentId: 'student-001',
        studentName: '김학생',
        status: AttendanceStatus.notRiding,
        date: DateTime(2025, 1, 14),
        updatedAt: DateTime(2025, 1, 14, 10, 30),
        updatedBy: 'parent-001',
      );

      final json = original.toJson();
      final restored = AttendanceModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.groupId, original.groupId);
      expect(restored.studentId, original.studentId);
      expect(restored.studentName, original.studentName);
      expect(restored.status, original.status);
      expect(restored.updatedBy, original.updatedBy);
    });

    test('copyWith 테스트', () {
      final original = AttendanceModel(
        id: 'att-001',
        groupId: 'group-001',
        studentId: 'student-001',
        studentName: '김학생',
        status: AttendanceStatus.riding,
        date: DateTime(2025, 1, 14),
      );

      final updated = original.copyWith(
        status: AttendanceStatus.notRiding,
        updatedBy: 'parent-001',
        updatedAt: DateTime.now(),
      );

      expect(updated.id, original.id);
      expect(updated.studentName, original.studentName);
      expect(updated.status, AttendanceStatus.notRiding);
      expect(updated.updatedBy, 'parent-001');
    });
  });
}
