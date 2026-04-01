import 'package:flutter/material.dart';

import '../../../../config/theme/app_pallete.dart';
import '../../../employee_task/controller/employee_task_detail_controller.dart';
import '../../model/task_model.dart';

/// The main step card used in [EmployeeTaskDetailScreen].
/// Shows a different UI for each lifecycle state:
///   pending → in_progress → reached (field only) → completed / skipped
class StepCard extends StatelessWidget {
  final TaskStep                step;
  final int                     index;
  final bool                    isLast;
  final EmployeeTaskController  controller;
  final VoidCallback            onStartStep;
  final VoidCallback            onMarkReached;
  final VoidCallback            onOpenCompletion;

  const StepCard({
    super.key,
    required this.step,
    required this.index,
    required this.isLast,
    required this.controller,
    required this.onStartStep,
    required this.onMarkReached,
    required this.onOpenCompletion,
  });

  // ── Derived state ──────────────────────────────────────────────────────
  bool get _isActive  => step.status == 'in_progress' || step.status == 'reached';
  bool get _isDone    => step.status == 'completed'   || step.status == 'skipped';
  bool get _isPending => step.status == 'pending';

  Color get _accent => switch (step.status) {
    'completed'   => Pallete.kGreen,
    'in_progress' || 'reached' || 'travelling' => Pallete.primaryColor,
    'skipped'     => Colors.grey,
    _             => Pallete.kAmber,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Timeline(
            index: index,
            isLast: isLast,
            isDone: _isDone,
            isActive: _isActive,
            accent: _accent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _CardBody(
                step: step,
                index: index,
                isActive: _isActive,
                isDone: _isDone,
                isPending: _isPending,
                accent: _accent,
                isDark: isDark,
                controller: controller,
                onStartStep: onStartStep,
                onMarkReached: onMarkReached,
                onOpenCompletion: onOpenCompletion,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TIMELINE COLUMN
// _____________________________________________________________________________

class _Timeline extends StatelessWidget {
  final int   index;
  final bool  isLast, isDone, isActive;
  final Color accent;

  const _Timeline({
    required this.index,
    required this.isLast,
    required this.isDone,
    required this.isActive,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? accent
            : isActive
            ? accent.withValues(alpha: 0.14)
            : Colors.grey.withValues(alpha: 0.07),
        border: Border.all(
          color: (isActive || isDone) ? accent : Colors.grey.withValues(alpha: 0.18),
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 1)]
            : null,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : Text('${index + 1}',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900,
              color: isActive ? accent : Colors.grey.withValues(alpha: 0.4),
            )),
      ),
    ),
    if (!isLast)
      Expanded(
        child: Container(
          width: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: isDone
                  ? [accent.withValues(alpha: 0.45), accent.withValues(alpha: 0.1)]
                  : [Colors.grey.withValues(alpha: 0.14), Colors.grey.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
  ]);
}

// _____________________________________________________________________________
//  CARD BODY  (dispatches to sub-widgets based on state)
// _____________________________________________________________________________

class _CardBody extends StatelessWidget {
  final TaskStep step;
  final int      index;
  final bool     isActive, isDone, isPending, isDark;
  final Color    accent;
  final EmployeeTaskController controller;
  final VoidCallback onStartStep, onMarkReached, onOpenCompletion;

  const _CardBody({
    required this.step, required this.index,
    required this.isActive, required this.isDone, required this.isPending,
    required this.accent, required this.isDark, required this.controller,
    required this.onStartStep, required this.onMarkReached,
    required this.onOpenCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: isActive
            ? accent.withValues(alpha: isDark ? 0.08 : 0.04)
            : isDark ? const Color(0xFF12121E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: isDark ? 0.08 : 0.09),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6))]
            : [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _StepHeader(step: step, accent: accent, isDone: isDone),
          ),

          // ── Body content ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (step.description?.isNotEmpty == true) ...[
                  Text(step.description!,
                      style: TextStyle(
                          fontSize: 13, height: 1.55,
                          color: Colors.grey.withValues(alpha: 0.62))),
                  const SizedBox(height: 10),
                ],

                // Time strip
                _TimeStrip(step: step, isDark: isDark, controller: controller),
                const SizedBox(height: 10),

                // Destination (field work)
                if (step.isFieldWorkStep == true &&
                    step.destinationLocation != null)
                  _DestinationTile(step: step),

                // Validation requirements
                if (_hasValidations) ...[
                  const SizedBox(height: 10),
                  _ValidationPills(step: step),
                ],

                // ── Completion summary (only when done) ─────────────
                if (isDone) ...[
                  const SizedBox(height: 12),
                  _CompletionSummary(
                      step: step, isDark: isDark, controller: controller),
                ],
              ],
            ),
          ),

          // ── Action button (only when not done) ────────────────────────
          if (!isDone) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _ActionArea(
                step: step,
                isPending: isPending,
                isActive: isActive,
                controller: controller,
                onStartStep: onStartStep,
                onMarkReached: onMarkReached,
                onOpenCompletion: onOpenCompletion,
              ),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  bool get _hasValidations =>
      step.validations?.requirePhoto == true ||
          step.validations?.requireSignature == true ||
          step.validations?.requireLocationCheck == true ||
          step.validations?.requireLocationTrace == true;
}

