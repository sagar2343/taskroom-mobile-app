import 'dart:io';

import 'package:field_work/features/employee_task/controller/employee_task_detail_controller.dart';
import 'package:field_work/features/task/view/widgets/step_card.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_pallete.dart';
import '../../../task/model/task_model.dart';
import '../../../task/view/widgets/signature_pad.dart';
import '../../../widgets/animated_screen_wrapper.dart';

class EmployeeTaskDetailScreen extends StatefulWidget {
  final String taskId;
  final VoidCallback? onTaskUpdated;

  const EmployeeTaskDetailScreen({
    super.key,
    required this.taskId,
    this.onTaskUpdated,
  });

  @override
  State<EmployeeTaskDetailScreen> createState() => _EmployeeTaskDetailScreenState();
}

class _EmployeeTaskDetailScreenState extends State<EmployeeTaskDetailScreen> {
  late final EmployeeTaskController _c;

  @override
  void initState() {
    super.initState();
    _c = EmployeeTaskController(
      context:  context,
      reloadData: reloadData,
      taskId:   widget.taskId,
    );
    _c.init();
  }

  void reloadData(){ if (mounted) setState(() {}); }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (_c.isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Pallete.primaryColor),
          ),
        ),
      );
    }

    if (_c.errorMsg != null || _c.task == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task'),
          backgroundColor: Colors.transparent,
        ),
        body:  Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Pallete.kRed.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded, size: 48, color: Pallete.kRed,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _c.errorMsg ?? 'Task not found',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _c.loadTask,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: Pallete.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              )
            ],
          ),
        ),
      );
    }

    // ── Main ─────────────────────────────────────────────────────────────
    final task        = _c.task!;
    final total       = task.totalSteps    ?? 0;
    final done        = task.completedSteps ?? 0;
    final progress    = total > 0 ? done / total : 0.0;
    final statusColor = _c.statusColor(task.status);

    return AnimatedScreenWrapper(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
      
            /// HERO HEADER
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(10),
                child: GestureDetector(
                  onTap: () {
                    widget.onTaskUpdated?.call();
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor,
                        statusColor.withValues(alpha: 0.8),
                        statusColor.withValues(alpha: 0.35),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(top: -40, right: -30,
                        child: Container(width: 200, height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06)),
                        ),
                      ),
                      Positioned(bottom: 10, left: 160,
                        child: Container(width: 160, height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Wrap(spacing: 8, runSpacing: 6, children: [
                                _HeroBadge(label: _c.statusLabel(task.status)),
                                if (task.isFieldWork == true)
                                  const _HeroBadge(label: '📍 Field Work'),
                                if (task.priority != null)
                                  _HeroBadge(label: _c.priorityLabel(task.priority)),
                              ]),
                              const SizedBox(height: 14),
                              Text(
                                task.title ?? 'Untitled Task',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.7,
                                  height: 1.2,
                                  shadows: [Shadow(
                                    color: Colors.black26,
                                    blurRadius: 16,
                                    offset: Offset(0, 3),
                                  )],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                if (task.room?.name != null) ...[
                                  const Icon(Icons.meeting_room_rounded,
                                      size: 13, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(task.room!.name!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 14),
                                ],
                                if (task.createdBy?.fullName != null) ...[
                                  const Icon(Icons.person_outline_rounded,
                                      size: 13, color: Colors.white54),
                                  const SizedBox(width: 4),
                                  Text('by ${task.createdBy!.fullName!}',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 12)),
                                ],
                              ]),
                              if (total > 0) ... [
                                const SizedBox(height: 16),
                                Row(children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6,
                                        backgroundColor:
                                          Colors.white.withValues(alpha: 0.2),
                                        valueColor: const AlwaysStoppedAnimation(
                                          Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('$done / $total',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                                ]),
                              ]
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
      
            /// SCHEDULE CARD
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SurfaceCard(
                  child: Column(children: [
                    Row(children: [
                      _ScheduleCol(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'START',
                        date: _c.fmtDate(task.startDatetime),
                        time: _c.fmtTime(task.startDatetime),
                        color: Pallete.primaryColor,
                      ),
                      Expanded(
                        child: Center(
                          child: Column(children: [
                           Icon(Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.grey.withValues(alpha: 0.3)),
                            const SizedBox(height: 2),
                            Text('to',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.withValues(alpha: 0.35))),
                          ]),
                        ),
                      ),
                      _ScheduleCol(
                        icon: Icons.flag_rounded,
                        label: 'DEADLINE',
                        date: _c.fmtDate(task.endDatetime),
                        time: _c.fmtTime(task.endDatetime),
                        color: Pallete.kAmber,
                        isOverdue: _c.isTaskActive &&
                            task.endDatetime != null &&
                            task.endDatetime!.isBefore(DateTime.now()),
                        alignEnd: true,
                      ),
                      if (total > 0) ...[
                        const SizedBox(width: 16),
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _c.progressColor(progress)
                                .withValues(alpha: 0.08),
                            border: Border.all(
                              color: _c.progressColor(progress)
                                    .withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${(progress * 100).round()}%',
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: _c.progressColor(progress))),
                              Text('done',
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: _c.progressColor(progress)
                                          .withValues(alpha: 0.7))),
                            ]),
                        ),
                      ],
                    ]),
                    if (total > 0) ...[
                      const SizedBox(height: 16),
                      Row(children: [
                       Expanded(
                         child: ClipRRect(
                           borderRadius: BorderRadius.circular(99),
                           child: LinearProgressIndicator(
                             value: progress,
                             minHeight: 7,
                             backgroundColor: Colors.grey.withValues(alpha: 0.1),
                             valueColor: AlwaysStoppedAnimation(
                                 _c.progressColor(progress)),
                           ),
                         ),
                       ),
                        const SizedBox(width: 10),
                        Text('$done/$total steps',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _c.progressColor(progress))),
                      ])
                    ]
                  ]),
                ),
              ),
            ),
      
            /// MANAGER NOTE
            if (task.note?.isNotEmpty == true)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Pallete.kAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Pallete.kAmber.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Pallete.kAmber.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sticky_note_2_rounded,
                              size: 16, color: Pallete.kAmber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MANAGER NOTE',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                      color: Pallete.kAmber)),
                              const SizedBox(height: 5),
                              Text(task.note!,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.5)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
      
            /// STEPS HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 4),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Pallete.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.checklist_rounded,
                        size: 17, color: Pallete.primaryColor),
                  ),
                  const SizedBox(width: 10),
                  const Text('Steps',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4)),
                  const SizedBox(width: 8),
                  if (total > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Pallete.primaryColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('$done / $total',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                ]),
              ),
            ),
      
            /// STEPS LIST
            SliverList(
              delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final steps = task.steps ?? [];
                    if (i >= steps.length) return null;
                    final step = steps[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: StepCard(
                        step: step,
                        index: i,
                        isLast: i == steps.length -1,
                        controller: _c,
                        onStartStep:      () => _c.startStep(step.stepId!),
                        onMarkReached:    () => _c.markReached(step.stepId!),
                        onOpenCompletion: () => _showCompletionSheet(step),
                      ),
                    );
                  }
              ),
            ),
      
            /// START TASK BUTTON
            if (_c.isTaskPending)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: GestureDetector(
                    onTap: _c.isActionInProgress ? null : _c.startTask,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(vertical: 19),
                      decoration: BoxDecoration(
                          gradient: _c.isActionInProgress
                              ? null
                              : LinearGradient(
                            colors: [
                              Pallete.primaryColor,
                              Pallete.primaryLightColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        color: _c.isActionInProgress
                            ? Colors.grey.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                          boxShadow: _c.isActionInProgress
                              ? null
                              : [
                            BoxShadow(
                              color: Pallete.primaryColor.withValues(alpha: 0.42),
                              blurRadius: 22,
                              offset: const Offset(0, 9),
                            )
                          ],
                      ),
                      child: _c.isActionInProgress
                          ? const Center(
                            child: SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          )
                          : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text('Start Task',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 52)),
          ],
        ),
      ),
    );
  }

  void _showCompletionSheet(TaskStep step) {
    final v = step.validations;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        void refresh() { setSheet(() {}); setState(() {}); }
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.only(top: 60),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F1C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                      color: Pallete.kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.task_alt_rounded,
                      color: Pallete.kGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Complete Step',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 17,
                          letterSpacing: -0.3)),
                  Text(step.title ?? '',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.withValues(alpha: 0.55)),
                      overflow: TextOverflow.ellipsis),
                ])),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey.withValues(alpha: 0.6)),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.08)),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Photo
                  if (v?.requirePhoto == true) ...[
                    _SheetLabel('PHOTO PROOF', isRequired: true),
                    _PhotoCapture(
                      photo: _c.capturedPhoto,
                      onCapture: () async { await _c.capturePhoto(); refresh(); },
                      onRemove: () { _c.removePhoto(); refresh(); },
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Signature
                  if (v?.requireSignature == true) ...[
                    _SheetLabel(
                      'SIGNATURE · ${(v?.signatureFrom ?? 'required').toUpperCase()}',
                      isRequired: true,
                    ),
                    _SignatureCapture(
                      hasSignature: _c.signatureBase64 != null,
                      signerLabel: _c.capitalize(v?.signatureFrom),
                      onOpen: () {
                        // Navigator.pop(ctx);
                        SignaturePadSheet.show(
                          context,
                          signerLabel: _c.capitalize(v?.signatureFrom),
                          onSigned: (b64) {
                            _c.onSignatureReceived(b64);
                            // Navigator.pop(ctx);
                            refresh();
                            // _showCompletionSheet(step);
                          },
                        );
                      },
                      onClear: () { _c.clearSignature(); refresh(); },
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Location check info
                  if (v?.requireLocationCheck == true) ...[
                    const _SheetLabel('LOCATION CHECK'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Pallete.kGreen.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Pallete.kGreen.withValues(alpha: 0.18)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              color: Pallete.kGreen.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.my_location_rounded,
                              color: Pallete.kGreen, size: 17),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your GPS location will be captured automatically when you submit.',
                            style: TextStyle(fontSize: 12, height: 1.45),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Notes
                  const _SheetLabel('NOTES (optional)'),
                  TextField(
                    controller: _c.notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Add observations or remarks...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey.withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: isDark ? 0.07 : 0.04),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Pallete.primaryColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Submit
                  GestureDetector(
                    onTap: _c.isActionInProgress
                        ? null
                        : () async {
                      if (ctx.mounted) Navigator.pop(ctx);
                      // await Future.delayed(const Duration(milliseconds: 150));
                      _c.completeStep(
                        step.stepId!,
                        requirePhoto: v?.requirePhoto == true,
                        requireSignature: v?.requireSignature == true,
                        signatureFrom: v?.signatureFrom,
                        requireLocationCheck: v?.requireLocationCheck == true,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        gradient: _c.isActionInProgress ? null : const LinearGradient(
                          colors: [Pallete.kGreen, Color(0xFF34D399)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight,
                        ),
                        color: _c.isActionInProgress
                            ? Colors.grey.withValues(alpha: 0.12) : null,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: _c.isActionInProgress ? null : [
                          BoxShadow(
                              color: Pallete.kGreen.withValues(alpha: 0.38),
                              blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: _c.isActionInProgress
                          ? const Center(child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white))))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Mark as Complete',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w900,
                                fontSize: 15, letterSpacing: -0.2)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
      }),
    );
  }

}

  class _SurfaceCard extends StatelessWidget {
    final Widget child;
    const _SurfaceCard({required this.child});

    @override
    Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.grey.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }

  class _HeroBadge extends StatelessWidget {
  final String label;
  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
    ),
    child: Text(label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3)),
  );
}

  class _ScheduleCol extends StatelessWidget {
    final IconData icon;
    final String label, date, time;
    final Color color;
    final bool isOverdue, alignEnd;
    const _ScheduleCol({
      required this.icon,
      required this.label,
      required this.date,
      required this.time,
      required this.color,
      this.isOverdue = false,
      this.alignEnd  = false,
    });

    @override
    Widget build(BuildContext context) {
      final c = isOverdue ? const Color(0xFFEF4444) : color;
      return Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
          if (!alignEnd) ...[
            Icon(icon, size: 12, color: c.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
          ],
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: c.withValues(alpha: 0.7))),
            if (alignEnd) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 12, color: c.withValues(alpha: 0.7)),
            ],
          ]),
          const SizedBox(height: 5),
          Text(date,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: c,
                  letterSpacing: -0.3)),
          Text(time,
              style: TextStyle(
                  fontSize: 11,
                  color: c.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600)),
        ],
      );
    }
  }
