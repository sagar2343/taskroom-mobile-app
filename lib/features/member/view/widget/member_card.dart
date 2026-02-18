import 'package:flutter/material.dart';
import '../../../../config/theme/app_pallete.dart';
import '../../../auth/model/user_model.dart';

class MemberCard extends StatelessWidget {
  final String memberName;
  final String memberRole;
  final UserModel member;
  final VoidCallback onAdd;
  final bool isInRoom;
  final bool isAdding;

  const MemberCard({
    super.key,
    required this.memberName,
    required this.memberRole,
    required this.member,
    required this.onAdd,
    this.isInRoom = false,
    this.isAdding = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOnline = member.isOnline ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isInRoom
              ? [
            // Green gradient if already in room
            Pallete.successColor.withValues(alpha: 0.1),
            Pallete.successColor.withValues(alpha: 0.05),
          ]
              : [
            // Blue gradient if not in room
            Pallete.primaryColor.withValues(alpha: 0.08),
            Pallete.primaryColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInRoom
              ? Pallete.successColor.withValues(alpha: 0.3)
              : Pallete.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isInRoom
                        ? [
                      Pallete.successColor,
                      Pallete.successColor.withValues(alpha: 0.7),
                    ]
                        : [
                      Pallete.primaryColor,
                      Pallete.primaryLightColor,
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isInRoom
                        ? Pallete.successColor.withValues(alpha: 0.3)
                        : Pallete.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isInRoom
                          ? Pallete.successColor.withValues(alpha: 0.3)
                          : Pallete.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: member.profilePicture != null
                    ? ClipOval(
                      child: Image.network(
                        member.profilePicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              memberName,
                              style: textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    : Center(
                      child: Text(
                        memberName,
                        style: textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
              // Online indicator
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isOnline ? Pallete.successColor : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.fullName ?? 'Unknown',
                        style: textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    _buildActionButton(context),
                  ],
                ),
                const SizedBox(height: 4),

                // Email
                if (member.email != null)
                  Text(
                    member.email!,
                    style: textTheme.bodySmall!.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 8),

                // Role, Department, Designation
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildRoleBadge(context),
                    if (member.department != null)
                      _buildInfoChip(context, member.department!),
                    if (member.designation != null)
                      _buildInfoChip(context, member.designation!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {

    final badgeColor = memberRole.toLowerCase() == 'manager'
        ? Pallete.primaryColor
        : Pallete.successColor;

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
            memberRole.toLowerCase() == 'manager'
                ? Icons.admin_panel_settings
                : Icons.badge,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            memberRole,
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

  Widget _buildActionButton(BuildContext context) {
    if (isInRoom) {
      // Already in room - show checkmark
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Pallete.successColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Pallete.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: Pallete.successColor,
            ),
            const SizedBox(width: 4),
            Text(
              'ADDED',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Pallete.successColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    if (isAdding) {
      // Currently adding - show loading
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Pallete.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Pallete.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Pallete.primaryColor),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'ADDING',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Pallete.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Can add - show add button
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Pallete.primaryColor),
          borderRadius: BorderRadius.circular(10),
          color: Pallete.primaryColor.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 16,
              color: Pallete.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              'ADD',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Pallete.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
