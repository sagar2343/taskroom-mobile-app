import 'dart:io';

import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/home/models/room_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/upload_service.dart';
import '../data/room_dataSource.dart';

class CreateRoomController {
  final BuildContext context;
  final VoidCallback reloadData;
  final RoomModel? roomToEdit; // For edit mode

  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool get isEditMode => roomToEdit != null;

  // Form controllers
  final nameController        = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController    = TextEditingController();
  final maxMembersController  = TextEditingController(text: '50');

  // Room image state
  File?   localRoomImage;         // preview before/after upload
  String? uploadedRoomImageUrl;   // Cloudinary URL after upload
  bool    isUploadingImage = false;
  final _picker = ImagePicker();

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
      uploadedRoomImageUrl       = roomToEdit!.roomImage;
    } else {
      // Set default category for create mode
      categoryController.text = categoryOptions[0];
    }
  }

  /// Pick from gallery, upload to Cloudinary, store URL for save.
  /// For CREATE mode: uploads after the room is created (roomId needed).
  /// For EDIT mode:   uploads immediately using the existing roomId.
  Future<void> pickAndUploadRoomImage() async {
    try {
      final xf = await _picker.pickImage(
        source:       ImageSource.gallery,
        imageQuality: 80,
        maxWidth:     1200,
        maxHeight:    675,   // keeps 16:9 ratio (Cloudinary crops to 800×450)
      );
      if (xf == null) return;

      localRoomImage   = File(xf.path);
      isUploadingImage = true;
      reloadData();

      if (isEditMode && roomToEdit?.id != null) {
        // Edit mode — room already exists, upload immediately
        final url = await UploadService.uploadRoomImage(
          localRoomImage!,
          roomId: roomToEdit!.id!,
        );
        if (url != null) {
          uploadedRoomImageUrl = url;
          if (context.mounted) {
            Helpers.showSnackBar(context, 'Room image updated!', type: SnackType.success);
          }
        } else {
          localRoomImage = null;
          if (context.mounted) {
            Helpers.showSnackBar(context, 'Upload failed. Please try again.', type: SnackType.error);
          }
        }
      }
      // Create mode — just store the local file; upload after room is created
    } catch (e) {
      debugPrint('pickAndUploadRoomImage error: $e');
      localRoomImage = null;
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Could not open image picker.', type: SnackType.error);
      }
    } finally {
      isUploadingImage = false;
      reloadData();
    }
  }

  void removeRoomImage() {
    localRoomImage       = null;
    uploadedRoomImageUrl = isEditMode ? null : uploadedRoomImageUrl;
    reloadData();
  }

  Future<void> handleCreateRoom() async {
    if (!formKey.currentState!.validate()) return;

    isLoading = true;
    reloadData();

    try {
      final response = isEditMode ? await _updateRoom() : await _createRoom();

      if (response == null) {
        Helpers.showSnackBar(context, 'Something went wrong!', type: SnackType.error);
        return;
      }

      if (response.success ?? false) {
        // CREATE mode — if user picked an image, upload it now that we have a roomId
        if (!isEditMode && localRoomImage != null) {
          final newRoomId = response.data?.room?.id;
          if (newRoomId != null) {
            final url = await UploadService.uploadRoomImage(
              localRoomImage!,
              roomId: newRoomId,
            );
            if (url != null) {
              uploadedRoomImageUrl = url;
            }
          }
        }

        if (context.mounted) Navigator.pop(context, true);

        Helpers.showSnackBar(
          context,
          response.message ?? (isEditMode ? 'Room updated!' : 'Room created!'),
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

  /// Helpers
  String _formatCategoryForDropdown(String category) {
    // Capitalize first letter to match dropdown options
    if (category.isEmpty) return categoryOptions[0];
    final formatted = category[0].toUpperCase() + category.substring(1).toLowerCase();
    // Check if it exists in options, otherwise use first option
    return categoryOptions.contains(formatted) ? formatted : categoryOptions[0];
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

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    maxMembersController.dispose();
  }

}