// _____________________________________________________________________________
//  STEP HEADER  — title + type tag + status pill
// _____________________________________________________________________________

class _StepHeader extends StatelessWidget {
  final TaskStep step;
  final Color    accent;
  final bool     isDone;

  const _StepHeader(
      {required this.step, required this.accent, required this.isDone});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        _TypeTag(isField: step.isFieldWorkStep == true),
        const Spacer(),
        _StatusPill(status: step.status),
      ]),
      const SizedBox(height: 8),
      Text(
        step.title ?? 'Untitled Step',
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          height: 1.25,
          color: isDone ? Colors.grey.withValues(alpha: 0.45) : null,
        ),
      ),
    ],
  );
}

// _____________________________________________________________________________
//  TIME STRIP
// _____________________________________________________________________________

class _TimeStrip extends StatelessWidget {
  final TaskStep step;
  final bool isDark;
  final EmployeeTaskController controller;

  const _TimeStrip(
      {required this.step, required this.isDark, required this.controller});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha: isDark ? 0.07 : 0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.07 : 0.06)),
    ),
    child: Row(children: [
      Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.withValues(alpha: 0.5)),
      const SizedBox(width: 6),
      Text(
        '${controller.fmtTime(step.startDatetime)}  →  ${controller.fmtTime(step.endDatetime)}',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: Colors.grey.withValues(alpha: 0.6)),
      ),
      if (step.isOverdue == true) ...[
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: Pallete.kRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5)),
          child: const Text('OVERDUE',
              style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w900,
                  color: Pallete.kRed, letterSpacing: 0.5)),
        ),
      ],
    ]),
  );
}

// _____________________________________________________________________________
//  DESTINATION TILE  (field work)
// _____________________________________________________________________________

class _DestinationTile extends StatelessWidget {
  final TaskStep step;
  const _DestinationTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final hasAddr = step.destinationLocation?.address?.isNotEmpty == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Pallete.kGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: Pallete.kGreen.withValues(alpha: 0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: Pallete.kGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.location_on_rounded,
              size: 14, color: Pallete.kGreen),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DESTINATION',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900,
                    letterSpacing: 0.7, color: Pallete.kGreen)),
            const SizedBox(height: 3),
            Text(
              hasAddr ? step.destinationLocation!.address! : 'Location set',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: Pallete.kGreen, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            if (step.locationRadiusMeters != null) ...[
              const SizedBox(height: 3),
              Text('Within ${step.locationRadiusMeters}m radius',
                  style: TextStyle(
                      fontSize: 11,
                      color: Pallete.kGreen.withValues(alpha: 0.65))),
            ],
          ]),
        ),
      ]),
    );
  }
}

// _____________________________________________________________________________
//  VALIDATION PILLS
// _____________________________________________________________________________

class _ValidationPills extends StatelessWidget {
  final TaskStep step;
  const _ValidationPills({required this.step});

  @override
  Widget build(BuildContext context) {
    final v = step.validations;
    return Wrap(spacing: 6, runSpacing: 5, children: [
      if (v?.requirePhoto == true)
        const _Pill(
            icon: Icons.camera_alt_rounded,
            label: 'Photo',
            color: Pallete.kAmber),
      if (v?.requireSignature == true)
        _Pill(
            icon: Icons.draw_rounded,
            label: 'Sign · ${v?.signatureFrom ?? ''}',
            color: Pallete.kBlue),
      if (v?.requireLocationCheck == true)
        const _Pill(
            icon: Icons.my_location_rounded,
            label: 'Location',
            color: Pallete.kGreen),
      if (v?.requireLocationTrace == true)
        const _Pill(
            icon: Icons.route_rounded,
            label: 'GPS Trace',
            color: Pallete.kRed),
    ]);
  }
}

