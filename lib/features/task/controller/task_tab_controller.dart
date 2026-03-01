import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/helpers.dart';
import '../data/task_datasource.dart';
import '../model/task_list_response.dart';

class TaskTabController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String roomId;

  final TaskDataSource _dataSource = TaskDataSource();
  final ScrollController scrollController = ScrollController();

  bool isLoading = false;
  bool isLoadingMore = false;
  List<TaskModel> tasks = [];

  bool get isManager => AppData().getUserData()?.role == 'manager';

  // Manager filters
  String selectedStatus = 'all';       // all | pending | in_progress | completed | overdue | cancelled
  String selectedPriority = 'all';     // all | low | medium | high

  // Employee filters (tab-style)
  String selectedFilter = 'today';     // today | upcoming | active | completed


  // pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool get hasMore => _currentPage < _totalPages;

  // ── Filter options for UI
  final List<Map<String, String>> managerStatusFilters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'In Progress', 'value': 'in_progress'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Overdue', 'value': 'overdue'},
    {'label': 'Cancelled', 'value': 'cancelled'},
    {'label': 'Missed', 'value': 'missed'},
  ];

  final List<Map<String, String>> priorityFilters = [
    {'label': 'All', 'value': 'all'},
    {'label': '🔴 High', 'value': 'high'},
    {'label': '🟡 Medium', 'value': 'medium'},
    {'label': '🟢 Low', 'value': 'low'},
  ];

  final List<Map<String, String>> employeeFilters = [
    {'label': 'Today', 'value': 'today'},
    {'label': 'Upcoming', 'value': 'upcoming'},
    {'label': 'Active', 'value': 'active'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Missed',    'value': 'missed'},
  ];


  TaskTabController({
    required this.context,
    required this.reloadData,
    required this.roomId,
  }){
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMore();
    }
  }


  void init() async {
    await fetchTasks(reset: true);
  }

  Future<void> fetchTasks({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      tasks = [];
      isLoading = true;
    } else {
      isLoadingMore = true;
    }
    reloadData();

    try {
      TaskListResponse? response;

      if (isManager) {
        response = await _dataSource.getManagerTasks(
          roomId: roomId,
          status: selectedStatus == 'all' ? null : selectedStatus,
          priority: selectedPriority == 'all' ? null : selectedPriority,
          page: _currentPage,
        );
      } else {
        response = await _dataSource.getMyTasks(
          filter: selectedFilter,
          page: _currentPage,
        );
      }

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        final newTasks = response.data?.tasks ?? [];
        if (reset) {
          tasks = newTasks;
        } else {
          tasks.addAll(newTasks);
        }
        _totalPages = response.data?.pagination?.totalPages ?? 1;

      } else {
        Helpers.showSnackBar(
          context,
          response.message ?? 'Something went wrong!',
          type: SnackType.error,
        );
      }

    } catch(e) {
      debugPrint('fetchTasks error: $e');
      Helpers.showSnackBar(
        context,
        e.toString(),
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      isLoadingMore = false;
      reloadData();
    }
  }

  // status filers
  void onStatusFilterChanged(String value) {
    selectedStatus = value;
    fetchTasks(reset: true);
  }

  void onPriorityFilterChanged(String value) {
    selectedPriority = value;
    fetchTasks(reset: true);
  }

  void onEmployeeFilterChanged(String value) {
    selectedFilter = value;;
    fetchTasks(reset: true);
  }

  Future<void> onRefresh()=> fetchTasks(reset: true);

  void loadMore() {
    if (!isLoadingMore && hasMore) {
      _currentPage++;
      fetchTasks();
    }
  }

  // Helpers
  String formatTime(DateTime? dt) {
    if (dt == null) return '--';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String formatDate(DateTime? dt) {
    if (dt == null) return '--';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  bool isToday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }


  void dispose() {
    scrollController.dispose();
  }

}