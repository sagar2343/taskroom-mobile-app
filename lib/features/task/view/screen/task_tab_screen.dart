import 'package:field_work/features/task/controller/task_tab_controller.dart';
import 'package:field_work/features/task/view/screen/create_task_screen.dart';
import 'package:field_work/features/task/view/widgets/task_full_screen.dart';
import 'package:field_work/features/task/view/widgets/task_card.dart';
import 'package:field_work/features/widgets/filter_chip_button.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_pallete.dart';
import '../../../widgets/animated_screen_wrapper.dart';
import '../widgets/filter_bar.dart';
import '../../../employee_task/view/screen/employee_task_detail_screen.dart';
import 'manager_task_details_screen.dart';

class TasksTabScreen extends StatefulWidget {
  final String roomId;
  final bool isFullscreen;
  const TasksTabScreen({
    super.key,
    required this.roomId,
    this.isFullscreen = false,
  });

  @override
  State<TasksTabScreen> createState() => _TasksTabScreenState();
}

class _TasksTabScreenState extends State<TasksTabScreen> {
  late final TaskTabController _controller;

  @override
  void initState() {
    _controller = TaskTabController(
      context: context,
      reloadData: reloadData,
      roomId: widget.roomId,
    );
    super.initState();
    _controller.init();
  }

  void reloadData() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScreenWrapper(
      child: Stack(
        children: [
          Column(
            children: [
              // ── Fullscreen toggle header (only in tab mode)
              if (!widget.isFullscreen)
                _FullscreenHeader(
                  onExpand: () {
                    // Get room name from controller or pass it — using roomId fallback
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskFullscreenScreen(
                          roomId: widget.roomId,
                          roomName: 'Tasks',
                        ),
                        fullscreenDialog: true,
                      ),
                    ).then((_) {
                      if (mounted) _controller.onRefresh();
                    });
                  },
                  taskCount: _controller.tasks.length,
                  isLoading: _controller.isLoading,
                ),

              // --Filter bar
              CustomFilterBar(controller: _controller),

              // ── Content
              Expanded(
                child: _controller.isLoading
                    ? _buildLoader()
                    : RefreshIndicator(
                      color: Pallete.primaryColor,
                      onRefresh: _controller.onRefresh,
                      child: _controller.tasks.isEmpty
                          ? _buildEmptyState()
                          : _buildTaskList(),
                    ),
              ),
            ],
          ),

          // ── FAB for manager
          if (_controller.isManager)
            Positioned(
              bottom: 20,
              right: 20,
              child: _createFAB(),
            )
        ],
      ),
    );
  }

  // Task list
  Widget _buildTaskList() {
    return ListView.builder(
      controller: _controller.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: _controller.isManager ? 90 : 24,
      ),
      itemCount: _controller.tasks.length + (_controller.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _controller.tasks.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final task = _controller.tasks[index];
        return TaskCardWidget(
          task: task,
          isManager: _controller.isManager,
          onTap: () {
            final route = _controller.isManager
                ? MaterialPageRoute(
                  builder: (_) => ManagerTaskDetailScreen(
                    taskId: task.id!,
                    // onTaskUpdated: () => _controller.onRefresh(),
                  ),
                )
                : MaterialPageRoute(
                  builder: (_) => EmployeeTaskDetailScreen(
                    taskId: task.id!,
                    // onTaskUpdated: () => _controller.onRefresh(),
                  ),
                );
            Navigator.push(context, route).then((_) => _controller.onRefresh());
          },
        );
      },
    );
  }

  // Loader
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading tasks...',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    final isManager = _controller.isManager;
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Pallete.primaryColor.withValues(alpha: 0.12),
                      Pallete.primaryColor.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isManager ? Icons.add_task_rounded : Icons.task_alt_rounded,
                  size: 72,
                  color: Pallete.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isManager ? 'No Tasks Yet' : 'No Tasks Found',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isManager
                    ? 'Tap the + button to create your\nfirst task for this room'
                    : _getEmployeeEmptyMessage(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isManager) ...[
                const SizedBox(height: 24),
                CustomFilterHint(controller: _controller),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getEmployeeEmptyMessage() {
    switch (_controller.selectedFilter) {
      case 'today':     return 'No tasks scheduled for today.\nCheck upcoming or ask your manager.';
      case 'upcoming':  return 'No upcoming tasks assigned to you yet.';
      case 'active':    return 'No tasks currently in progress.';
      case 'completed': return 'No completed tasks yet.\nStart working on your tasks!';
      case 'missed':    return 'No missed tasks. Great work! 🎉';
      default:          return 'No tasks found.';
    }
  }

  Widget _createFAB() {
    return GestureDetector(
      onTap: (){
      // TODO: Navigate to CreateTaskScreen
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CreateTaskScreen(
            roomId: widget.roomId,
            roomName: 'ROOM NAME',
            onTaskCreated: () => _controller.onRefresh(),
          ),
          fullscreenDialog: true,
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Pallete.primaryColor, Pallete.primaryLightColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Pallete.primaryColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Create Task',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenHeader extends StatelessWidget {
  final VoidCallback onExpand;
  final int taskCount;
  final bool isLoading;

  const _FullscreenHeader({
    required this.onExpand,
    required this.taskCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          // Task count pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Pallete.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 13,
                  color: Pallete.primaryColor,
                ),
                const SizedBox(width: 5),
                Text(
                  isLoading ? '...' : '$taskCount task${taskCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Pallete.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Expand button
          GestureDetector(
            onTap: onExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fullscreen_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Full View',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
