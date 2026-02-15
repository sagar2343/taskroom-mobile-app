import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/member/controller/member_tab_controller.dart';
import 'package:field_work/features/widgets/avatar_initials.dart';
import 'package:flutter/material.dart';

class MemberTabScreen extends StatefulWidget {
  final String roomId;

  const MemberTabScreen({
    super.key,
    required this.roomId,
  });

  @override
  State<MemberTabScreen> createState() => _MemberTabScreenState();
}

class _MemberTabScreenState extends State<MemberTabScreen> {
  late final MemberTabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MemberTabController(
      context: context,
      roomId: widget.roomId,
      reloadData: reloadData,
    );
    _controller.init();
  }

  void reloadData() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _controller.onRefresh,
        color: Pallete.primaryColor,
        child: _controller.members.isEmpty
            ? _buildEmptyState()
            : _buildMembersList(),
      ),
      floatingActionButton: _controller.isManager
          ? FloatingActionButton.extended(
            onPressed: _controller.onAddMember,
            backgroundColor: Pallete.primaryColor,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Add Member',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          : null,
    );
  }

  Widget _buildMembersList() {
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        // Header with count
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Pallete.primaryColor.withValues(alpha: 0.2),
                        Pallete.primaryColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.people,
                    color: Pallete.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room Members',
                      style: textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_controller.totalMembers} ${_controller.totalMembers == 1 ? "member" : "members"}',
                      style: textTheme.bodySmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Members List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final member = _controller.members[index];
                return _MemberCard(
                  member: member,
                  isManager: _controller.isManager,
                  onRemove: () => _controller.onRemoveMember(member),
                  controller: _controller,
                );
              },
              childCount: _controller.members.length,
            ),
          ),
        ),

        // Bottom padding for FAB
        if (_controller.isManager)
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        physics: const AlwaysScrollableScrollPhysics(),
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
                Icons.people_outline,
                size: 80,
                color: Pallete.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Members Yet',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _controller.isManager
                  ? 'Add members to get started'
                  : 'This room has no members yet',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (_controller.isManager) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _controller.onAddMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Member'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final dynamic member;
  final bool isManager;
  final VoidCallback onRemove;
  final MemberTabController controller;

  const _MemberCard({
    required this.member,
    required this.isManager,
    required this.onRemove,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = member.user;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Pallete.primaryColor.withValues(alpha: 0.08),
            Pallete.primaryColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Pallete.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Hero(
            tag: 'member_${member.id}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Pallete.primaryColor,
                    Pallete.primaryLightColor,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Pallete.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Pallete.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: user?.profilePicture != null
                  ? ClipOval(
                    child: Image.network(
                      user!.profilePicture!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return AvatarInitials(
                          fullName: user.fullName ?? 'U',
                          textStyle: textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  )
                  : AvatarInitials(
                    fullName: user?.fullName ?? 'U',
                    textStyle: textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),

          const SizedBox(width: 16),

          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  user?.fullName ?? 'Unknown User',
                  style: textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Email
                // if (user?.email != null)
                //   Text(
                //     user!.email!,
                //     style: textTheme.bodySmall!.copyWith(
                //       color: Theme.of(context)
                //           .colorScheme
                //           .onSurface
                //           .withValues(alpha: 0.6),
                //     ),
                //     maxLines: 1,
                //     overflow: TextOverflow.ellipsis,
                //   ),

                const SizedBox(height: 8),

                // Role and Status Badges
                Row(
                  children: [
                    _buildRoleBadge(context),
                    const SizedBox(width: 8),
                    _buildStatusBadge(context),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Remove Button (Only for Manager)
          if (isManager)
            IconButton(
              onPressed: onRemove,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Pallete.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_remove,
                  color: Pallete.errorColor,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    final role = controller.getMemberRoleDisplay(member.role);
    Color badgeColor;
    IconData badgeIcon;

    switch (role.toLowerCase()) {
      case 'admin':
        badgeColor = Pallete.primaryColor;
        badgeIcon = Icons.admin_panel_settings;
        break;
      case 'moderator':
        badgeColor = Pallete.warningColor;
        badgeIcon = Icons.shield;
        break;
      default:
        badgeColor = Pallete.successColor;
        badgeIcon = Icons.badge;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            role,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final status = controller.getStatusDisplay(member.status);
    final isActive = status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Pallete.successColor : Pallete.errorColor)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isActive ? Pallete.successColor : Pallete.errorColor)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Pallete.successColor : Pallete.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: isActive ? Pallete.successColor : Pallete.errorColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}