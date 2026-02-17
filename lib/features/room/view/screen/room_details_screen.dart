import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/widgets/animated_screen_wrapper.dart';
import 'package:flutter/material.dart';
import '../../../member/view/screen/member_tab_screen.dart';
import 'overview_tab_screen.dart';
import '../../../task/view/screen/task_tab_screen.dart';
import '../../controller/room_details_controller.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen>
    with SingleTickerProviderStateMixin {
  late final RoomDetailController _controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = RoomDetailController(
      context: context,
      roomId: widget.roomId,
      reloadData: reloadData,
    );
    _tabController = TabController(length: 3, vsync: this);
    _controller.init();
  }

  void reloadData() => setState(() {});

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
          ),
        ),
      );
    }

    if (_controller.room == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
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
        title: Text(
          _controller.room?.name ?? 'Room Details',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_controller.canEdit())
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Pallete.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit,
                  size: 20,
                  color: Pallete.primaryColor,
                ),
              ),
              onPressed: _controller.onEditRoom,
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: AnimatedScreenWrapper(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Pallete.primaryColor,
                      Pallete.primaryLightColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Tasks'),
                  Tab(text: 'Members'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: AnimatedScreenWrapper(
        child: TabBarView(
          controller: _tabController,
          children: [
            OverviewTabScreen(
              room: _controller.room!,
              onRefresh: _controller.onRefresh,
              formatDate: _controller.formatDate,
              onDeleteRoom: _controller.isManager ? _controller.onArchiveRoom : null,
              isManager: _controller.isManager,
            ),
            const TasksTabScreen(),
            MemberTabScreen(roomId: widget.roomId),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Pallete.errorColor.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to Load Room',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please try again later',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}