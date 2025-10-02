import 'package:uuid/uuid.dart';
import '../models/attendance_model.dart';
import 'local_storage_service.dart';

/// Attendance service interface
/// Can be replaced with Firebase Firestore later
abstract class AttendanceService {
  Future<AttendanceModel> createAttendance({
    required String groupId,
    required String studentId,
    required String studentName,
    required DateTime date,
  });

  Future<AttendanceModel?> getAttendance(String attendanceId);

  Future<List<AttendanceModel>> getAttendanceByGroup(
    String groupId,
    DateTime date,
  );

  Future<AttendanceModel?> getAttendanceByStudent(
    String groupId,
    String studentId,
    DateTime date,
  );

  Future<void> updateAttendanceStatus({
    required String attendanceId,
    required AttendanceStatus status,
    required String updatedBy,
  });

  Future<void> deleteAttendance(String attendanceId);

  Future<List<AttendanceModel>> getAllAttendances();
}

/// Local attendance service implementation
class LocalAttendanceService implements AttendanceService {
  static const String _attendancesKey = 'attendances';
  final LocalStorageService _storage;

  LocalAttendanceService(this._storage);

  @override
  Future<AttendanceModel> createAttendance({
    required String groupId,
    required String studentId,
    required String studentName,
    required DateTime date,
  }) async {
    const uuid = Uuid();

    // Normalize date to start of day
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final attendance = AttendanceModel(
      id: uuid.v4(),
      groupId: groupId,
      studentId: studentId,
      studentName: studentName,
      status: AttendanceStatus.riding, // Default: 탑승 예정
      date: normalizedDate,
      updatedAt: DateTime.now(),
    );

    // Save attendance
    final attendances = await getAllAttendances();
    attendances.add(attendance);
    await _saveAllAttendances(attendances);

    return attendance;
  }

  @override
  Future<AttendanceModel?> getAttendance(String attendanceId) async {
    final attendances = await getAllAttendances();
    try {
      return attendances.firstWhere((a) => a.id == attendanceId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<AttendanceModel>> getAttendanceByGroup(
    String groupId,
    DateTime date,
  ) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final attendances = await getAllAttendances();

    return attendances.where((a) {
      final attendanceDate = DateTime(
        a.date.year,
        a.date.month,
        a.date.day,
      );
      return a.groupId == groupId && attendanceDate == normalizedDate;
    }).toList();
  }

  @override
  Future<AttendanceModel?> getAttendanceByStudent(
    String groupId,
    String studentId,
    DateTime date,
  ) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final attendances = await getAllAttendances();

    try {
      return attendances.firstWhere((a) {
        final attendanceDate = DateTime(
          a.date.year,
          a.date.month,
          a.date.day,
        );
        return a.groupId == groupId &&
               a.studentId == studentId &&
               attendanceDate == normalizedDate;
      });
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateAttendanceStatus({
    required String attendanceId,
    required AttendanceStatus status,
    required String updatedBy,
  }) async {
    final attendances = await getAllAttendances();
    final index = attendances.indexWhere((a) => a.id == attendanceId);

    if (index == -1) {
      throw Exception('출석 정보를 찾을 수 없습니다.');
    }

    final updatedAttendance = attendances[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
      updatedBy: updatedBy,
    );

    attendances[index] = updatedAttendance;
    await _saveAllAttendances(attendances);
  }

  @override
  Future<void> deleteAttendance(String attendanceId) async {
    final attendances = await getAllAttendances();
    final updatedAttendances = attendances.where((a) => a.id != attendanceId).toList();
    await _saveAllAttendances(updatedAttendances);
  }

  @override
  Future<List<AttendanceModel>> getAllAttendances() async {
    final jsonList = _storage.getJsonList(_attendancesKey);
    if (jsonList == null) return [];

    return jsonList.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  /// Save all attendances to storage
  Future<void> _saveAllAttendances(List<AttendanceModel> attendances) async {
    final jsonList = attendances.map((a) => a.toJson()).toList();
    await _storage.saveJsonList(_attendancesKey, jsonList);
  }
}

/// Factory to get attendance service instance
class AttendanceServiceFactory {
  static AttendanceService? _instance;

  static Future<AttendanceService> getInstance() async {
    if (_instance == null) {
      final storage = await LocalStorageService.getInstance();
      _instance = LocalAttendanceService(storage);
    }
    return _instance!;
  }
}