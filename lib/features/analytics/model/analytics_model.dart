// features/analytics/model/analytics_model.dart

// ─── Overview (GET /api/analytics/overview) ───────────────────────────────────
class AnalyticsOverview {
  final DateTime timestamp;
  final int totalEmployees;
  final int onlineNow;
  final int attendanceToday;
  final int attendanceRate;
  final int tasksToday;
  final int overdueTasks;
  final TaskBreakdown taskBreakdown;

  const AnalyticsOverview({
    required this.timestamp, required this.totalEmployees,
    required this.onlineNow, required this.attendanceToday,
    required this.attendanceRate, required this.tasksToday,
    required this.overdueTasks, required this.taskBreakdown,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> j) =>
      AnalyticsOverview(
        timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
        totalEmployees: j['totalEmployees'] ?? 0,
        onlineNow: j['onlineNow'] ?? 0,
        attendanceToday: j['attendanceToday'] ?? 0,
        attendanceRate: j['attendanceRate'] ?? 0,
        tasksToday: j['tasksToday'] ?? 0,
        overdueTasks: j['overdueTasks'] ?? 0,
        taskBreakdown: TaskBreakdown.fromJson(j['taskBreakdown'] ?? {}),
      );
}

class TaskBreakdown {
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  const TaskBreakdown({
    required this.pending, required this.inProgress,
    required this.completed, required this.cancelled,
  });

  factory TaskBreakdown.fromJson(Map<String, dynamic> j) => TaskBreakdown(
    pending: j['pending'] ?? 0,
    inProgress: j['in_progress'] ?? 0,
    completed: j['completed'] ?? 0,
    cancelled: j['cancelled'] ?? 0,
  );

  int get total => pending + inProgress + completed + cancelled;
}

// ─── Productivity (GET /api/analytics/productivity) ───────────────────────────
class ProductivityData {
  final DateTime from;
  final DateTime to;
  final List<EmployeeScore> scores;
  final ProductivitySummary summary;

  const ProductivityData({
    required this.from, required this.to,
    required this.scores, required this.summary,
  });

  factory ProductivityData.fromJson(Map<String, dynamic> j) {
    final period = j['period'] ?? {};
    return ProductivityData(
      from: DateTime.tryParse(period['from'] ?? '') ?? DateTime.now(),
      to:   DateTime.tryParse(period['to']   ?? '') ?? DateTime.now(),
      scores: (j['scores'] as List? ?? [])
          .map((s) => EmployeeScore.fromJson(s))
          .toList(),
      summary: ProductivitySummary.fromJson(j['summary'] ?? {}),
    );
  }
}

class EmployeeScore {
  final String employeeId;
  final String fullName;
  final String? empIdCode;
  final String? department;
  final String? designation;
  final String? profilePicture;
  final bool isOnline;
  final EmployeeStats stats;
  final int score;
  final String grade; // 'A' | 'B' | 'C' | 'D'

  const EmployeeScore({
    required this.employeeId, required this.fullName, this.empIdCode,
    this.department, this.designation, this.profilePicture,
    required this.isOnline, required this.stats,
    required this.score, required this.grade,
  });

  factory EmployeeScore.fromJson(Map<String, dynamic> j) => EmployeeScore(
    employeeId: j['employeeId'] ?? '',
    fullName: j['fullName'] ?? '',
    empIdCode: j['empIdCode'],
    department: j['department'],
    designation: j['designation'],
    profilePicture: j['profilePicture'],
    isOnline: j['isOnline'] ?? false,
    stats: EmployeeStats.fromJson(j['stats'] ?? {}),
    score: j['score'] ?? 0,
    grade: j['grade'] ?? 'D',
  );
}

class EmployeeStats {
  final int daysPresent;
  final double totalHours;
  final double avgHoursPerDay;
  final int tasksCompleted;
  final int tasksAssigned;
  final int completionRate;

  const EmployeeStats({
    required this.daysPresent, required this.totalHours,
    required this.avgHoursPerDay, required this.tasksCompleted,
    required this.tasksAssigned, required this.completionRate,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> j) => EmployeeStats(
    daysPresent: j['daysPresent'] ?? 0,
    totalHours: (j['totalHours'] ?? 0.0).toDouble(),
    avgHoursPerDay: (j['avgHoursPerDay'] ?? 0.0).toDouble(),
    tasksCompleted: j['tasksCompleted'] ?? 0,
    tasksAssigned: j['tasksAssigned'] ?? 0,
    completionRate: j['completionRate'] ?? 0,
  );
}

class ProductivitySummary {
  final int avgScore;
  final EmployeeScore? topPerformer;
  final Map<String, int> gradeDistribution;

  const ProductivitySummary({
    required this.avgScore, this.topPerformer,
    required this.gradeDistribution,
  });

  factory ProductivitySummary.fromJson(Map<String, dynamic> j) =>
      ProductivitySummary(
        avgScore: j['avgScore'] ?? 0,
        topPerformer: j['topPerformer'] != null
            ? EmployeeScore.fromJson(j['topPerformer'])
            : null,
        gradeDistribution: Map<String, int>.from(
            (j['gradeDistribution'] as Map? ?? {})
                .map((k, v) => MapEntry(k.toString(), (v as num).toInt()))),
      );
}

// ─── Trend data (GET /api/analytics/trends) ───────────────────────────────────
class TrendPoint {
  final String date;
  final int present;
  final double totalHrs;
  final int tasksDone;
  final int created;
  final int completed;

  const TrendPoint({
    required this.date, required this.present, required this.totalHrs,
    required this.tasksDone, required this.created, required this.completed,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> j) => TrendPoint(
    date: j['date'] ?? '',
    present: j['present'] ?? 0,
    totalHrs: (j['totalHrs'] ?? 0.0).toDouble(),
    tasksDone: j['tasksDone'] ?? 0,
    created: j['created'] ?? 0,
    completed: j['completed'] ?? 0,
  );
}
