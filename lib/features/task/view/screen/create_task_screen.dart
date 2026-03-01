import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/member/model/room_member_response.dart';
import 'package:field_work/features/task/controller/create_task_controller.dart';
import 'package:field_work/features/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import '../../model/task_form_models.dart';

class CreateTaskScreen extends StatefulWidget {
  final String roomId;
  final String roomName;
  final VoidCallback? onTaskCreated;

  const CreateTaskScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    this.onTaskCreated,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  late final CreateTaskController _controller;
  static const _kGreen = Color(0xFF10B981);

  @override
  void initState() {
    _controller = CreateTaskController(
      context: context,
      reloadData: reloadData,
      roomId: widget.roomId,
      onCreated: widget.onTaskCreated,
    );
    super.initState();
    _controller.init();
  }

  void reloadData() { if (mounted) setState(() {});}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Task Details
                  SliverToBoxAdapter(child: _buildCard(
                    icon: Icons.assignment_rounded,
                    title: 'Task Details',
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Title
                        _formLbl('TITLE *'),
                        CustomTextField(
                          controller: _controller.titleCtrl,
                          hint: 'e.g. Deliver Order #204 to Site C',
                          // label: 'Title',
                          // isDark: isDark,
                        ),

                        const SizedBox(height: 14),

                        // Note
                        _formLbl('NOTE'),
                        CustomTextField(
                          controller: _controller.noteCtrl,
                          hint: 'Extra instructions for the employee...',
                          // label: 'NOTE',
                          // isDark: isDark,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 16),

                        // Priority
                        _formLbl('PRIORITY'),
                        Row(
                          children: [
                            for (final p in ['low', 'medium', 'high'])
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: p != 'high' ? 8 : 0),
                                  child: _PriorityBtn(
                                    label: p[0].toUpperCase() + p.substring(1),
                                    value: p,
                                    selected: _controller.priority == p,
                                    onTap: () {
                                      _controller.priority = p;
                                      reloadData();
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Schedule
                        _formLbl('SCHEDULE *'),
                        Row(
                          children: [
                            Expanded(
                              child: _dateBtn(
                                'START',
                                _controller.formatDt(_controller.startDatetime),
                                _controller.startDatetime != null,
                                () async { await _controller.pickStart(); reloadData();},
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.east_rounded, size: 14, color: Colors.grey.withValues(alpha:0.5)),
                            ),
                            Expanded(
                              child: _dateBtn(
                                'END',
                                _controller.formatDt(_controller.endDatetime),
                                _controller.endDatetime != null,
                                () async { await _controller.pickEnd(); reloadData(); },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Field work toggle
                        GestureDetector(
                          onTap: () {
                            _controller.isFieldWork = !_controller.isFieldWork;
                            reloadData();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: _controller.isFieldWork ? _kGreen.withValues(alpha:0.08) : Colors.grey.withValues(alpha:0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _controller.isFieldWork ? _kGreen.withValues(alpha:0.4) : Colors.grey.withValues(alpha:0.15),
                                width: _controller.isFieldWork ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (_controller.isFieldWork ? _kGreen : Colors.grey).withValues(alpha:0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.signpost_rounded, color: _controller.isFieldWork ? _kGreen : Colors.grey, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Field Work Task',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: _controller.isFieldWork ? _kGreen : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Employees will travel to physical locations',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.withValues(alpha:0.65)),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _controller.isFieldWork,
                                  onChanged: (v) { _controller.isFieldWork = v; reloadData(); },
                                  activeColor: _kGreen,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Steps
                  SliverToBoxAdapter(
                    child: _buildCard(
                      icon: Icons.checklist_rtl_rounded,
                      title: 'Steps',
                      badge: _controller.steps.isNotEmpty ? '${_controller.steps.length}' : null,
                      isDark: isDark,
                      child: _controller.steps.isEmpty
                          ? _emptyStepsPlaceholder(_controller.addAndOpenStep)
                          : Column(
                        children: [
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            itemCount: _controller.steps.length,
                            onReorder: _controller.reorderSteps,
                            itemBuilder: (context, i) {
                              final step = _controller.steps[i];
                              return _StepRow(
                                key: ValueKey(step.localId),
                                step: step,
                                index: i,
                                onEdit: () => _controller.openStepSheet(step),
                                onDelete: () => _controller.deleteStep(step.localId),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _controller.addAndOpenStep,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color: Pallete.primaryColor.withValues(alpha:0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Pallete.primaryColor.withValues(alpha:0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, size: 18, color: Pallete.primaryColor),
                                  const SizedBox(width: 7),
                                  Text('Add Another Step', style: TextStyle(color: Pallete.primaryColor, fontWeight: FontWeight.w700, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Assign
                  SliverToBoxAdapter(child: _buildCard(
                    icon: Icons.group_rounded,
                    title: 'Assign Employees',
                    badge: _controller.selectedIds.isNotEmpty ? '${_controller.selectedIds.length}' : null,
                    badgeColor: _controller.selectedIds.isNotEmpty ? const Color(0xFF10B981) : null,
                    isDark: isDark,
                    // child: _AssignSection(c: _controller),
                    child: _controller.isLoadingMembers
                        ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Pallete.primaryColor))),
                        )
                        : _controller.roomMembers.isEmpty
                        ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('No active employees in this room', style: TextStyle(fontSize: 13, color: Colors.grey.withValues(alpha:0.6))),
                        )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Select/deselect all
                        Row(
                          children: [
                            Text('${_controller.roomMembers.length} member${_controller.roomMembers.length == 1 ? '' : 's'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha:0.6))),
                            const Spacer(),
                            GestureDetector(
                              onTap: _controller.allSelected ? _controller.clearAll : _controller.selectAll,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _controller.allSelected
                                      ? const Color(0xFFEF4444).withValues(alpha:0.1)
                                      : Pallete.primaryColor.withValues(alpha:0.1),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  _controller.allSelected ? 'Deselect all' : 'Select all',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _controller.allSelected ? const Color(0xFFEF4444) : Pallete.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        ..._controller.roomMembers.map((m) => _MemberTile(
                          member: m,
                          selected: _controller.selectedIds.contains(m.user!.id!),
                          onTap: () => _controller.toggleMember(m.user!.id!),
                        )),
                      ],
                    ),
                  )),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),

                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C0C18) : Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha:0.1))),
              ),
              child: GestureDetector(
                onTap: _controller.isSubmitting ? null : _controller.submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    gradient: _controller.isSubmitting ? null : const LinearGradient(colors: [Pallete.primaryLightColor, Pallete.primaryColor]),
                    color: _controller.isSubmitting ? Colors.grey.withValues(alpha:0.15) : null,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _controller.isSubmitting ? null : [
                      BoxShadow(color: Pallete.primaryColor.withValues(alpha:0.4), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: _controller.isSubmitting
                      ? const Center(
                        child: SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 19),
                          const SizedBox(width: 10),
                          Text(
                            _controller.selectedIds.length > 1
                                ? 'Create Task for ${_controller.selectedIds.length} Employees'
                                : 'Create Task',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2),
                          ),
                        ],
                      ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _emptyStepsPlaceholder(VoidCallback onAdd) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Pallete.primaryColor.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Pallete.primaryColor.withValues(alpha:0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.add_task_rounded, size: 44, color: Pallete.primaryColor.withValues(alpha:0.5)),
            const SizedBox(height: 10),
            const Text('Add First Step', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Pallete.primaryColor)),
            const SizedBox(height: 4),
            Text('Tap to break the task into steps', style: TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha:0.6))),
          ],
        ),
      ),
    );
  }

  Widget _dateBtn(String label, String value, bool isSet, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSet ? Pallete.primaryColor.withValues(alpha:0.08) : Colors.grey.withValues(alpha:0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSet ? Pallete.primaryColor.withValues(alpha:0.4) : Colors.grey.withValues(alpha:0.15),
            width: isSet ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.grey.withValues(alpha:0.6))),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: isSet ? Pallete.primaryColor : Colors.grey),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isSet ? null : Colors.grey.withValues(alpha:0.4),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formLbl(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: Colors.grey.withValues(alpha:0.55)),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
    required bool isDark,
    String? badge,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14142A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha:0.06) : Colors.black.withValues(alpha:0.06)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha:0.3) : Colors.black.withValues(alpha:0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Pallete.primaryColor.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Pallete.primaryColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? Pallete.primaryColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: child),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.close_rounded, size: 20),
          ),
        ),
      ),
      title: Column(
        children: [
          Text(
            'Create Task',
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            widget.roomName,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha:0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

}

class _StepRow extends StatelessWidget {
  final TaskFormStep step;
  final int index;
  final VoidCallback onEdit, onDelete;

  const _StepRow({super.key, required this.step, required this.index, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isField = step.isFieldWorkStep;
    final accent = isField ? const Color(0xFF10B981) : Pallete.primaryColor;
    final valid = step.isValid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: valid ? accent.withValues(alpha:0.25) : const Color(0xFFEF4444).withValues(alpha:0.4),
            width: 1.5,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minLeadingWidth: 20,
          leading: Container(
            width: 36, height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(fontWeight: FontWeight.w900, color: accent, fontSize: 15),
              ),
            ),
          ),
          title: Text(
            step.title.isEmpty ? 'Untitled step' : step.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: step.title.isEmpty ? Colors.grey : null,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(isField ? Icons.signpost_rounded : Icons.work_outline_rounded, size: 11, color: accent),
              const SizedBox(width: 4),
              Text(isField ? 'Field Work' : 'Normal', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w700)),
              if (!valid) ...[
                const SizedBox(width: 8),
                const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFEF4444)),
                const SizedBox(width: 3),
                const Text('Incomplete', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SmallBtn(icon: Icons.edit_rounded, color: Pallete.primaryColor, onTap: onEdit),
              const SizedBox(width: 4),
              _SmallBtn(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444), onTap: onDelete),
              const SizedBox(width: 4),
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_handle_rounded, color: Colors.grey.withValues(alpha:0.4), size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 15, color: color),
    ),
  );
}