// _____________________________________________________________________________
//  COMPLETION SUMMARY  (shown only on completed/skipped steps)
// _____________________________________________________________________________

class _CompletionSummary extends StatelessWidget {
  final TaskStep step;
  final bool isDark;
  final EmployeeTaskController controller;

  const _CompletionSummary(
      {required this.step, required this.isDark, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isSkipped = step.status == 'skipped';
    if (isSkipped) return _SkippedBanner(isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Pallete.kGreen.withValues(alpha: isDark ? 0.07 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Pallete.kGreen.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Completed header ────────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: Pallete.kGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.task_alt_rounded,
                size: 14, color: Pallete.kGreen),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('COMPLETED',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w900,
                    letterSpacing: 0.8, color: Pallete.kGreen)),
            if (step.employeeCompleteTime != null)
              Text(
                controller.fmtTime(step.employeeCompleteTime),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Pallete.kGreen),
              ),
          ]),
          const Spacer(),
          if (step.isOverdue == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Pallete.kRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: Pallete.kRed.withValues(alpha: 0.2))),
              child: const Text('Late',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: Pallete.kRed)),
            ),
        ]),

        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // ── Timeline row ────────────────────────────────────────────────
        _TimelineRow(step: step, controller: controller),

        // ── Submitted photo ─────────────────────────────────────────────
        if (step.submittedPhotoUrl?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.camera_alt_rounded,
            color: Pallete.kAmber,
            label: 'Photo',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                step.submittedPhotoUrl!,
                height: 72, width: 72, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Pallete.kAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.broken_image_rounded,
                      color: Pallete.kAmber, size: 22),
                ),
              ),
            ),
          ),
        ],

        // ── Signature ────────────────────────────────────────────────────
        if (step.signatureData == true) ...[
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.draw_rounded,
            color: Pallete.kBlue,
            label: 'Signature',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.verified_rounded,
                    size: 14, color: Pallete.kBlue),
                const SizedBox(width: 5),
                const Text('Collected',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: Pallete.kBlue)),
              ]),
              if (step.signatureSignedBy?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('by ${step.signatureSignedBy}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.withValues(alpha: 0.6))),
                ),
            ]),
          ),
        ],

        // ── Location ─────────────────────────────────────────────────────
        if (step.submittedLocation?.coordinates != null) ...[
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.my_location_rounded,
            color: Pallete.kGreen,
            label: 'Location',
            child: Text(
              '${step.submittedLocation!.coordinates![1].toStringAsFixed(5)}, '
                  '${step.submittedLocation!.coordinates![0].toStringAsFixed(5)}',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.grey.withValues(alpha: 0.7)),
            ),
          ),
        ],

        // ── Employee notes ────────────────────────────────────────────────
        if (step.employeeNotes?.isNotEmpty == true) ...[
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.notes_rounded,
            color: Colors.grey,
            label: 'Notes',
            child: Text(step.employeeNotes!,
                style: TextStyle(
                    fontSize: 12, height: 1.5,
                    color: Colors.grey.withValues(alpha: 0.75))),
          ),
        ],
      ]),
    );
  }
}

class _SkippedBanner extends StatelessWidget {
  final bool isDark;
  const _SkippedBanner({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.14)),
    ),
    child: Row(children: [
      Icon(Icons.skip_next_rounded, size: 16, color: Colors.grey.withValues(alpha: 0.5)),
      const SizedBox(width: 8),
      Text('Step skipped',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: Colors.grey.withValues(alpha: 0.5))),
    ]),
  );
}

/// Start / reach / complete times shown as a horizontal row
class _TimelineRow extends StatelessWidget {
  final TaskStep step;
  final EmployeeTaskController controller;

