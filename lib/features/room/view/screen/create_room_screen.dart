import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/home/models/room_model.dart';
import 'package:field_work/features/room/controller/create_room_controller.dart';
import 'package:field_work/features/widgets/custom_textfield.dart';
import 'package:field_work/features/widgets/icon_box_header.dart';
import 'package:flutter/material.dart';

class CreateRoomScreen extends StatefulWidget {
  final RoomModel? roomToEdit;
  const CreateRoomScreen({super.key, this.roomToEdit});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  late CreateRoomController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateRoomController(
      context: context,
      reloadData: reloadData,
      roomToEdit: widget.roomToEdit
    );
    _controller.init();
  }

  void reloadData() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          _controller.isEditMode ? 'Edit Room' : 'Create Room',
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Pallete.primaryColor.withValues(alpha: 0.2),
                        Pallete.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
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
                          color: Pallete.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // Basic Information
              IconBoxHeader(
                icon: Icons.info_outline,
                title: 'Basic Information',
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.nameController,
                label: 'Room Name',
                hint: 'Enter room name',
                prefixIcon: Icons.meeting_room,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Room name is required';
                  }
                  if (value.length < 3) {
                    return 'Room name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.descriptionController,
                label: 'Description',
                hint: 'Enter room description',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _CategoryDropdown(
                controller: _controller,
                onChanged: _controller.onCategoryChanged,
              ),

              const SizedBox(height: 24),

              // Room Settings
              IconBoxHeader(
                icon: Icons.settings_outlined,
                title: 'Room Settings',
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.maxMembersController,
                label: 'Maximum Members',
                hint: 'Enter max members',
                prefixIcon: Icons.people_outline,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Max members is required';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1) {
                    return 'Enter a valid number (min: 1)';
                  }
                  if (number > 1000) {
                    return 'Maximum limit is 1000';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              _SettingSwitch(
                title: 'Auto Accept Members',
                subtitle: 'Automatically accept join requests',
                value: _controller.autoAcceptMembers,
                onChanged: _controller.onAutoAcceptChanged,
                icon: Icons.person_add_outlined,
              ),

              const SizedBox(height: 12),

              _SettingSwitch(
                title: 'Members Can See Each Other',
                subtitle: 'Allow members to view other members',
                value: _controller.allowMembersToSeeEachOther,
                onChanged: _controller.onAllowMembersToSeeEachOtherChanged,
                icon: Icons.visibility_outlined,
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _controller.isLoading
                      ? null
                      : _controller.handleCreateRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.primaryColor,
                    disabledBackgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _controller.isLoading
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_controller.isEditMode ? Icons.check_circle : Icons.add_circle, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _controller.isEditMode ? 'Update Room' : 'Create Room',
                            style: textTheme.bodyLarge!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}


class _CategoryDropdown extends StatelessWidget {
  final CreateRoomController controller;
  final void Function(String?) onChanged;

  const _CategoryDropdown({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.categoryController.text.isNotEmpty
              ? controller.categoryController.text
              : null,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Select category',
            prefixIcon: Icon(
              Icons.category_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              size: 22,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Pallete.primaryColor,
                width: 2,
              ),
            ),
          ),
          items: controller.categoryOptions
              .map((category) => DropdownMenuItem(
            value: category,
            child: Text(category),
          ))
              .toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;
  final IconData icon;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Pallete.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Pallete.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall!.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Pallete.primaryColor,
          ),
        ],
      ),
    );
  }
}