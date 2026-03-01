import 'package:flutter/material.dart';
import '../../../../config/theme/app_pallete.dart';
import '../../../widgets/filter_chip_button.dart';
import '../../controller/task_tab_controller.dart';


class CustomFilterBar extends StatelessWidget {
  final TaskTabController controller;
  const CustomFilterBar({super.key, required this.controller});

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
                child: CustomFilterChip(
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
                  child: CustomFilterChip(
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
            child: CustomFilterChip(
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

//  Filter hint (shown in empty state for employees)
class CustomFilterHint extends StatelessWidget {
  final TaskTabController controller;
  const CustomFilterHint({super.key, required this.controller});

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