  const _TimelineRow({required this.step, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (step.employeeStartTime != null)
          _TimeChip(
              icon: Icons.play_arrow_rounded,
              label: 'Started',
              time: controller.fmtTime(step.employeeStartTime),
              color: Pallete.primaryColor),
        if (step.isFieldWorkStep == true && step.employeeReachTime != null)
          _TimeChip(
              icon: Icons.where_to_vote_rounded,
              label: 'Reached',
              time: controller.fmtTime(step.employeeReachTime),
              color: Pallete.kAmber),
        if (step.employeeCompleteTime != null)
          _TimeChip(
              icon: Icons.check_circle_rounded,
              label: 'Done',
              time: controller.fmtTime(step.employeeCompleteTime),
              color: Pallete.kGreen),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label, time;
  final Color color;
  const _TimeChip(
      {required this.icon, required this.label,
        required this.time, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 13, color: color),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: Colors.grey.withValues(alpha: 0.5), letterSpacing: 0.4)),
      Text(time,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    ],
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Widget child;
  const _SummaryRow(
      {required this.icon, required this.color,
        required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 13, color: color),
      ),
      const SizedBox(width: 10),
      Expanded(child: child),
    ],
  );
}

// _____________________________________________________________________________
//  ACTION AREA  — shows different CTAs depending on step state
// _____________________________________________________________________________

class _ActionArea extends StatelessWidget {
  final TaskStep step;
  final bool isPending, isActive;
  final EmployeeTaskController controller;
  final VoidCallback onStartStep, onMarkReached, onOpenCompletion;

  const _ActionArea({
    required this.step, required this.isPending, required this.isActive,
    required this.controller, required this.onStartStep,
    required this.onMarkReached, required this.onOpenCompletion,
  });

  @override
  Widget build(BuildContext context) {
    // Task not started yet — lock all steps
    if (controller.isTaskPending) {
      return const _LockedHint('Start the task first to unlock steps');
    }

    // Pending step — can only start if it's next in sequence
    if (isPending) {
      final isNext = controller.nextPendingStep?.stepId == step.stepId;
      if (!isNext) {
        return const _LockedHint('Complete the previous step first');
      }
      return _ActionButton(
        label: 'Start Step',
        icon: Icons.play_arrow_rounded,
        color: Pallete.primaryColor,
        loading: controller.isActionInProgress,
        onTap: onStartStep,
      );
    }

    // Active field-work step that hasn't reached destination yet
    if (isActive && step.isFieldWorkStep == true && step.status != 'reached') {
      return _ActionButton(
        label: "I've Reached the Destination",
        icon: Icons.where_to_vote_rounded,
        color: Pallete.kGreen,
        loading: controller.isActionInProgress,
        onTap: onMarkReached,
      );
    }

    // Active step (or reached) — show complete CTA
    if (isActive) {
      return _ActionButton(
        label: 'Complete This Step',
        icon: Icons.check_circle_rounded,
        color: Pallete.kGreen,
        loading: controller.isActionInProgress,
        onTap: onOpenCompletion,
      );
    }

    return const SizedBox.shrink();
  }
}

// _____________________________________________________________________________
//  SMALL REUSABLE WIDGETS
// _____________________________________________________________________________

class _TypeTag extends StatelessWidget {
  final bool isField;
  const _TypeTag({required this.isField});

  @override
  Widget build(BuildContext context) {
    final color = isField ? Pallete.kGreen : Pallete.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isField ? Icons.signpost_rounded : Icons.work_outline_rounded,
            size: 11, color: color),
        const SizedBox(width: 4),
        Text(isField ? 'Field Work' : 'Office',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String? status;
  const _StatusPill({this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed'   => ('✓ Completed', Pallete.kGreen),
      'in_progress' => ('Active',      Pallete.primaryColor),
      'reached'     => ('Reached ✓',   Pallete.kGreen),
      'travelling'  => ('Travelling',  Pallete.kAmber),
      'skipped'     => ('Skipped',     Colors.grey),
      _             => ('Pending',     Pallete.kAmber),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.icon,
    required this.color, required this.loading, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
      ),
      child: loading
          ? Center(child: SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(color))))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    ),
  );
}

class _LockedHint extends StatelessWidget {
  final String msg;
  const _LockedHint(this.msg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.lock_outline_rounded,
          size: 13, color: Colors.grey.withValues(alpha: 0.35)),
      const SizedBox(width: 7),
      Text(msg,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.grey.withValues(alpha: 0.42))),
    ]),
  );
}