import 'package:flutter/material.dart';

/// Location sharing schedule model
/// Defines when location sharing is active (weekdays only)
class LocationSharingScheduleModel {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> weekdays; // 1=Monday, 2=Tuesday, ..., 7=Sunday

  LocationSharingScheduleModel({
    required this.startTime,
    required this.endTime,
    List<int>? weekdays,
  }) : weekdays = weekdays ?? [1, 2, 3, 4, 5]; // Default: Monday-Friday

  /// Create default schedule (08:00 - 09:30, weekdays only)
  factory LocationSharingScheduleModel.defaultSchedule() {
    return LocationSharingScheduleModel(
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 9, minute: 30),
      weekdays: [1, 2, 3, 4, 5],
    );
  }

  /// Create from Firebase Realtime DB JSON
  factory LocationSharingScheduleModel.fromRealtimeDbJson(
    Map<dynamic, dynamic> json,
  ) {
    return LocationSharingScheduleModel(
      startTime: TimeOfDay(
        hour: json['startHour'] as int? ?? 8,
        minute: json['startMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int? ?? 9,
        minute: json['endMinute'] as int? ?? 30,
      ),
      weekdays: (json['weekdays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [1, 2, 3, 4, 5],
    );
  }

  /// Convert to Firebase Realtime DB JSON
  Map<String, dynamic> toRealtimeDbJson() {
    return {
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'weekdays': weekdays,
    };
  }

  /// Check if current time is within the sharing schedule
  bool isWithinSchedule([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();

    // Check weekday (DateTime uses 1=Monday, 7=Sunday)
    if (!weekdays.contains(now.weekday)) {
      return false;
    }

    // Convert current time to minutes since midnight
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  /// Copy with
  LocationSharingScheduleModel copyWith({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<int>? weekdays,
  }) {
    return LocationSharingScheduleModel(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      weekdays: weekdays ?? List.from(this.weekdays),
    );
  }

  /// Get weekday names in Korean
  List<String> get weekdayNames {
    const names = ['', '월', '화', '수', '목', '금', '토', '일'];
    return weekdays.map((d) => names[d]).toList();
  }

  /// Get formatted time range string
  String get timeRangeString {
    String formatTime(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${formatTime(startTime)} ~ ${formatTime(endTime)}';
  }

  /// Get formatted weekday string
  String get weekdayString => weekdayNames.join(', ');

  @override
  String toString() {
    return 'LocationSharingScheduleModel($timeRangeString, $weekdayString)';
  }
}
