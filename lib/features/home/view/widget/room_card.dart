import 'package:flutter/material.dart';
import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/home/models/room_model.dart';
import '../../../../core/utils/helpers.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final String? currentUserId;
  final String? userRole;
  final RoomTaskSummary? taskSummary;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.currentUserId,
    this.userRole,
    this.taskSummary,
  });

  // ── Derived helpers ────────────────────────────────────────────────────────

  bool get _hasActiveTasks => taskSummary != null && taskSummary!.hasActiveTasks;

  /// Border / accent colour driven by the single highest-priority status.
  Color get _accentColor {
    if (taskSummary == null) return Pallete.primaryColor;
    switch (taskSummary!.primaryStatus) {
      case TaskBannerStatus.overdue:    return Pallete.errorColor;
      case TaskBannerStatus.inProgress: return Pallete.successColor;
      case TaskBannerStatus.pending:    return Pallete.warningColor;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme  = Theme.of(context).textTheme;
    final roleInRoom = _getUserRoleInRoom();

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
                colors: !(room.isArchived ?? false)
                    ? [
                  Pallete.primaryColor.withValues(alpha: 0.1),
                  Pallete.primaryColor.withValues(alpha: 0.05),
                ]
                    : [Colors.grey.shade300, Colors.grey.shade200],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hasActiveTasks
                    ? _accentColor.withValues(alpha: 0.45)
                    : Pallete.primaryColor.withValues(alpha: 0.2),
                width: _hasActiveTasks ? 1.8 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────────
                Row(
                  children: [
                    _buildRoomIcon(),
                    const SizedBox(width: 12),
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
                              if (roleInRoom != null) ...[
                                const SizedBox(width: 8),
                                _buildRoleBadge(roleInRoom, textTheme),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (room.category != null)
                                _buildInfoChip(context, Icons.category_outlined,
                                    room.category!, Pallete.infoColor),
                              if (room.roomCode != null)
                                _buildInfoChip(context, Icons.numbers,
                                    room.roomCode!, Pallete.infoColor),
                              _buildStatusIndicator(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Description ───────────────────────────────────────────────
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

                // ── Task status banner — single chip, one status only ──────────
                if (_hasActiveTasks) ...[
                  _buildTaskBanner(context),
                  const SizedBox(height: 10),
                ],

                // ── Room stats (manager / owner) ──────────────────────────────
                if (_canViewStats()) _buildStatsRow(context, textTheme),
                if (_canViewStats()) const SizedBox(height: 10),

                // ── Footer ─────────────────────────────────────────────────────
                _buildFooter(context, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Task Banner ─────────────────────────────────────────────────────────────
  //
  // Shows EXACTLY ONE chip reflecting the single highest-priority status:
  //   overdue    → red,    warning icon
  //   inProgress → green,  play icon
  //   pending    → orange, clock icon
  //
  // The count shown is the number of tasks in that bucket only.

  Widget _buildTaskBanner(BuildContext context) {
    final s = taskSummary!;

    final IconData icon;
    final Color    color;
    final String   label;

    switch (s.primaryStatus) {
      case TaskBannerStatus.overdue:
        icon  = Icons.warning_amber_rounded;
        color = Pallete.errorColor;
        label = s.overdue == 1 ? '1 task overdue' : '${s.overdue} tasks overdue';
        break;

      case TaskBannerStatus.inProgress:
        icon  = Icons.play_circle_fill_rounded;
        color = Pallete.successColor;
        label = s.inProgress == 1
            ? '1 task in progress'
            : '${s.inProgress} tasks in progress';
        break;

      case TaskBannerStatus.pending:
        icon  = Icons.access_time_rounded;
        color = Pallete.warningColor;
        label = s.pending == 1 ? '1 task pending' : '${s.pending} tasks pending';
        break;
    }

    final isOverdue = s.primaryStatus == TaskBannerStatus.overdue;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: isOverdue ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(
          color: color.withValues(alpha: isOverdue ? 0.45 : 0.30),
          width: isOverdue ? 1.3 : 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color:       color,
              fontWeight:  isOverdue ? FontWeight.w800 : FontWeight.w700,
              fontSize:    12,
              letterSpacing: 0.1,
            ),
          ),
          // Show total alongside when there are tasks in other buckets too,
          // so the user knows the full scope without multiple chips.
          if (s.total > s.primaryCount) ...[
            const Spacer(),
            Text(
              '${s.total} total',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color:    color.withValues(alpha: 0.65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Room icon ──────────────────────────────────────────────────────────────

  Widget _buildRoomIcon() {
    return Container(
      width:   50,
      height:  50,
      padding: room.roomImage != null ? null : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Pallete.primaryColor, Pallete.primaryLightColor],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Pallete.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: room.roomImage != null
          ? Hero(
        tag: 'room_${room.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            room.roomImage!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Helpers.getRoomIcon(room.category, room.isArchived),
              color: Colors.white,
              size:  24,
            ),
          ),
        ),
      )
          : Icon(
        Helpers.getRoomIcon(room.category, room.isArchived),
        color: Colors.white,
        size:  24,
      ),
    );
  }

  // ── Info chip (category / room code) ──────────────────────────────────────

  Widget _buildInfoChip(
      BuildContext context, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color:      color,
              fontWeight: FontWeight.w600,
              fontSize:   11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Role badge ─────────────────────────────────────────────────────────────

  Widget _buildRoleBadge(String role, TextTheme textTheme) {
    Color    badgeColor;
    IconData badgeIcon;
    String   badgeText;

    switch (role.toLowerCase()) {
      case 'owner':
        badgeColor = Pallete.warningColor;
        badgeIcon  = Icons.star;
        badgeText  = 'Owner';
        break;
      case 'admin':
        badgeColor = Pallete.primaryColor;
        badgeIcon  = Icons.admin_panel_settings;
        badgeText  = 'Admin';
        break;
      case 'member':
        badgeColor = Pallete.successColor;
        badgeIcon  = Icons.badge;
        badgeText  = 'Member';
        break;
      default:
        badgeColor = Pallete.infoColor;
        badgeIcon  = Icons.info_outline;
        badgeText  = role;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [badgeColor, badgeColor.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:      badgeColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: textTheme.bodySmall!.copyWith(
              fontWeight:    FontWeight.w800,
              color:         Colors.white,
              fontSize:      9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Active / archived status pill ─────────────────────────────────────────

  Widget _buildStatusIndicator(BuildContext context) {
    final isArchived = room.isArchived ?? false;
    final isActive   = room.settings?.isActive ?? false;

    if (isArchived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:        Pallete.errorColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: Pallete.errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.archive, size: 12, color: Pallete.errorColor),
            const SizedBox(width: 4),
            Text(
              'ARCHIVED',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color:      Pallete.errorColor,
                fontWeight: FontWeight.w700,
                fontSize:   9,
              ),
            ),
          ],
        ),
      );
    }

    final statusColor = isActive ? Pallete.successColor : Pallete.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color:  statusColor,
              shape:  BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:       statusColor.withValues(alpha: 0.5),
                  blurRadius:  4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color:         statusColor,
              fontWeight:    FontWeight.w700,
              fontSize:      9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row (manager / owner only) ──────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem(context, Icons.people_outline,
              '${room.stats!.totalMembers ?? 0}', 'Members', Pallete.primaryColor),
          const SizedBox(width: 16),
          Container(
            width: 1, height: 30,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          _buildStatItem(context, Icons.task_alt,
              '${room.stats!.activeTasks ?? 0}', 'Active', Pallete.successColor),
          const SizedBox(width: 16),
          Container(
            width: 1, height: 30,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          _buildStatItem(context, Icons.check_circle_outline,
              '${room.stats!.completedTasks ?? 0}', 'Done', Pallete.infoColor),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value,
      String label, Color color) {
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
                  color:      color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 10,
              color:    Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext context, TextTheme textTheme) {
    return Row(
      children: [
        if (room.createdBy != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:        Pallete.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person_outline, size: 14, color: Pallete.primaryColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              room.createdBy!.fullName ?? 'Unknown',
              style: textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w600,
                color:      Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:        Pallete.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_forward_ios, size: 14, color: Pallete.primaryColor),
        ),
      ],
    );
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  String? _getUserRoleInRoom() {
    if (currentUserId == null) return null;
    if (room.createdBy?.id == currentUserId) return 'Owner';
    if (room.members != null) {
      for (final member in room.members!) {
        if (member.user?.id == currentUserId ||
            member.userId   == currentUserId) {
          return member.role ?? 'Member';
        }
      }
    }
    return null;
  }

  bool _canViewStats() {
    if (room.stats == null) return false;
    final isOwner   = currentUserId != null && room.createdBy?.id == currentUserId;
    final isManager = userRole?.toLowerCase() == 'manager';
    return isOwner || isManager;
  }
}