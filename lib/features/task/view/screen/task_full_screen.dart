import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/widgets/animated_screen_wrapper.dart';
import 'package:flutter/material.dart';
import 'task_tab_screen.dart';

class TaskFullscreenScreen extends StatelessWidget {
  final String roomId;
  final String roomName;

  const TaskFullscreenScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Tasks',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              roomName,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Exit fullscreen button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Pallete.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fullscreen_exit_rounded,
                  size: 20,
                  color: Pallete.primaryColor,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Exit fullscreen',
            ),
          ),
        ],
      ),
      body: AnimatedScreenWrapper(
        child: TasksTabScreen(
          roomId: roomId,
          isFullscreen: true,
        ),
      ),
    );
  }
}