import 'package:flutter/material.dart';
import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/home/models/room_model.dart';

import '../../../../core/utils/helpers.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final String? currentUserId;
  final String? userRole; // 'manager' or 'employee'

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.currentUserId,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final userRole = _getUserRoleInRoom();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: !(room.isArchived ?? false) ? [
                  Pallete.primaryColor.withValues(alpha: 0.1),
                  Pallete.primaryColor.withValues(alpha: 0.05),
                ] : [
                  Colors.grey.shade300,
                  Colors.grey.shade200
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Pallete.primaryColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Room Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Pallete.primaryColor,
                            Pallete.primaryLightColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Pallete.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Helpers.getRoomIcon(room.category, room.isArchived),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Room Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  room.name ?? 'Untitled Room',
                                  style: textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (userRole != null) ...[
                                const SizedBox(width: 8),
                                _buildRoleBadge(userRole, textTheme),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (room.category != null) ...[
                                // const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Pallete.infoColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Pallete.infoColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 10,
                                        color: Pallete.infoColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        room.category!,
                                        style: textTheme.bodySmall!.copyWith(
                                          color: Pallete.infoColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (room.roomCode != null) ...[
                                // const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Pallete.infoColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Pallete.infoColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.numbers,
                                        size: 10,
                                        color: Pallete.infoColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        room.roomCode!,
                                        style: textTheme.bodySmall!.copyWith(
                                          color: Pallete.infoColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Active Status
                              _buildStatusIndicator(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (room.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    room.description!,
                    style: textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Stats Row - Only visible to Owner or Manager
                if (_canViewStats()) _buildStatsRow(context, textTheme),

                if (_canViewStats()) const SizedBox(height: 10),

                // Footer Row
                Row(
                  children: [
                    // Creator Info
                    if (room.createdBy != null) ...[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Pallete.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Pallete.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          room.createdBy!.fullName ?? 'Unknown',
                          style: textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Arrow Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Pallete.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Pallete.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, TextTheme textTheme) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (role.toLowerCase()) {
      case 'owner':
        badgeColor = Pallete.warningColor;
        badgeIcon = Icons.star;
        badgeText = 'Owner';
        break;
      case 'admin':
        badgeColor = Pallete.primaryColor;
        badgeIcon = Icons.admin_panel_settings;
        badgeText = 'Admin';
        break;
      case 'member':
        badgeColor = Pallete.successColor;
        badgeIcon = Icons.badge;
        badgeText = 'Member';
        break;
      default:
        badgeColor = Pallete.infoColor;
        badgeIcon = Icons.info_outline;
        badgeText = role;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final isActive = room.settings?.isActive ?? false;
    final isArchived = room.isArchived ?? false;

    if (isArchived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Pallete.errorColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Pallete.errorColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.archive,
              size: 12,
              color: Pallete.errorColor,
            ),
            const SizedBox(width: 4),
            Text(
              'ARCHIVED',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Pallete.errorColor,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive ? Pallete.successColor : Pallete.errorColor)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
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
              boxShadow: [
                BoxShadow(
                  color: (isActive ? Pallete.successColor : Pallete.errorColor)
                      .withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: isActive ? Pallete.successColor : Pallete.errorColor,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem(
            context,
            Icons.people_outline,
            '${room.stats!.totalMembers ?? 0}',
            'Members',
            Pallete.primaryColor,
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 30,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            context,
            Icons.task_alt,
            '${room.stats!.activeTasks ?? 0}',
            'Active',
            Pallete.successColor,
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 30,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          _buildStatItem(
            context,
            Icons.check_circle_outline,
            '${room.stats!.completedTasks ?? 0}',
            'Done',
            Pallete.infoColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      Color color,
      ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 10,
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

  String? _getUserRoleInRoom() {
    if (currentUserId == null) return null;

    // Check if user is the creator (owner)
    if (room.createdBy?.id == currentUserId) {
      return 'Owner';
    }

    // Check members list for user's role
    if (room.members != null) {
      for (var member in room.members!) {
        if (member.user == currentUserId) {
          return member.role ?? 'Member';
        }
      }
    }

    return null;
  }

  /// Check if user can view stats (only owner or manager)
  bool _canViewStats() {
    if (room.stats == null) return false;

    // Check if user is the owner (created the room)
    final isOwner = currentUserId != null &&
        room.createdBy?.id == currentUserId;

    // Check if user is a manager
    final isManager = userRole?.toLowerCase() == 'manager';

    return isOwner || isManager;
  }
}