class AttendanceSession {
  final int? id;
  final String checkInTime;
  final String? checkOutTime;
  final double? sessionHours;
  final String? checkInImagePath;
  final String? checkOutImagePath;

  const AttendanceSession({
    this.id,
    required this.checkInTime,
    this.checkOutTime,
    this.sessionHours,
    this.checkInImagePath,
    this.checkOutImagePath,
  });

  bool get isOpen => checkOutTime == null;

  factory AttendanceSession.fromJson(Map<String, dynamic> j) => AttendanceSession(
        id: j['id'] as int?,
        checkInTime: j['checkInTime'] as String? ?? '',
        checkOutTime: j['checkOutTime'] as String?,
        sessionHours: (j['sessionHours'] as num?)?.toDouble(),
        checkInImagePath: j['checkInImagePath'] as String?,
        checkOutImagePath: j['checkOutImagePath'] as String?,
      );
}

class AttendanceRecord {
  final int id;
  final String attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final double? workingHours;
  final String status;
  final String? checkInImagePath;
  final String? checkOutImagePath;
  final List<AttendanceSession> sessions;

  const AttendanceRecord({
    required this.id,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    required this.status,
    this.checkInImagePath,
    this.checkOutImagePath,
    this.sessions = const [],
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'] as int,
        attendanceDate: j['attendance_date'] as String? ?? '',
        checkInTime: j['check_in_time'] as String?,
        checkOutTime: j['check_out_time'] as String?,
        workingHours: (j['working_hours'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'absent',
        checkInImagePath: j['check_in_image_path'] as String?,
        checkOutImagePath: j['check_out_image_path'] as String?,
        sessions: (j['sessions'] as List<dynamic>?)
                ?.map((s) => AttendanceSession.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id':                  id,
        'attendance_date':     attendanceDate,
        'check_in_time':       checkInTime,
        'check_out_time':      checkOutTime,
        'working_hours':       workingHours,
        'status':              status,
        'check_in_image_path': checkInImagePath,
        'check_out_image_path':checkOutImagePath,
      };
}

class TodayStatus {
  final bool hasRecord;
  final String date;
  final double? workingHours;
  final String? status;
  final bool hasOpenSession;
  final int sessionCount;
  final List<AttendanceSession> sessions;

  const TodayStatus({
    required this.hasRecord,
    required this.date,
    this.workingHours,
    this.status,
    required this.hasOpenSession,
    required this.sessionCount,
    required this.sessions,
  });

  factory TodayStatus.fromJson(Map<String, dynamic> j) => TodayStatus(
        hasRecord: j['hasRecord'] as bool? ?? false,
        date: j['date'] as String? ?? '',
        workingHours: (j['workingHours'] as num?)?.toDouble(),
        status: j['status'] as String?,
        hasOpenSession: j['hasOpenSession'] as bool? ?? false,
        sessionCount: j['sessionCount'] as int? ?? 0,
        sessions: (j['sessions'] as List<dynamic>?)
                ?.map((s) => AttendanceSession.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class MonthlySummary {
  final int present;
  final int halfDay;
  final int absent;
  final int workingDays;
  final double avgWorkingHours;
  final String month;

  const MonthlySummary({
    required this.present,
    required this.halfDay,
    required this.absent,
    required this.workingDays,
    required this.avgWorkingHours,
    required this.month,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> j) => MonthlySummary(
        present: j['present'] as int? ?? 0,
        halfDay: j['half_day'] as int? ?? 0,
        absent: j['absent'] as int? ?? 0,
        workingDays: j['working_days'] as int? ?? 0,
        avgWorkingHours: (j['avg_working_hours'] as num?)?.toDouble() ?? 0.0,
        month: j['month'] as String? ?? '',
      );

  double get attendancePercent {
    if (workingDays == 0) return 0;
    return ((present + halfDay * 0.5) / workingDays) * 100;
  }
}

class AdminStats {
  final int totalFaculty;
  final int todayPresent;
  final int todayAbsent;
  final int todayCheckout;
  final int todayHalfDay;
  final int totalAttendance;
  final List<Map<String, dynamic>> departments;

  const AdminStats({
    required this.totalFaculty,
    required this.todayPresent,
    required this.todayAbsent,
    required this.todayCheckout,
    required this.todayHalfDay,
    required this.totalAttendance,
    required this.departments,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalFaculty: j['totalFaculty'] as int? ?? 0,
        todayPresent: j['todayPresent'] as int? ?? 0,
        todayAbsent: j['todayAbsent'] as int? ?? 0,
        todayCheckout: j['todayCheckout'] as int? ?? 0,
        todayHalfDay: j['todayHalfDay'] as int? ?? 0,
        totalAttendance: j['totalAttendance'] as int? ?? 0,
        departments: (j['departments'] as List<dynamic>?)
                ?.map((d) => d as Map<String, dynamic>)
                .toList() ??
            [],
      );
}
