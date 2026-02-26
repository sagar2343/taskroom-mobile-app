import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/task/controller/task_tab_controller.dart';
import 'package:field_work/features/widgets/animated_screen_wrapper.dart';
import 'package:flutter/material.dart';

import '../widgets/task_card.dart';

class TasksTabScreen extends StatefulWidget {
  final String roomId;
  const TasksTabScreen({super.key, required this.roomId});

  @override
  State<TasksTabScreen> createState() => _TasksTabScreenState();
}

class _TasksTabScreenState extends State<TasksTabScreen> {
  late final TaskTabController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TaskTabController(
      context: context,
      reloadData: reloadData,
      roomId: widget.roomId,
    );
    _scrollController.addListener(_onScroll);
    _controller.init();
  }

  void reloadData() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
              // ── Filter bar
              _FilterBar(controller: _controller),

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
              child: _CreateTaskFAB(
                onTap: () {
                  // TODO: Navigate to CreateTaskScreen
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (_) => CreateTaskScreen(roomId: widget.roomId),
                  // )).then((_) => _controller.onRefresh());
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Task list
  // ─────────────────────────────────────────────────────────

  Widget _buildTaskList() {
    return ListView.builder(
      controller: _scrollController,
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
            // TODO: Navigate to TaskDetailScreen
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (_) => TaskDetailScreen(taskId: task.id!),
            // )).then((_) => _controller.onRefresh());
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Loader
  // ─────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────
  //  Empty state
  // ─────────────────────────────────────────────────────────

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
                _FilterHint(controller: _controller),
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
      default:          return 'No tasks found.';
    }
  }
}

// ─────────────────────────────────────────────────────────
//  Filter Bar
// ─────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TaskTabController controller;
  const _FilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: controller.isManager
          ? _ManagerFilters(controller: controller)
          : _EmployeeFilters(controller: controller),
    );
  }
}

// Manager: two rows — status + priority
class _ManagerFilters extends StatelessWidget {
  final TaskTabController controller;
  const _ManagerFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status filter row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: controller.managerStatusFilters.map((f) {
              final isSelected = controller.selectedStatus == f['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: f['label']!,
                  isSelected: isSelected,
                  onTap: () => controller.onStatusFilterChanged(f['value']!),
                ),
              );
            }).toList(),
          ),
        ),
        // Priority filter row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Text(
                'Priority:',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              ...controller.priorityFilters.map((f) {
                final isSelected = controller.selectedPriority == f['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: f['label']!,
                    isSelected: isSelected,
                    onTap: () => controller.onPriorityFilterChanged(f['value']!),
                    small: true,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// Employee: single tab-style row
class _EmployeeFilters extends StatelessWidget {
  final TaskTabController controller;
  const _EmployeeFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: controller.employeeFilters.map((f) {
          final isSelected = controller.selectedFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: f['label']!,
              isSelected: isSelected,
              onTap: () => controller.onEmployeeFilterChanged(f['value']!),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool small;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 14,
          vertical: small ? 5 : 7,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [Pallete.primaryColor, Pallete.primaryLightColor],
          )
              : null,
          color: isSelected
              ? null
              : theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Filter hint (shown in empty state for employees)
// ─────────────────────────────────────────────────────────

class _FilterHint extends StatelessWidget {
  final TaskTabController controller;
  const _FilterHint({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.selectedFilter == 'today') {
      return GestureDetector(
        onTap: () => controller.onEmployeeFilterChanged('upcoming'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Pallete.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Pallete.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_rounded, size: 16, color: Pallete.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Check upcoming tasks →',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Pallete.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────
//  Create Task FAB
// ─────────────────────────────────────────────────────────

class _CreateTaskFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateTaskFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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