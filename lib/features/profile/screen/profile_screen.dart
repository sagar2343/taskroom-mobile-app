import 'package:field_work/features/profile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:field_work/config/theme/app_pallete.dart';

import '../../widgets/icon_box_header.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    _controller = ProfileController(context: context, reloadData: reloadData);
    super.initState();
    _controller.init();
  }

  void reloadData() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
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
          'Profile',
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
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
                Icons.edit_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onPressed: _controller.navigateToEditScreen,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _controller.isLoading
          ? Center(child: CircularProgressIndicator())
          :
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card with Organization
            _buildProfileHeaderCard(context),

            const SizedBox(height: 24),

            // Contact Information Section
            IconBoxHeader(
              icon: Icons.contact_phone,
              title: 'Contact Information',
            ),

            const SizedBox(height: 12),

            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _controller.userData?.email ?? 'Not provided',
              color: Pallete.infoColor,
            ),

            const SizedBox(height: 12),

            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Mobile',
              value: _controller.userData?.mobile ?? 'Not provided',
              color: Pallete.successColor,
            ),

            const SizedBox(height: 24),

            // Work Information Section
            IconBoxHeader(
              icon: Icons.work_outline,
              title: 'Work Information',
            ),

            const SizedBox(height: 12),

            if (_controller.userData?.employeeId != null)
              _InfoTile(
                icon: Icons.badge_outlined,
                label: 'Employee ID',
                value: _controller.userData!.employeeId!,
                color: Pallete.primaryColor,
              ),

            if (_controller.userData?.managerId != null)
              _InfoTile(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Manager ID',
                value: _controller.userData!.managerId!,
                color: Pallete.primaryColor,
              ),

            const SizedBox(height: 12),

            _InfoTile(
              icon: Icons.business_center_outlined,
              label: 'Department',
              value: _controller.userData!.department ?? 'Not specified',
              color: Pallete.warningColor,
            ),

            const SizedBox(height: 12),

            _InfoTile(
              icon: Icons.work_history_outlined,
              label: 'Designation',
              value: _controller.userData!.designation ?? 'Not specified',
              color: Pallete.orangeAccent,
            ),

            const SizedBox(height: 24),

            // Location Information (if available)
            if (_controller.userData?.currentLocation != null) ...[
              IconBoxHeader(
                icon: Icons.location_on_outlined,
                title: 'Current Location',
              ),

              const SizedBox(height: 12),

              _buildLocationCard(context),

              const SizedBox(height: 24),
            ],

            // Account Status Section
            IconBoxHeader(
              icon: Icons.info_outline,
              title: 'Account Status',
            ),

            const SizedBox(height: 12),

            _buildStatusCard(context),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _controller.navigateToEditScreen,
                    icon: Icon(Icons.edit, size: 20),
                    label: Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallete.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Settings coming soon!'),
                          backgroundColor: Pallete.infoColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.settings, size: 20),
                    label: Text('Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Pallete.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Pallete.primaryColor,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Pallete.primaryColor.withValues(alpha: 0.15),
            Pallete.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Pallete.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Pallete.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Hero(
              tag: 'avatar',
              child: Container(
                width: 100,
                height: 100,
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
                    width: 3,
                  ),
                ),
                child: _controller.userData?.profilePicture != null
                    ? ClipOval(
                      child: Image.network(
                        _controller.userData?.profilePicture ?? "",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarInitials();
                        },
                      ),
                    )
                    : _buildAvatarInitials(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Full Name
          Text(
            _controller.userData?.fullName ?? 'User',
            style: textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // Username
          Text(
            '@${_controller.userData?.username ?? 'username'}',
            style: textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),

          const SizedBox(height: 16),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _controller.userData?.role == 'manager'
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _controller.userData?.role == 'manager'
                      ? Pallete.primaryColor.withValues(alpha: 0.4)
                      : Pallete.successColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _controller.userData?.role == 'manager'
                      ? Icons.admin_panel_settings
                      : Icons.badge,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _controller.userData?.role == 'manager' ? 'Manager' : 'Employee',
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Divider(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.1),
          ),

          const SizedBox(height: 16),

          // Organization Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
                  Icons.business,
                  size: 20,
                  color: Pallete.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organization',
                      style: textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _controller.userData?.organization?.name ?? 'Not assigned',
                      style: textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarInitials() {
    String initials = 'U';
    if (_controller.userData != null && _controller.userData?.fullName != null &&
        _controller.userData!.fullName!.isNotEmpty) {
      final names = _controller.userData?.fullName!.trim().split(' ');
      if (names!.length >= 2) {
        initials = '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        initials = names[0][0].toUpperCase();
      }
    }

    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    final location = _controller.userData?.currentLocation!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Pallete.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Pallete.infoColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Address',
                      style: textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location?.address ?? 'Location not available',
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (location?.lastUpdated != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Updated ${_formatDateTime(location!.lastUpdated!)}',
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
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOnline = _controller.userData?.isOnline ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Pallete.successColor.withValues(alpha: 0.1)
                      : Pallete.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? Pallete.successColor : Pallete.errorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline
                                ? Pallete.successColor
                                : Pallete.errorColor)
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isOnline ? Pallete.successColor : Pallete.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_controller.userData?.createdAt != null) ...[
            const SizedBox(height: 16),
            Divider(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Member Since',
                      style: textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (_controller.userData != null)
                      Text(
                        _formatDate(_controller.userData!.createdAt!),
                        style: textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Reusable Icon Box Header Component
// class _IconBoxHeader extends StatelessWidget {
//   final IconData icon;
//   final String title;
//
//   const _IconBoxHeader({
//     required this.icon,
//     required this.title,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [
//                 Pallete.primaryColor.withValues(alpha: 0.2),
//                 Pallete.primaryColor.withValues(alpha: 0.1),
//               ],
//             ),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(
//             icon,
//             size: 22,
//             color: Pallete.primaryColor,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Text(
//           title,
//           style: Theme.of(context).textTheme.titleMedium!.copyWith(
//             fontWeight: FontWeight.w700,
//             color: Theme.of(context).colorScheme.onSurface,
//           ),
//         ),
//       ],
//     );
//   }
// }

// Reusable Info Tile Component
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}