class _PriorityBtn extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityBtn({required this.label, required this.value, required this.selected, required this.onTap});

  Color get _c => switch (value) {
    'high' => const Color(0xFFEF4444),
    'low' => const Color(0xFF22C55E),
    _ => const Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? _c.withValues(alpha:0.12) : Colors.grey.withValues(alpha:0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? _c : Colors.grey.withValues(alpha:0.15), width: selected ? 1.5 : 1),
      ),
      child: Center(
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? _c : Colors.grey)),
      ),
    ),
  );
}

class _MemberTile extends StatelessWidget {
  final RoomMemberItem member;
  final bool selected;
  final VoidCallback onTap;

  const _MemberTile({required this.member, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? Pallete.primaryColor.withValues(alpha:0.08)
                : Colors.grey.withValues(alpha:isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Pallete.primaryColor.withValues(alpha:0.4) : Colors.grey.withValues(alpha:0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Pallete.primaryColor.withValues(alpha:0.15),
                    backgroundImage: member.user?.profilePicture != null ? NetworkImage(member.user!.profilePicture!) : null,
                    child: member.user?.profilePicture == null
                        ? Text(
                      (member.user?.fullName?[0] ?? 'NA').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Pallete.primaryColor, fontSize: 15),
                    )
                        : null,
                  ),
                  if (member.user?.isOnline ?? false)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF14142A) : Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.user?.fullName ?? 'NA', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    if (member.user?.username != null)
                      Text('@${member.user?.username ?? 'NA'}', style: TextStyle(fontSize: 11, color: Colors.grey.withValues(alpha:0.6))),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: selected ? Pallete.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: selected ? Pallete.primaryColor : Colors.grey.withValues(alpha:0.35),
                    width: 1.5,
                  ),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}