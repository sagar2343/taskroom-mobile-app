class AttendanceSession {
  final DateTime startTime;
  final DateTime? endTime;
  final double? durationMinutes;
  final String method;

  const AttendanceSession({
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.method = 'manual',
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> j) => AttendanceSession(
    startTime:       DateTime.parse(j['startTime']).toLocal(),
    endTime:         j['endTime'] != null ? DateTime.parse(j['endTime']).toLocal() : null,
    durationMinutes: (j['durationMinutes'] as num?)?.toDouble(),
    method:          j['method'] ?? 'manual',
  );

  bool get isOpen => endTime == null;

  String get durationFormatted {
    final mins = (durationMinutes ?? 0).round();
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h ${mins % 60}m';
  }
}

class AttendanceModel {
  final String id;
  final String employeeId;
  final DateTime workDate;
  final List<AttendanceSession> sessions;
  final double totalMinutes;
  final bool isOnline;
  final int tasksCompleted;
  final int tasksAssigned;
  final int tasksInProgress;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.workDate,
    required this.sessions,
    required this.totalMinutes,
    required this.isOnline,
    required this.tasksCompleted,
    required this.tasksAssigned,
    required this.tasksInProgress,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> j) => AttendanceModel(
    id:              j['_id']?.toString() ?? '',
    // employeeId:      j['employee']?['_id']?.toString() ?? j['employee']?.toString() ?? '',
    employeeId:      j['employee'] is Map ? j['employee']['_id']?.toString() ?? '' : j['employee']?.toString() ?? '',
    workDate:        DateTime.parse(j['workDate']).toLocal(),
    sessions: ((j['sessions'] as List?) ?? [])
        .map<AttendanceSession>(
            (s) => AttendanceSession.fromJson(s as Map<String, dynamic>))
        .toList(),
    totalMinutes:    (j['totalMinutes'] as num?)?.toDouble() ?? 0,
    isOnline:        j['isOnline'] == true,
    tasksCompleted:  (j['tasksCompleted'] as num?)?.toInt() ?? 0,
    tasksAssigned:   (j['tasksAssigned']  as num?)?.toInt() ?? 0,
    tasksInProgress: (j['tasksInProgress'] as num?)?.toInt() ?? 0,
  );

  String get totalFormatted {
    final mins = totalMinutes.round();
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  double get totalHours => totalMinutes / 60;

  AttendanceSession? get openSession {
    try { return sessions.firstWhere((s) => s.isOpen); }
    catch (_) { return null; }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AttendanceTaskStats {
  final int completed;
  final int inProgress;
  final int assigned;
  final int completionRate;

  const AttendanceTaskStats({
    required this.completed,
    required this.inProgress,
    required this.assigned,
    required this.completionRate,
  });

  factory AttendanceTaskStats.fromJson(Map<String, dynamic> j) => AttendanceTaskStats(
    completed:      (j['completed']      as num?)?.toInt() ?? 0,
    inProgress:     (j['inProgress']     as num?)?.toInt() ?? 0,
    assigned:       (j['assigned']       as num?)?.toInt() ?? 0,
    completionRate: (j['completionRate'] as num?)?.toInt() ?? 0,
  );

  factory AttendanceTaskStats.empty() =>
      const AttendanceTaskStats(completed: 0, inProgress: 0, assigned: 0, completionRate: 0);
}

// ─────────────────────────────────────────────────────────────────────────────

class AttendanceTodayData {
  final AttendanceModel? attendance;
  final bool isOnline;
  final double totalMinutes;
  final String totalFormatted;
  final List<AttendanceSession> sessions;
  final AttendanceTaskStats taskStats;

  const AttendanceTodayData({
    this.attendance,
    required this.isOnline,
    required this.totalMinutes,
    required this.totalFormatted,
    required this.sessions,
    required this.taskStats,
  });

  factory AttendanceTodayData.fromJson(Map<String, dynamic> j) => AttendanceTodayData(
    attendance:     j['attendance'] != null
        ? AttendanceModel.fromJson(j['attendance'] as Map<String, dynamic>)
        : null,
    isOnline:       j['isOnline'] == true,
    totalMinutes:   (j['totalMinutes'] as num?)?.toDouble() ?? 0,
    totalFormatted: j['totalFormatted']?.toString() ?? '0m',
    sessions: (j['sessions'] as List? ?? [])
        .map((s) => AttendanceSession.fromJson(s as Map<String, dynamic>))
        .toList(),
    taskStats: j['taskStats'] != null
        ? AttendanceTaskStats.fromJson(j['taskStats'] as Map<String, dynamic>)
        : AttendanceTaskStats.empty(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class AttendanceSummary {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final double totalMinutes;
  final double totalHours;
  final double avgHoursPerDay;
  final int tasksCompleted;

  const AttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.totalMinutes,
    required this.totalHours,
    required this.avgHoursPerDay,
    required this.tasksCompleted,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) => AttendanceSummary(
    totalDays:      (j['totalDays']      as num?)?.toInt()    ?? 0,
    presentDays:    (j['presentDays']    as num?)?.toInt()    ?? 0,
    absentDays:     (j['absentDays']     as num?)?.toInt()    ?? 0,
    totalMinutes:   (j['totalMinutes']   as num?)?.toDouble() ?? 0,
    totalHours:     (j['totalHours']     as num?)?.toDouble() ?? 0,
    avgHoursPerDay: (j['avgHoursPerDay'] as num?)?.toDouble() ?? 0,
    tasksCompleted: (j['tasksCompleted'] as num?)?.toInt()    ?? 0,
  );

  factory AttendanceSummary.empty() => const AttendanceSummary(
    totalDays: 0, presentDays: 0, absentDays: 0,
    totalMinutes: 0, totalHours: 0, avgHoursPerDay: 0, tasksCompleted: 0,
  );

  String get totalFormatted {
    final mins = totalMinutes.round();
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h ${mins % 60}m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Manager — org employee summary entry
// ─────────────────────────────────────────────────────────────────────────────

class OrgEmployeeAttendance {
  final String id;
  final String username;
  final String? fullName;
  final String? profilePicture;
  final String? department;
  final String? designation;
  final bool isOnline;

  final bool attendanceOnline;
  final double attendanceTotalMinutes;
  final String attendanceTotalFormatted;
  final int attendanceSessions;
  final DateTime? firstOnline;

  final int taskTotal;
  final int taskCompleted;
  final int taskActive;
  final int completionRate;

  const OrgEmployeeAttendance({
    required this.id,
    required this.username,
    this.fullName,
    this.profilePicture,
    this.department,
    this.designation,
    required this.isOnline,
    required this.attendanceOnline,
    required this.attendanceTotalMinutes,
    required this.attendanceTotalFormatted,
    required this.attendanceSessions,
    this.firstOnline,
    required this.taskTotal,
    required this.taskCompleted,
    required this.taskActive,
    required this.completionRate,
  });

  factory OrgEmployeeAttendance.fromJson(Map<String, dynamic> j) {
    final emp  = j['employee'] as Map<String, dynamic>;
    final att  = j['attendance'] as Map<String, dynamic>? ?? {};
    final task = j['taskStats']  as Map<String, dynamic>? ?? {};
    return OrgEmployeeAttendance(
      id:             emp['_id']?.toString() ?? '',
      username:       emp['username']?.toString() ?? '',
      fullName:       emp['fullName']?.toString(),
      profilePicture: emp['profilePicture']?.toString(),
      department:     emp['department']?.toString(),
      designation:    emp['designation']?.toString(),
      isOnline:       emp['isOnline'] == true,
      attendanceOnline:         att['isOnline'] == true,
      attendanceTotalMinutes:   (att['totalMinutes'] as num?)?.toDouble() ?? 0,
      attendanceTotalFormatted: att['totalFormatted']?.toString() ?? '0m',
      attendanceSessions:       (att['sessions'] as num?)?.toInt() ?? 0,
      firstOnline: att['firstOnline'] != null
          ? DateTime.parse(att['firstOnline'].toString()).toLocal()
          : null,
      taskTotal:      (task['total']          as num?)?.toInt() ?? 0,
      taskCompleted:  (task['completed']       as num?)?.toInt() ?? 0,
      taskActive:     (task['active']          as num?)?.toInt() ?? 0,
      completionRate: (task['completionRate']  as num?)?.toInt() ?? 0,
    );
  }
}