// ── Completion sheet sub-widgets ──────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  const _SheetLabel(this.text, {this.isRequired = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.7,
              color: Colors.grey.withValues(alpha: 0.5))),
      if (isRequired)
        const Text(' *',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900,
                color: Pallete.kRed)),
    ]),
  );
}

class _PhotoCapture extends StatelessWidget {
  final File? photo;
  final VoidCallback onCapture, onRemove;
  const _PhotoCapture(
      {required this.photo, required this.onCapture, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(photo!, height: 200,
              width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(top: 10, right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.black54, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
            ),
          ),
        ),
      ]);
    }
    return GestureDetector(
      onTap: onCapture,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Pallete.kAmber.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Pallete.kAmber.withValues(alpha: 0.26),
              width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Pallete.kAmber.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_rounded,
                color: Pallete.kAmber, size: 28),
          ),
          const SizedBox(height: 10),
          const Text('Tap to capture photo',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Pallete.kAmber)),
          const SizedBox(height: 3),
          Text('Required for this step',
              style: TextStyle(
                  fontSize: 11,
                  color: Pallete.kAmber.withValues(alpha: 0.55))),
        ]),
      ),
    );
  }
}

class _SignatureCapture extends StatelessWidget {
  final bool hasSignature;
  final String? signerLabel;
  final VoidCallback onOpen, onClear;
  const _SignatureCapture({
    required this.hasSignature, this.signerLabel,
    required this.onOpen, required this.onClear,
  });

  static const _c = Pallete.kBlue;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: hasSignature ? null : onOpen,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _c.withValues(alpha: hasSignature ? 0.07 : 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _c.withValues(alpha: hasSignature ? 0.32 : 0.16),
            width: hasSignature ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(
              hasSignature ? Icons.verified_rounded : Icons.draw_rounded,
              color: _c, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            hasSignature ? 'Signature Collected ✓' : 'Collect Signature',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: _c),
          ),
          if (signerLabel != null)
            Text('Required from: $signerLabel',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.withValues(alpha: 0.55))),
        ])),
        if (hasSignature)
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.refresh_rounded,
                  color: Colors.grey.withValues(alpha: 0.5), size: 16),
            ),
          )
        else
          const Icon(Icons.chevron_right_rounded, color: _c, size: 20),
      ]),
    ),
  );
}