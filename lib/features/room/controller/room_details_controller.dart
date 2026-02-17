import 'package:field_work/config/data/local/app_data.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/helpers.dart';
import '../../home/models/room_model.dart';
import '../data/room_dataSource.dart';
import '../view/screen/create_room_screen.dart';

class RoomDetailController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String roomId;

  final RoomDataSource _roomDataSource = RoomDataSource();

  RoomModel? room;
  bool isLoading = false;
  String? currentUserId;
  String? userRole;


  RoomDetailController({
    required this.context,
    required this.roomId,
    required this.reloadData,
  });

  void init() async {
    final userData = AppData().getUserData();
    currentUserId = userData?.id;
    userRole = userData?.role;
    await getRoomDetail();
  }

  Future<void> getRoomDetail() async {
    isLoading = true;
    reloadData();
    try {
      final response = await _roomDataSource.getRoomDetail(
        roomId: roomId,
      );

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        room = response.data?.room;
      } else {
        Helpers.showSnackBar(
          context,
          response.message ?? 'Failed to load room details',
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint('Get room detail error: $e');
      Helpers.showSnackBar(
        context,
        'Failed to load room details',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  bool get isManager => userRole?.toLowerCase() == 'manager';

  bool canEdit() {
    if (room == null || currentUserId == null) return false;
    final isOwner = room!.createdBy?.id == currentUserId;
    final isManager = userRole?.toLowerCase() == 'manager';
    return isOwner || isManager;
  }

  void onEditRoom() async {
    if (room == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRoomScreen(
          roomToEdit: room,
        ),
      ),
    );
    if (result == true) {
      await getRoomDetail();
    }
  }

  Future<void> onRefresh() async {
    await getRoomDetail();
  }

  void onMembersTab() {
    Helpers.showSnackBar(
      context,
      'Members section coming soon!',
      type: SnackType.normal,
    );
  }

  void onTasksTab() {
    Helpers.showSnackBar(
      context,
      'Tasks section coming soon!',
      type: SnackType.normal,
    );
  }

  Future<void> onArchiveRoom() async {
    if (room == null) return;

    bool isArchived = room!.isArchived ?? false;
    final action = isArchived ? 'unarchive' : 'archive';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(isArchived ? 'Unarchive Room?' : 'Archive Room?'),
        content: Text(
          isArchived
              ? 'Are you sure you want to unarchive "${room!.name}"? This will make the room active again.'
              : 'Are you sure you want to archive "${room!.name}"? Members won\'t be able to access it until unarchived.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isArchived ? Colors.green : Colors.red,
            ),
            child: Text(isArchived ? 'Unarchive' : 'Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      isLoading = true;
      reloadData();

      final response = await _roomDataSource.archiveRoom(
        roomId: roomId,
        isArchive: !isArchived,
      );

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      final successValue = response['success'];
      final isSuccess = successValue == true || successValue == "true";

      if (isSuccess) {
        // Navigate back if room was archived
        if (!isArchived) {
          Navigator.pop(context, true);
        } else {
          await getRoomDetail();
        }
        Helpers.showSnackBar(
          context,
          response['message'] ??
              (isArchived
                  ? 'Room unarchived successfully!'
                  : 'Room archived successfully!'),
          type: SnackType.success,
        );
      } else {
        Helpers.showSnackBar(
          context,
          response['message'] ?? 'Failed to $action room',
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint('Archive room error: $e');
      Helpers.showSnackBar(
        context,
        'Failed to $action room',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}