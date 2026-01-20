import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/attendance_service.dart';

/// Parent boarding settings screen - Allows parents to set their boarding status
class ParentBoardingScreen extends StatefulWidget {
  final UserModel user;
  final GroupModel? group;
  final AttendanceStatus? initialStatus;

  const ParentBoardingScreen({
    super.key,
    required this.user,
    this.group,
    this.initialStatus,
  });

  @override
  State<ParentBoardingScreen> createState() => _ParentBoardingScreenState();
}

class _ParentBoardingScreenState extends State<ParentBoardingScreen>
    with SingleTickerProviderStateMixin {
  late AttendanceStatus _currentStatus;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus ?? AttendanceStatus.riding;

    // Setup animation controller for status change
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Get weekday name in Korean
  String _getWeekdayName(int weekday) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[weekday - 1];
  }

  /// Format date as "M월 d일"
  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  /// Show confirmation dialog for canceling boarding
  Future<void> _showCancelConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('탑승 취소 확인', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: const Text(
          '오늘 셔틀버스를 이용하지 않으시겠어요?',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('확인', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _updateStatus(AttendanceStatus.notRiding);
    }
  }

  /// Update attendance status
  Future<void> _updateStatus(AttendanceStatus newStatus) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final attendanceService = await AttendanceServiceFactory.getInstance();
      final today = DateTime.now();

      // Get or create attendance for today
      var attendance = await attendanceService.getAttendanceByStudent(
        widget.group?.id ?? '',
        widget.user.id,
        today,
      );

      if (attendance == null) {
        // Create new attendance
        attendance = await attendanceService.createAttendance(
          groupId: widget.group?.id ?? '',
          studentId: widget.user.id,
          studentName: widget.user.nickname,
          date: today,
        );
      }

      // Update status
      await attendanceService.updateAttendanceStatus(
        attendanceId: attendance.id,
        status: newStatus,
        updatedBy: widget.user.id,
      );

      if (mounted) {
        setState(() {
          _currentStatus = newStatus;
          _isLoading = false;
        });

        // Replay animation on status change
        _animationController.reset();
        _animationController.forward();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == AttendanceStatus.riding
                  ? '탑승 예정으로 변경되었습니다'
                  : '오늘은 탑승하지 않는 것으로 설정되었습니다',
            ),
            backgroundColor: newStatus == AttendanceStatus.riding
                ? Colors.green
                : Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상태 변경 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateString = '${_formatDate(now)} (${_getWeekdayName(now.weekday)})';

    final isRiding = _currentStatus == AttendanceStatus.riding;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('탑승 설정', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateString,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isRiding
                              ? Colors.green.shade50
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRiding ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: isRiding
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isRiding ? '탑승 예정' : '탑승하지 않음',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isRiding
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // User info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '학부모',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.user.nickname,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Current status card with animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isRiding
                                ? [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ]
                                : [
                                    Colors.grey.shade300,
                                    Colors.grey.shade400,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (isRiding
                                      ? Colors.green
                                      : Colors.grey)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isRiding
                                    ? Icons.directions_bus
                                    : Icons.cancel_outlined,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              isRiding ? '탑승 예정' : '탑승하지 않음',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRiding
                                  ? '오늘 셔틀버스를 이용합니다'
                                  : '오늘은 셔틀버스를 이용하지 않습니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action button at bottom
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (isRiding) {
                              _showCancelConfirmDialog();
                            } else {
                              _updateStatus(AttendanceStatus.riding);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRiding
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: (isRiding ? Colors.red : Colors.green)
                          .withValues(alpha: 0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isRiding ? Icons.close : Icons.check,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isRiding
                                    ? '오늘은 탑승하지 않아요'
                                    : '탑승 예정으로 변경',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
