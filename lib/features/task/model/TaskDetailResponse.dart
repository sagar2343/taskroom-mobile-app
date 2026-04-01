import 'package:field_work/features/task/model/task_model.dart';

class TaskDetailResponse {
  final bool? success;
  final String? message;
  final TaskDetailData? data;

  TaskDetailResponse({
    this.success,
    this.message,
    this.data,
  });

  factory TaskDetailResponse.fromJson(Map<String, dynamic> json) {
    return TaskDetailResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? TaskDetailData.fromJson(json['data'])
          : null,
    );
  }
}

class TaskDetailData {
  final TaskModel? task;

  TaskDetailData({this.task});

  factory TaskDetailData.fromJson(Map<String, dynamic> json) {
    return TaskDetailData(
      task: json['task'] != null
          ? TaskModel.fromJson(json['task'])
          : null,
    );
  }
}