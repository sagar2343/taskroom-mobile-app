import 'package:field_work/features/home/controller/home_controller.dart';
import 'package:field_work/features/widgets/animated_screen_wrapper.dart';
import 'package:field_work/features/widgets/avatar_initials.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_pallete.dart';
import '../widget/room_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    _controller = HomeController(context: context, reloadData: reloadData);
    super.initState();
    _controller.init();
  }

  void reloadData() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = _controller.userData;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
          title: userData != null
              ? Row(
                children: [
                  // Profile Avatar with Glow
                  GestureDetector(
                    onTap: _controller.onProfileTapped,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Pallete.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'avatar',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Pallete.primaryColor,
                                Pallete.primaryLightColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Pallete.primaryColor.withValues(alpha: 0.5),
                              width: 2.5,
                            ),
                          ),
                          child: userData.profilePicture != null
                              ? ClipOval(
                                child: Image.network(
                                  userData.profilePicture!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return AvatarInitials(
                                      fullName: userData.fullName,
                                      textStyle: Theme.of(context).textTheme.
                                      titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              )
                              :  AvatarInitials(
                            fullName: userData.fullName,
                            textStyle: Theme.of(context).textTheme.
                            titleSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // User Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // User Name with Role Badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userData.fullName ?? 'User',
                                style: textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Animated Role Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: userData.role == 'manager'
                                      ? [
                                    Pallete.primaryColor,
                                    Pallete.primaryLightColor,
                                  ]
                                      : [
                                    Pallete.successColor,
                                    Pallete.emeraldAccent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: userData.role == 'manager'
                                        ? Pallete.primaryColor.withValues(alpha: 0.3)
                                        : Pallete.successColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    userData.role == 'manager'
                                        ? Icons.admin_panel_settings
                                        : Icons.badge,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    userData.role == 'manager' ? 'MGR' : 'EMP',
                                    style: textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Organization Name with Icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Pallete.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.business,
                                size: 12,
                                color: Pallete.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                userData.organization?.name ?? 'Task Room',
                                style: textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.65),
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : Text(
            'Task Room',
            style: textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            // Notification Icon with Badge
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    size: 26,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    // TODO: Navigate to notifications
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            const SizedBox(width: 12),
                            Text('Notifications coming soon!'),
                          ],
                        ),
                        backgroundColor: Pallete.infoColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                // Notification Badge
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Pallete.errorColor,
                          Pallete.redAccent,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Pallete.errorColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Three Dot Menu
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 22,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              offset: const Offset(0, 55),
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              itemBuilder: (context) => [
                // Profile Menu Item
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Pallete.primaryColor.withValues(alpha: 0.15),
                              Pallete.primaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 20,
                          color: Pallete.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profile',
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'View and edit profile',
                            style: textTheme.bodySmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const PopupMenuDivider(),

                // Logout Menu Item
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Pallete.errorColor.withValues(alpha: 0.15),
                              Pallete.errorColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.logout,
                          size: 20,
                          color: Pallete.errorColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logout',
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Pallete.errorColor,
                            ),
                          ),
                          Text(
                            'Sign out from account',
                            style: textTheme.bodySmall!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'profile':
                    _controller.onProfileTapped();
                    break;
                  case 'logout':
                    _controller.onLogoutTapped();
                    break;
                }
              },
            ),

            const SizedBox(width: 8),
          ],
        ),
        body:
          RefreshIndicator(
            onRefresh: _controller.onRefresh,
            color: Pallete.primaryColor,
            child: AnimatedScreenWrapper(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSearchBar(),
                  _controller.isLoading
                      ? const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
                          ),
                        ),
                      ):
                  Expanded(
                    child: _controller.rooms.isEmpty
                        ? AnimatedScreenWrapper(child: _buildEmptyState())
                        : AnimatedScreenWrapper(child: _buildRoomsList()),
                  )
                ],
              ),
            ),
          ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildRoomsList() {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      controller: _controller.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _controller.rooms.length + 1,
      itemBuilder: (context, index) {
        if (index == _controller.rooms.length) {
          return _buildLoadMoreIndicator();
        }
        final room = _controller.rooms[index];
        return RoomCard(
          room: room,
          onTap: () => _controller.onRoomTapped(room),
          currentUserId: _controller.userData?.id,
          userRole: _controller.userData?.role,
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_controller.isLoadingMore) return const SizedBox(height: 20);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Pallete.primaryColor.withValues(alpha: 0.2),
                      Pallete.primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.meeting_room_outlined,
                  size: 80,
                  color: Pallete.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Rooms Found',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pull down to refresh or try a different search',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _controller.searchController,
        onChanged: _controller.onSearch,
        decoration: InputDecoration(
          hintText: 'Search rooms...',
          prefixIcon: Icon(Icons.search, color: Pallete.primaryColor),
          suffixIcon: _controller.searchController.text.isNotEmpty
              ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _controller.searchController.clear();
                  _controller.onSearch('');
                },
              )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final userData = _controller.userData;
    if (userData == null) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: () {
        _showRoomOptionsDialog(userData);
        // if (isManager) {
        //
        // } else {
        //   _controller.onJoinRoom();
        // }
      },
      backgroundColor: Pallete.primaryColor,
      elevation: 4,
      child: Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

  void _showRoomOptionsDialog(dynamic userData) {
    final isManager = userData.role?.toLowerCase() == 'manager';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Room Actions',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isManager)
              _buildRoomOption(
                icon: Icons.add_circle_outline,
                title: 'Create Room',
                subtitle: 'Create a new task room',
                color: Pallete.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  _controller.onCreateRoom();
                },
              ),
            const Divider(height: 1),
            _buildRoomOption(
              icon: Icons.meeting_room_outlined,
              title: 'Join Room',
              subtitle: 'Join an existing room',
              color: Pallete.successColor,
              onTap: () {
                Navigator.pop(context);
                _controller.onJoinRoom();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}