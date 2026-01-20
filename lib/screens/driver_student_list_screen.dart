import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/attendance_service.dart';
import '../services/location_sharing_service.dart';

/// Driver student list screen - Shows student attendance list
class DriverStudentListScreen extends StatefulWidget {
  final UserModel driver;
  final GroupModel group;
  final List<AttendanceModel> attendances;
  // Optional: for testing without Firebase
  final LocationSharingService? sharingService;

  const DriverStudentListScreen({
    super.key,
    required this.driver,
    required this.group,
    required this.attendances,
    this.sharingService,
  });

  @override
  State<DriverStudentListScreen> createState() =>
      _DriverStudentListScreenState();
}

class _DriverStudentListScreenState extends State<DriverStudentListScreen> {
  late List<AttendanceModel> _attendances;
  final Set<String> _loadingAttendanceIds = {};
  AttendanceService? _attendanceService;

  // Firebase real-time boarding status
  LocationSharingService? _sharingService;
  StreamSubscription<Map<String, bool>>? _boardingStatusSubscription;
  Map<String, bool> _realtimeBoardingStatus = {};

  @override
  void initState() {
    super.initState();
    _attendances = widget.attendances;
    _initializeServices();
    _initializeSharingService();
  }

  @override
  void dispose() {
    _boardingStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _attendanceService = await AttendanceServiceFactory.getInstance();
  }

  /// Initialize sharing service and subscribe to boarding status
  void _initializeSharingService() {
    try {
      _sharingService = widget.sharingService ?? LocationSharingService.getInstance();
      _subscribeToBoardingStatus();
    } catch (e) {
      // Firebase not initialized (e.g., in tests) - continue without real-time updates
      if (kDebugMode) {
        print('DriverStudentList: Sharing service not available: $e');
      }
    }
  }

  /// Subscribe to real-time boarding status from Firebase
  void _subscribeToBoardingStatus() {
    if (_sharingService == null) return;

    _boardingStatusSubscription = _sharingService!
        .watchBoardingStatus(groupId: widget.group.id)
        .listen((boardingStatus) {
      if (mounted) {
        setState(() {
          _realtimeBoardingStatus = boardingStatus;
        });
        if (kDebugMode) {
          print('DriverStudentList: Received boarding status: $boardingStatus');
        }
      }
    });
  }

  /// Get effective attendance status (real-time boarding status overrides local)
  AttendanceStatus _getEffectiveStatus(AttendanceModel attendance) {
    // Check real-time boarding status from Firebase
    final isBoardingToday = _realtimeBoardingStatus[attendance.studentId];

    // If Firebase says not boarding, override status
    if (isBoardingToday == false) {
      return AttendanceStatus.notRiding;
    }

    // Otherwise use local attendance status
    return attendance.status;
  }

  /// Get weekday name in Korean
  String _getWeekdayName(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  /// Get formatted date string
  String _getFormattedDate(DateTime date) {
    return '${date.month}월 ${date.day}일 (${_getWeekdayName(date)})';
  }

  /// Count riding students (riding + onBoard), respecting real-time status
  int _countRidingStudents() {
    return _attendances.where((a) {
      final effectiveStatus = _getEffectiveStatus(a);
      return effectiveStatus == AttendanceStatus.riding ||
          effectiveStatus == AttendanceStatus.onBoard;
    }).length;
  }

  /// Update attendance status
  Future<void> _updateStatus(
    AttendanceModel attendance,
    AttendanceStatus newStatus,
  ) async {
    if (_attendanceService == null) return;

    setState(() {
      _loadingAttendanceIds.add(attendance.id);
    });

    try {
      await _attendanceService!.updateAttendanceStatus(
        attendanceId: attendance.id,
        status: newStatus,
        updatedBy: widget.driver.id,
      );

      // Update local state
      setState(() {
        final index =
            _attendances.indexWhere((a) => a.id == attendance.id);
        if (index != -1) {
          _attendances[index] = attendance.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
            updatedBy: widget.driver.id,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${attendance.studentName} 상태가 변경되었습니다'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상태 변경 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loadingAttendanceIds.remove(attendance.id);
      });
    }
  }

  /// Get status badge color
  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.riding:
        return Colors.blue.shade100;
      case AttendanceStatus.notRiding:
        return Colors.grey.shade200;
      case AttendanceStatus.onBoard:
        return Colors.green.shade100;
      case AttendanceStatus.dropped:
        return Colors.purple.shade100;
    }
  }

