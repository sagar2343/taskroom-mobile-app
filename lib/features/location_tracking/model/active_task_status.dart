// lib/features/location_tracking/model/active_task_status.dart

class ActiveTaskStatus {
  final bool hasActiveTask;
  final String? taskId;
  final String? stepId;
  final bool requiresTracking;
  final String? roomId;

  const ActiveTaskStatus({
    required this.hasActiveTask,
    this.taskId,
    this.stepId,
    required this.requiresTracking,
    this.roomId,
  });

  factory ActiveTaskStatus.none() => const ActiveTaskStatus(
    hasActiveTask: false,
    requiresTracking: false,
  );

  factory ActiveTaskStatus.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>? ?? {};
    return ActiveTaskStatus(
      hasActiveTask:    d['hasActiveTask']    as bool? ?? false,
      taskId:           d['taskId']           as String?,
      stepId:           d['stepId']           as String?,
      requiresTracking: d['requiresTracking'] as bool? ?? false,
      roomId:           d['roomId']           as String?,
    );
  }
}