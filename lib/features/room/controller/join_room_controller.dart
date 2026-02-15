import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/room/data/room_datasource.dart';
import 'package:flutter/material.dart';

class JoinRoomController {
  final BuildContext context;
  final VoidCallback reloadData;

  final formKey = GlobalKey<FormState>();
  final TextEditingController roomCodeController = TextEditingController();
  bool isLoading = false;

  JoinRoomController({
    required this.context,
    required this.reloadData,
  });

  void dispose() {
    roomCodeController.dispose();
  }

  Future<void> handleJoinRoom() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading = true;
    reloadData();

    try {
      final response = await RoomDataSource().joinRoom(
        roomCode: roomCodeController.text.trim().toUpperCase(),
      );

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      final success = response['success'] ?? false;
      final message = response['message'] ?? '';

      if (success) {
        // Navigate back with success
        if (context.mounted) {
          Navigator.pop(context, true);
        }

        Helpers.showSnackBar(
          context,
          message.isNotEmpty ? message : 'Successfully joined room!',
          type: SnackType.success,
        );
      } else {
        Helpers.showSnackBar(
          context,
          message ?? 'Failed to join room',
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint('Join room error: $e');
      Helpers.showSnackBar(
        context,
        'Failed to join room. Please try again.',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }
}