import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/home/models/room_model.dart';
import 'package:field_work/features/widgets/icon_box_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverviewTabScreen extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onRefresh;
  final String Function(DateTime) formatDate;

  const OverviewTabScreen({
    super.key,
    required this.room,
    required this.onRefresh,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: Pallete.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Details Header
            _buildRoomHeader(context),

            // Stats Section
            if (room.stats != null) _buildStatsSection(context),

            // Room Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBoxHeader(
                    icon: Icons.settings_outlined,
                    title: 'Room Settings',
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    Icons.people_outline,
                    'Maximum Members',
                    '${room.settings?.maxMembers ?? 0}',
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    context,
                    Icons.person_add_outlined,
                    'Auto Accept Members',
                    (room.settings?.autoAcceptMembers ?? false)
                        ? 'Enabled'
                        : 'Disabled',
                    color: (room.settings?.autoAcceptMembers ?? false)
                        ? Pallete.successColor
                        : Pallete.errorColor,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    context,
                    Icons.visibility_outlined,
                    'Members Can See Each Other',
                    (room.settings?.allowMembersToSeeEachOther ?? false)
                        ? 'Enabled'
                        : 'Disabled',
                    color: (room.settings?.allowMembersToSeeEachOther ?? false)
                        ? Pallete.successColor
                        : Pallete.errorColor,
                  ),
                  const SizedBox(height: 24),
                  IconBoxHeader(
                    icon: Icons.info_outline,
                    title: 'Additional Information',
                  ),
                  const SizedBox(height: 16),
                  if (room.createdBy != null)
                    _buildInfoItem(
                      context,
                      Icons.person_outline,
                      'Created by',
                      room.createdBy!.fullName ?? 'Unknown',
                    ),
                  if (room.createdAt != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      context,
                      Icons.calendar_today,
                      'Created',
                      formatDate(room.createdAt!),
                    ),
                  ],
                  if (room.updatedAt != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      context,
                      Icons.update,
                      'Last Updated',
                      formatDate(room.updatedAt!),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Pallete.primaryColor.withValues(alpha: 0.15),
            Pallete.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Room Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Pallete.primaryColor,
                  Pallete.primaryLightColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Pallete.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Helpers.getRoomIcon(room.category, room.isArchived),
              size: 48,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // Room Name
          Text(
            room.name ?? 'Untitled Room',
            style: textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (room.category != null) ...[
                _buildCategoryBadge(context),
                const SizedBox(width: 8),
              ],
              _buildStatusBadge(context),
            ],
          ),

          if (room.description != null) ...[
            const SizedBox(height: 16),
            Text(
              room.description!,
              style: textTheme.bodyMedium!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          // Room Code
          if (room.roomCode != null) _buildRoomCode(context),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Pallete.infoColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Pallete.infoColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_outlined,
            size: 14,
            color: Pallete.infoColor,
          ),
          const SizedBox(width: 4),
          Text(
            room.category!,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Pallete.infoColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final isActive = room.settings?.isActive ?? false;
    final isArchived = room.isArchived ?? false;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isArchived) {
      statusColor = Pallete.errorColor;
      statusText = 'ARCHIVED';
      statusIcon = Icons.archive;
    } else if (isActive) {
      statusColor = Pallete.successColor;
      statusText = 'ACTIVE';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Pallete.errorColor;
      statusText = 'INACTIVE';
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCode(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Pallete.successColor.withValues(alpha: 0.15),
            Pallete.successColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Pallete.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code,
            color: Pallete.successColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            room.roomCode!,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Pallete.successColor,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: room.roomCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Room code copied!'),
                    ],
                  ),
                  backgroundColor: Pallete.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Pallete.successColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.copy,
                size: 16,
                color: Pallete.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final stats = room.stats!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            _buildStatItem(
              context,
              Icons.people_outline,
              '${stats.totalMembers ?? 0}',
              'Members',
              Pallete.primaryColor,
            ),
            const SizedBox(width: 20),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(width: 20),
            _buildStatItem(
              context,
              Icons.task_alt,
              '${stats.activeTasks ?? 0}',
              'Active',
              Pallete.warningColor,
            ),
            const SizedBox(width: 20),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(width: 20),
            _buildStatItem(
              context,
              Icons.check_circle_outline,
              '${stats.completedTasks ?? 0}',
              'Done',
              Pallete.successColor,
            ),
          ],
        ),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
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

  Widget _buildSettingItem(
      BuildContext context,
      IconData icon,
      String title,
      String value, {
        Color? color,
      }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (color ?? Pallete.primaryColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color ?? Pallete.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: color ?? Pallete.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context,
      IconData icon,
      String label,
      String value,
      ) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: textTheme.bodyMedium!.copyWith(
            color:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}