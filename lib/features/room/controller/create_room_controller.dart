import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/home/models/room_model.dart';
import 'package:flutter/material.dart';

import '../data/room_dataSource.dart';

class CreateRoomController {
  final BuildContext context;
  final VoidCallback reloadData;
  final RoomModel? roomToEdit; // For edit mode

  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool get isEditMode => roomToEdit != null;

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController maxMembersController = TextEditingController(text: '50');

  // Settings
  bool autoAcceptMembers = true;
  bool allowMembersToSeeEachOther = true;

  // Category options
  final List<String> categoryOptions =
  ['It', 'Sales', 'Delivery', 'Inspection', 'Survey', 'Maintenance', 'Other'];

  CreateRoomController({
    required this.context,
    required this.reloadData,
    this.roomToEdit,
  });

  void init() {
    if (isEditMode) {
      // Pre-fill form with existing room data
      nameController.text = roomToEdit!.name ?? '';
      descriptionController.text = roomToEdit!.description ?? '';
      categoryController.text = _formatCategoryForDropdown(roomToEdit!.category ?? '');
      maxMembersController.text = '${roomToEdit!.settings?.maxMembers ?? 50}';
      autoAcceptMembers = roomToEdit!.settings?.autoAcceptMembers ?? true;
      allowMembersToSeeEachOther = roomToEdit!.settings?.allowMembersToSeeEachOther ?? true;
    } else {
      // Set default category for create mode
      categoryController.text = categoryOptions[0];
    }
  }

  String _formatCategoryForDropdown(String category) {
    // Capitalize first letter to match dropdown options
    if (category.isEmpty) return categoryOptions[0];
    final formatted = category[0].toUpperCase() + category.substring(1).toLowerCase();
    // Check if it exists in options, otherwise use first option
    return categoryOptions.contains(formatted) ? formatted : categoryOptions[0];
  }

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    maxMembersController.dispose();
  }

  void onAutoAcceptChanged(bool value) {
    autoAcceptMembers = value;
    reloadData();
  }

  void onAllowMembersToSeeEachOtherChanged(bool value) {
    allowMembersToSeeEachOther = value;
    reloadData();
  }

  void onCategoryChanged(String? value) {
    if (value != null) {
      categoryController.text = value;
      reloadData();
    }
  }

  Future<void> handleCreateRoom() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading = true;
    reloadData();

    try {
      final response = isEditMode
          ? await _updateRoom()
          : await _createRoom();

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        if (context.mounted) {
          Navigator.pop(context, true);
        }

        Helpers.showSnackBar(
          context,
          response.message ?? (isEditMode ? 'Room updated successfully!' : 'Room created successfully!'),
          type: SnackType.success,
        );
      } else {
        Helpers.showSnackBar(
          context,
          response.message ?? (isEditMode ? 'Failed to update room' : 'Failed to create room'),
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint('${isEditMode ? "Update" : "Create"} room error: $e');
      Helpers.showSnackBar(
        context,
        'Failed to ${isEditMode ? "update" : "create"} room. Please try again.',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  Future<dynamic> _createRoom() async {
    return await RoomDataSource().createRoom(
      name: nameController.text.trim(),
      desc: descriptionController.text.trim(),
      category: categoryController.text.trim().toLowerCase(),
      autoAcceptMember: autoAcceptMembers,
      allowMembersToSeeEachOther: allowMembersToSeeEachOther,
      maxMembers: int.parse(maxMembersController.text.trim()),
    );
  }

  Future<dynamic> _updateRoom() async {
    return await RoomDataSource().updateRoom(
      roomId: roomToEdit!.id!,
      name: nameController.text.trim(),
      desc: descriptionController.text.trim(),
      category: categoryController.text.trim().toLowerCase(),
      autoAcceptMember: autoAcceptMembers,
      allowMembersToSeeEachOther: allowMembersToSeeEachOther,
      maxMembers: int.parse(maxMembersController.text.trim()),
    );
  }
}