import 'package:field_work/features/task/model/task_model.dart';

class TaskListResponse {
  final bool? success;
  final String? message;
  final TaskListData? data;

  TaskListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory TaskListResponse.fromJson(Map<String, dynamic> json) {
    return TaskListResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? TaskListData.fromJson(json['data'])
          : null,
    );
  }
}

class TaskListData {
  final List<TaskModel>? tasks;
  final TaskPagination? pagination;

  TaskListData({
    this.tasks,
    this.pagination,
  });

  factory TaskListData.fromJson(Map<String, dynamic> json) {
    return TaskListData(
      tasks: json['tasks'] != null
          ? List<TaskModel>.from(
        json['tasks'].map((e) => TaskModel.fromJson(e)),
      )
          : [],
      pagination: json['pagination'] != null
          ? TaskPagination.fromJson(json['pagination'])
          : null,
    );
  }
}

class TaskPagination {
  final int? currentPage;
  final int? totalPages;
  final int? total;
  final int? limit;

  TaskPagination({
    this.currentPage,
    this.totalPages,
    this.total,
    this.limit,
  });

  factory TaskPagination.fromJson(Map<String, dynamic> json) {
    return TaskPagination(
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
      total: json['total'],
      limit: json['limit'],
    );
  }
}