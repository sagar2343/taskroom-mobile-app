import 'package:field_work/config/data/local/app_data.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/helpers.dart';
import '../data/member_datasource.dart';
import '../model/room_member_response.dart';

class MemberTabController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String roomId;

  bool isLoading = false;
  List<RoomMemberItem> members = [];
  int totalMembers = 0;
  String? userRole;
  String? currentUserId;

  MemberTabController({
    required this.context,
    required this.roomId,
    required this.reloadData,
  });

  void init() async {
    final userData = AppData().getUserData();
    userRole = userData?.role;
    currentUserId = userData?.id;
    await getMembers();
  }

  bool get isManager => userRole?.toLowerCase() == 'manager';

  Future<void> getMembers() async {
    isLoading = true;
    reloadData();
    try {
      final response = await MemberDatasource().getRoomMembers(roomId);
      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        members = response.data?.members ?? [];
        totalMembers = response.data?.totalMembers ?? 0;
      } else {
        Helpers.showSnackBar(
          context,
          'Failed to load members',
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint('Get members error: $e');
      Helpers.showSnackBar(
        context,
        'Failed to load members',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  Future<void> onRefresh() async {
    await getMembers();
  }

  void onAddMember() {
    if (!isManager) return;

    // TODO: Implement add member functionality
    Helpers.showSnackBar(
      context,
      'Add member feature coming soon!',
      type: SnackType.normal,
    );
  }

  void onRemoveMember(RoomMemberItem member) {
    if (!isManager) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.user?.fullName ?? "this member"} from the room?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(RoomMemberItem member) async {
    // TODO: Implement API call to remove member
    Helpers.showSnackBar(
      context,
      'Remove member API coming soon!',
      type: SnackType.normal,
    );

    // After successful removal, refresh the list
    // await getMembers();
  }

  String getMemberRoleDisplay(String? role) {
    if (role == null) return 'Member';
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  String getStatusDisplay(String? status) {
    if (status == null) return 'Active';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }


}