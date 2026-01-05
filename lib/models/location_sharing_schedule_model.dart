import 'package:flutter/material.dart';

/// Single time slot (start ~ end)
class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
  });

  /// Create from JSON
  factory TimeSlot.fromJson(Map<dynamic, dynamic> json) {
    return TimeSlot(
      startTime: TimeOfDay(
        hour: json['startHour'] as int? ?? 8,
        minute: json['startMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int? ?? 9,
        minute: json['endMinute'] as int? ?? 30,
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
    };
  }

  /// Check if time is within this slot
  bool containsTime(DateTime dateTime) {
    final currentMinutes = dateTime.hour * 60 + dateTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  /// Get formatted string
  String get timeRangeString {
    String formatTime(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${formatTime(startTime)} ~ ${formatTime(endTime)}';
  }

  TimeSlot copyWith({TimeOfDay? startTime, TimeOfDay? endTime}) {
    return TimeSlot(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  String toString() => timeRangeString;
}

/// Location sharing schedule model
/// Defines when location sharing is active
class LocationSharingScheduleModel {
  final List<TimeSlot> timeSlots; // Multiple time slots
  final List<int> weekdays; // 1=Monday ~ 5=Friday only
  final bool excludeHolidays; // Exclude Korean public holidays

  LocationSharingScheduleModel({
    required this.timeSlots,
    List<int>? weekdays,
    this.excludeHolidays = true,
  }) : weekdays = weekdays ?? [1, 2, 3, 4, 5]; // Default: Monday-Friday

  /// Create default schedule (08:00 - 09:30, weekdays only)
  factory LocationSharingScheduleModel.defaultSchedule() {
    return LocationSharingScheduleModel(
      timeSlots: [
        const TimeSlot(
          startTime: TimeOfDay(hour: 8, minute: 0),
          endTime: TimeOfDay(hour: 9, minute: 30),
        ),
      ],
      weekdays: [1, 2, 3, 4, 5],
      excludeHolidays: true,
    );
  }

  /// Create from Firebase Realtime DB JSON
  factory LocationSharingScheduleModel.fromRealtimeDbJson(
    Map<dynamic, dynamic> json,
  ) {
    // Handle both old format (single time) and new format (multiple slots)
    List<TimeSlot> slots;
    if (json.containsKey('timeSlots')) {
      final slotsJson = json['timeSlots'] as List<dynamic>;
      slots = slotsJson
          .map((s) => TimeSlot.fromJson(s as Map<dynamic, dynamic>))
          .toList();
    } else {
      // Legacy format: single time slot
      slots = [
        TimeSlot(
          startTime: TimeOfDay(
            hour: json['startHour'] as int? ?? 8,
            minute: json['startMinute'] as int? ?? 0,
          ),
          endTime: TimeOfDay(
            hour: json['endHour'] as int? ?? 9,
            minute: json['endMinute'] as int? ?? 30,
          ),
        ),
      ];
    }

    // Filter weekdays to only allow 1-5
    final rawWeekdays = (json['weekdays'] as List<dynamic>?)
            ?.map((e) => e as int)
            .where((d) => d >= 1 && d <= 5)
            .toList() ??
        [1, 2, 3, 4, 5];

    return LocationSharingScheduleModel(
      timeSlots: slots,
      weekdays: rawWeekdays,
      excludeHolidays: json['excludeHolidays'] as bool? ?? true,
    );
  }

  /// Convert to Firebase Realtime DB JSON
  Map<String, dynamic> toRealtimeDbJson() {
    return {
      'timeSlots': timeSlots.map((s) => s.toJson()).toList(),
      'weekdays': weekdays,
      'excludeHolidays': excludeHolidays,
    };
  }

  /// Check if current time is within the sharing schedule
  bool isWithinSchedule([DateTime? dateTime]) {
    final now = dateTime ?? DateTime.now();

    // Check if it's a holiday
    if (excludeHolidays && KoreanHolidays.isHoliday(now)) {
      return false;
    }

    // Check weekday (DateTime uses 1=Monday, 7=Sunday)
    if (!weekdays.contains(now.weekday)) {
      return false;
    }

    // Check if current time is within any time slot
    return timeSlots.any((slot) => slot.containsTime(now));
  }

  /// Copy with
  LocationSharingScheduleModel copyWith({
    List<TimeSlot>? timeSlots,
    List<int>? weekdays,
    bool? excludeHolidays,
  }) {
    return LocationSharingScheduleModel(
      timeSlots: timeSlots ?? List.from(this.timeSlots),
      weekdays: weekdays ?? List.from(this.weekdays),
      excludeHolidays: excludeHolidays ?? this.excludeHolidays,
    );
  }

  /// Get weekday names in Korean
  List<String> get weekdayNames {
    const names = ['', '월', '화', '수', '목', '금', '토', '일'];
    return weekdays.map((d) => names[d]).toList();
  }

  /// Get formatted time slots string
  String get timeSlotsString {
    if (timeSlots.isEmpty) return '설정 없음';
    return timeSlots.map((s) => s.timeRangeString).join(', ');
  }

  /// Get formatted weekday string
  String get weekdayString => weekdayNames.join(', ');

  /// Get schedule summary
  String get summaryString {
    final parts = <String>[];
    parts.add(timeSlotsString);
    parts.add(weekdayString);
    if (excludeHolidays) parts.add('공휴일 제외');
    return parts.join(' | ');
  }

  // Legacy getters for backward compatibility
  TimeOfDay get startTime => timeSlots.isNotEmpty
      ? timeSlots.first.startTime
      : const TimeOfDay(hour: 8, minute: 0);

  TimeOfDay get endTime => timeSlots.isNotEmpty
      ? timeSlots.first.endTime
      : const TimeOfDay(hour: 9, minute: 30);

  String get timeRangeString => timeSlotsString;

  @override
  String toString() {
    return 'LocationSharingScheduleModel($summaryString)';
  }
}

/// Korean public holidays (2024-2040)
/// Includes: 신정, 설날, 삼일절, 어린이날, 부처님오신날, 현충일, 광복절, 추석, 개천절, 한글날, 크리스마스
/// Also includes substitute holidays (대체공휴일)
class KoreanHolidays {
  static final Set<DateTime> _holidays = {
    // 2024
    DateTime(2024, 1, 1), DateTime(2024, 2, 9), DateTime(2024, 2, 10),
    DateTime(2024, 2, 11), DateTime(2024, 2, 12), DateTime(2024, 3, 1),
    DateTime(2024, 4, 10), DateTime(2024, 5, 5), DateTime(2024, 5, 6),
    DateTime(2024, 5, 15), DateTime(2024, 6, 6), DateTime(2024, 8, 15),
    DateTime(2024, 9, 16), DateTime(2024, 9, 17), DateTime(2024, 9, 18),
    DateTime(2024, 10, 3), DateTime(2024, 10, 9), DateTime(2024, 12, 25),

    // 2025
    DateTime(2025, 1, 1), DateTime(2025, 1, 28), DateTime(2025, 1, 29),
    DateTime(2025, 1, 30), DateTime(2025, 3, 1), DateTime(2025, 3, 3),
    DateTime(2025, 5, 5), DateTime(2025, 5, 6), DateTime(2025, 6, 6),
    DateTime(2025, 8, 15), DateTime(2025, 10, 3), DateTime(2025, 10, 5),
    DateTime(2025, 10, 6), DateTime(2025, 10, 7), DateTime(2025, 10, 8),
    DateTime(2025, 10, 9), DateTime(2025, 12, 25),

    // 2026
    DateTime(2026, 1, 1), DateTime(2026, 2, 16), DateTime(2026, 2, 17),
    DateTime(2026, 2, 18), DateTime(2026, 3, 1), DateTime(2026, 3, 2),
    DateTime(2026, 5, 5), DateTime(2026, 5, 24), DateTime(2026, 5, 25),
    DateTime(2026, 6, 6), DateTime(2026, 8, 15), DateTime(2026, 8, 17),
    DateTime(2026, 9, 24), DateTime(2026, 9, 25), DateTime(2026, 9, 26),
    DateTime(2026, 10, 3), DateTime(2026, 10, 5), DateTime(2026, 10, 9),
    DateTime(2026, 12, 25),

    // 2027
    DateTime(2027, 1, 1), DateTime(2027, 2, 6), DateTime(2027, 2, 7),
    DateTime(2027, 2, 8), DateTime(2027, 2, 9), DateTime(2027, 3, 1),
    DateTime(2027, 5, 5), DateTime(2027, 5, 13), DateTime(2027, 6, 6),
    DateTime(2027, 6, 7), DateTime(2027, 8, 15), DateTime(2027, 8, 16),
    DateTime(2027, 9, 25), DateTime(2027, 9, 26), DateTime(2027, 9, 27),
    DateTime(2027, 10, 3), DateTime(2027, 10, 4), DateTime(2027, 10, 9),
    DateTime(2027, 10, 11), DateTime(2027, 12, 25),

    // 2028
    DateTime(2028, 1, 1), DateTime(2028, 1, 26), DateTime(2028, 1, 27),
    DateTime(2028, 1, 28), DateTime(2028, 3, 1), DateTime(2028, 5, 2),
    DateTime(2028, 5, 5), DateTime(2028, 6, 6), DateTime(2028, 8, 15),
    DateTime(2028, 10, 2), DateTime(2028, 10, 3), DateTime(2028, 10, 4),
    DateTime(2028, 10, 5), DateTime(2028, 10, 9), DateTime(2028, 12, 25),

    // 2029
    DateTime(2029, 1, 1), DateTime(2029, 2, 12), DateTime(2029, 2, 13),
    DateTime(2029, 2, 14), DateTime(2029, 3, 1), DateTime(2029, 5, 5),
    DateTime(2029, 5, 7), DateTime(2029, 5, 20), DateTime(2029, 5, 21),
    DateTime(2029, 6, 6), DateTime(2029, 8, 15), DateTime(2029, 9, 21),
    DateTime(2029, 9, 22), DateTime(2029, 9, 23), DateTime(2029, 9, 24),
    DateTime(2029, 10, 3), DateTime(2029, 10, 9), DateTime(2029, 12, 25),

    // 2030
    DateTime(2030, 1, 1), DateTime(2030, 2, 2), DateTime(2030, 2, 3),
    DateTime(2030, 2, 4), DateTime(2030, 2, 5), DateTime(2030, 3, 1),
    DateTime(2030, 5, 5), DateTime(2030, 5, 6), DateTime(2030, 5, 9),
    DateTime(2030, 6, 6), DateTime(2030, 8, 15), DateTime(2030, 9, 11),
    DateTime(2030, 9, 12), DateTime(2030, 9, 13), DateTime(2030, 10, 3),
    DateTime(2030, 10, 9), DateTime(2030, 12, 25),

    // 2031
    DateTime(2031, 1, 1), DateTime(2031, 1, 22), DateTime(2031, 1, 23),
    DateTime(2031, 1, 24), DateTime(2031, 3, 1), DateTime(2031, 3, 3),
    DateTime(2031, 4, 28), DateTime(2031, 5, 5), DateTime(2031, 5, 6),
    DateTime(2031, 6, 6), DateTime(2031, 8, 15), DateTime(2031, 9, 30),
    DateTime(2031, 10, 1), DateTime(2031, 10, 2), DateTime(2031, 10, 3),
    DateTime(2031, 10, 9), DateTime(2031, 12, 25),

    // 2032
    DateTime(2032, 1, 1), DateTime(2032, 2, 10), DateTime(2032, 2, 11),
    DateTime(2032, 2, 12), DateTime(2032, 3, 1), DateTime(2032, 5, 5),
    DateTime(2032, 5, 16), DateTime(2032, 5, 17), DateTime(2032, 6, 6),
    DateTime(2032, 6, 7), DateTime(2032, 8, 15), DateTime(2032, 8, 16),
    DateTime(2032, 9, 18), DateTime(2032, 9, 19), DateTime(2032, 9, 20),
    DateTime(2032, 10, 3), DateTime(2032, 10, 4), DateTime(2032, 10, 9),
    DateTime(2032, 10, 11), DateTime(2032, 12, 25),

    // 2033
    DateTime(2033, 1, 1), DateTime(2033, 1, 30), DateTime(2033, 1, 31),
    DateTime(2033, 2, 1), DateTime(2033, 3, 1), DateTime(2033, 5, 5),
    DateTime(2033, 5, 6), DateTime(2033, 6, 6), DateTime(2033, 8, 15),
    DateTime(2033, 9, 7), DateTime(2033, 9, 8), DateTime(2033, 9, 9),
    DateTime(2033, 10, 3), DateTime(2033, 10, 9), DateTime(2033, 10, 10),
    DateTime(2033, 12, 25), DateTime(2033, 12, 26),

    // 2034
    DateTime(2034, 1, 1), DateTime(2034, 1, 2), DateTime(2034, 2, 18),
    DateTime(2034, 2, 19), DateTime(2034, 2, 20), DateTime(2034, 2, 21),
    DateTime(2034, 3, 1), DateTime(2034, 5, 5), DateTime(2034, 5, 25),
    DateTime(2034, 6, 6), DateTime(2034, 8, 15), DateTime(2034, 9, 26),
    DateTime(2034, 9, 27), DateTime(2034, 9, 28), DateTime(2034, 10, 3),
    DateTime(2034, 10, 9), DateTime(2034, 12, 25),

    // 2035
    DateTime(2035, 1, 1), DateTime(2035, 2, 7), DateTime(2035, 2, 8),
    DateTime(2035, 2, 9), DateTime(2035, 3, 1), DateTime(2035, 5, 5),
    DateTime(2035, 5, 7), DateTime(2035, 5, 14), DateTime(2035, 6, 6),
    DateTime(2035, 8, 15), DateTime(2035, 9, 15), DateTime(2035, 9, 16),
    DateTime(2035, 9, 17), DateTime(2035, 10, 3), DateTime(2035, 10, 9),
    DateTime(2035, 12, 25),

    // 2036
    DateTime(2036, 1, 1), DateTime(2036, 1, 27), DateTime(2036, 1, 28),
    DateTime(2036, 1, 29), DateTime(2036, 3, 1), DateTime(2036, 3, 3),
    DateTime(2036, 5, 3), DateTime(2036, 5, 5), DateTime(2036, 5, 6),
    DateTime(2036, 6, 6), DateTime(2036, 8, 15), DateTime(2036, 10, 3),
    DateTime(2036, 10, 4), DateTime(2036, 10, 5), DateTime(2036, 10, 6),
    DateTime(2036, 10, 9), DateTime(2036, 12, 25),

    // 2037
    DateTime(2037, 1, 1), DateTime(2037, 2, 14), DateTime(2037, 2, 15),
    DateTime(2037, 2, 16), DateTime(2037, 3, 1), DateTime(2037, 3, 2),
    DateTime(2037, 5, 5), DateTime(2037, 5, 22), DateTime(2037, 6, 6),
    DateTime(2037, 8, 15), DateTime(2037, 8, 17), DateTime(2037, 9, 23),
    DateTime(2037, 9, 24), DateTime(2037, 9, 25), DateTime(2037, 10, 3),
    DateTime(2037, 10, 5), DateTime(2037, 10, 9), DateTime(2037, 12, 25),

    // 2038
    DateTime(2038, 1, 1), DateTime(2038, 2, 3), DateTime(2038, 2, 4),
    DateTime(2038, 2, 5), DateTime(2038, 3, 1), DateTime(2038, 5, 5),
    DateTime(2038, 5, 11), DateTime(2038, 6, 6), DateTime(2038, 6, 7),
    DateTime(2038, 8, 15), DateTime(2038, 8, 16), DateTime(2038, 9, 12),
    DateTime(2038, 9, 13), DateTime(2038, 9, 14), DateTime(2038, 10, 3),
    DateTime(2038, 10, 4), DateTime(2038, 10, 9), DateTime(2038, 10, 11),
    DateTime(2038, 12, 25),

    // 2039
    DateTime(2039, 1, 1), DateTime(2039, 1, 23), DateTime(2039, 1, 24),
    DateTime(2039, 1, 25), DateTime(2039, 3, 1), DateTime(2039, 4, 30),
    DateTime(2039, 5, 2), DateTime(2039, 5, 5), DateTime(2039, 6, 6),
    DateTime(2039, 8, 15), DateTime(2039, 10, 1), DateTime(2039, 10, 2),
    DateTime(2039, 10, 3), DateTime(2039, 10, 9), DateTime(2039, 10, 10),
    DateTime(2039, 12, 25), DateTime(2039, 12, 26),

    // 2040
    DateTime(2040, 1, 1), DateTime(2040, 1, 2), DateTime(2040, 2, 11),
    DateTime(2040, 2, 12), DateTime(2040, 2, 13), DateTime(2040, 3, 1),
    DateTime(2040, 5, 5), DateTime(2040, 5, 7), DateTime(2040, 5, 18),
    DateTime(2040, 6, 6), DateTime(2040, 8, 15), DateTime(2040, 9, 20),
    DateTime(2040, 9, 21), DateTime(2040, 9, 22), DateTime(2040, 9, 24),
    DateTime(2040, 10, 3), DateTime(2040, 10, 9), DateTime(2040, 12, 25),
  };

  /// Check if a date is a Korean public holiday
  static bool isHoliday(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _holidays.contains(dateOnly);
  }

  /// Get all holidays for a specific year
  static List<DateTime> getHolidaysForYear(int year) {
    return _holidays.where((d) => d.year == year).toList()..sort();
  }

  /// Get next upcoming holiday
  static DateTime? getNextHoliday([DateTime? from]) {
    final now = from ?? DateTime.now();
    final upcoming = _holidays.where((d) => d.isAfter(now)).toList()..sort();
    return upcoming.isNotEmpty ? upcoming.first : null;
  }
}