  /// Get status badge text color
  Color _getStatusTextColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.riding:
        return Colors.blue.shade800;
      case AttendanceStatus.notRiding:
        return Colors.grey.shade600;
      case AttendanceStatus.onBoard:
        return Colors.green.shade800;
      case AttendanceStatus.dropped:
        return Colors.purple.shade800;
    }
  }

  /// Get status icon
  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.riding:
        return Icons.schedule;
      case AttendanceStatus.notRiding:
        return Icons.not_interested;
      case AttendanceStatus.onBoard:
        return Icons.directions_bus;
      case AttendanceStatus.dropped:
        return Icons.check_circle;
    }
  }

  /// Get status display name
  String _getStatusDisplayName(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.riding:
        return '탑승 예정';
      case AttendanceStatus.notRiding:
        return '탑승하지 않음';
      case AttendanceStatus.onBoard:
        return '탑승 완료';
      case AttendanceStatus.dropped:
        return '하차 완료';
    }
  }

  /// Build action button for each status
  Widget? _buildActionButton(AttendanceModel attendance, AttendanceStatus effectiveStatus) {
    final isLoading = _loadingAttendanceIds.contains(attendance.id);

    switch (effectiveStatus) {
      case AttendanceStatus.riding:
        return ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => _updateStatus(attendance, AttendanceStatus.onBoard),
          icon: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login, size: 16),
          label: const Text('탑승', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      case AttendanceStatus.onBoard:
        return ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => _updateStatus(attendance, AttendanceStatus.dropped),
          icon: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout, size: 16),
          label: const Text('하차', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      case AttendanceStatus.notRiding:
      case AttendanceStatus.dropped:
        return null; // No button for these states
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final ridingCount = _countRidingStudents();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('학생 목록'),
        backgroundColor: Colors.green.shade100,
        elevation: 0,
      ),
      body: _attendances.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 학생이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Date and statistics card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getFormattedDate(today),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Statistics
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '탑승 예정 ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '$ridingCount명',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' / 전체 ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${_attendances.length}명',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Student list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _attendances.length,
                    itemBuilder: (context, index) {
                      final attendance = _attendances[index];
                      // Use effective status (real-time from Firebase)
                      final effectiveStatus = _getEffectiveStatus(attendance);
                      final isNotRiding =
                          effectiveStatus == AttendanceStatus.notRiding;
                      final isDropped =
                          effectiveStatus == AttendanceStatus.dropped;

                      return Opacity(
                        opacity: isNotRiding ? 0.5 : 1.0,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isNotRiding ? 1 : 3,
                          color: isNotRiding
                              ? Colors.grey.shade100
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: effectiveStatus ==
                                      AttendanceStatus.onBoard
                                  ? Colors.blue.shade300
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Student icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(effectiveStatus),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: _getStatusTextColor(
                                        effectiveStatus),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Student info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name
                                      Text(
                                        attendance.studentName,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: isNotRiding
                                              ? Colors.grey.shade600
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                              effectiveStatus),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(
                                                  effectiveStatus),
                                              size: 14,
                                              color: _getStatusTextColor(
                                                  effectiveStatus),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _getStatusDisplayName(effectiveStatus),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusTextColor(
                                                    effectiveStatus),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Action button
                                if (_buildActionButton(attendance, effectiveStatus) != null)
                                  _buildActionButton(attendance, effectiveStatus)!,

                                // Completion checkmark
                                if (isDropped)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.purple.shade700,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
