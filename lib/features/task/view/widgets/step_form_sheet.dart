import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/task/model/task_form_models.dart';
import 'package:field_work/features/task/view/screen/location_picker_screen.dart';
import 'package:field_work/features/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step configuration bottom-sheet.
///
/// What changed vs old version:
/// - "Normal / Field Work" step-type tiles REMOVED.
///   A step becomes field-work automatically when [requireLocationCheck] is
///   enabled AND a destination pin is set.
/// - "GPS route trace" toggle REMOVED from step level.
///   Tracing is now a task-level setting inherited automatically.
/// - "Location Check" renamed to "Destination Check" with clear explanation.
class StepFormSheet extends StatefulWidget {
  final TaskFormStep step;
  final DateTime?    taskStart;
  final DateTime?    taskEnd;
  final void Function(TaskFormStep) onSave;

  const StepFormSheet({
    super.key,
    required this.step,
    required this.onSave,
    this.taskStart,
    this.taskEnd,
  });

  static Future<void> show(
      BuildContext context, {
        required TaskFormStep step,
        required void Function(TaskFormStep) onSave,
        DateTime? taskStart,
        DateTime? taskEnd,
      }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => StepFormSheet(
            step: step, onSave: onSave,
            taskStart: taskStart, taskEnd: taskEnd),
      );

  @override
  State<StepFormSheet> createState() => _StepFormSheetState();
}

class _StepFormSheetState extends State<StepFormSheet> {
  late TaskFormStep _s;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _radiusCtrl;

  static const _kGreen  = Color(0xFF10B981);
  static const _kAmber  = Color(0xFFF59E0B);
  static const _kBlue   = Color(0xFF3B82F6);
  static const _primary = Pallete.primaryColor;

  @override
  void initState() {
    super.initState();
    _s          = widget.step;
    _titleCtrl  = TextEditingController(text: _s.title);
    _descCtrl   = TextEditingController(text: _s.description);
    _radiusCtrl = TextEditingController(text: _s.locationRadiusMeters.toString());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = _s.copyWith(
      title:                _titleCtrl.text.trim(),
      description:          _descCtrl.text.trim(),
      locationRadiusMeters: int.tryParse(_radiusCtrl.text) ?? 100,
    );
    final err = updated.validationError;
    if (err != null) {
      Helpers.showSnackBar(context, err, type: SnackType.error);
      return;
    }
    widget.onSave(updated);
    Navigator.pop(context);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final base = isStart
        ? (_s.startDatetime ?? widget.taskStart ?? DateTime.now())
        : (_s.endDatetime   ?? widget.taskEnd   ?? DateTime.now());
    final first = isStart
        ? (widget.taskStart ?? DateTime.now().subtract(const Duration(days: 1)))
        : (_s.startDatetime ?? widget.taskStart ?? DateTime.now());

    Widget theme(BuildContext ctx, Widget? child) => Theme(
      data: Theme.of(ctx).copyWith(
          colorScheme:
          Theme.of(ctx).colorScheme.copyWith(primary: _primary)),
      child: child!,
    );

    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(first) ? first : base,
      firstDate: first,
      lastDate: widget.taskEnd ?? DateTime.now().add(const Duration(days: 730)),
      builder: theme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: theme,
    );
    if (time == null) return;
    final dt =
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _s = isStart
        ? _s.copyWith(startDatetime: dt)
        : _s.copyWith(endDatetime: dt));
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerScreen(
          initial: _s.hasLocation
              ? PickedLocation(
              latitude: _s.latitude!, longitude: _s.longitude!,
              address: _s.address)
              : null,
        ),
      ),
    );
    if (result != null) {
      setState(() => _s = _s.copyWith(
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address,
      ));
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return 'Set time';
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${mo[dt.month - 1]}, $h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bottom  = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 50),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [

        // ── Header ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.tune_rounded, color: _primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configure Step',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  if (_s.isFieldWorkStep)
                    Row(children: [
                      const Icon(Icons.where_to_vote_rounded, size: 11, color: _kGreen),
                      const SizedBox(width: 3),
                      const Text('Destination set',
                          style: TextStyle(fontSize: 11, color: _kGreen,
                              fontWeight: FontWeight.w600)),
                    ]),
                ],
              )),
              GestureDetector(
                onTap: _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_primary, Pallete.primaryLightColor]),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Save',
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ]),
          ]),
        ),

        const SizedBox(height: 8),
        Divider(color: Colors.grey.withValues(alpha: 0.1)),

        // ── Body ───────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Title
              const _Lbl('STEP TITLE *'),
              CustomTextField(controller: _titleCtrl,
                  hint: 'e.g. Pick up order from warehouse'),

              const SizedBox(height: 14),

              // Description
              const _Lbl('DESCRIPTION'),
              CustomTextField(controller: _descCtrl,
                  hint: 'Extra instructions...', maxLines: 3),

              const SizedBox(height: 20),

              // Time
              const _Lbl('STEP TIME *'),
              Row(children: [
                Expanded(child: _TimeBtn(label: 'Start', value: _fmt(_s.startDatetime),
                    isSet: _s.startDatetime != null,
                    onTap: () => _pickTime(isStart: true))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, size: 14,
                        color: Colors.grey.withValues(alpha: 0.5))),
                Expanded(child: _TimeBtn(label: 'End', value: _fmt(_s.endDatetime),
                    isSet: _s.endDatetime != null,
                    onTap: () => _pickTime(isStart: false))),
              ]),

              const SizedBox(height: 26),

              // Requirements header
              const _Lbl('EMPLOYEE REQUIREMENTS'),

              // Photo
              _Toggle(icon: Icons.camera_alt_rounded, color: _kAmber,
                  label: 'Photo Proof',
                  desc: 'Employee uploads a photo on completion',
                  value: _s.requirePhoto,
                  onChanged: (v) => setState(() => _s = _s.copyWith(requirePhoto: v))),

              // Signature
              _Toggle(icon: Icons.draw_rounded, color: _kBlue,
                  label: 'Signature',
                  desc: 'Collect a digital signature before completing',
                  value: _s.requireSignature,
                  onChanged: (v) => setState(() => _s = _s.copyWith(requireSignature: v))),

              if (_s.requireSignature) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 0, 0, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Signed by',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: Colors.grey.withValues(alpha: 0.65))),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      for (final who in ['customer', 'supervisor', 'manager'])
                        GestureDetector(
                          onTap: () => setState(
                                  () => _s = _s.copyWith(signatureFrom: who)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: _s.signatureFrom == who
                                  ? _kBlue
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: _s.signatureFrom == who
                                      ? _kBlue
                                      : Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              who[0].toUpperCase() + who.substring(1),
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _s.signatureFrom == who
                                      ? Colors.white : Colors.grey),
                            ),
                          ),
                        ),
                    ]),
                  ]),
                ),
              ],

              // Destination Check — main new toggle
              _DestCheckToggle(
                value: _s.requireLocationCheck,
                onChanged: (v) => setState(() {
                  _s = v
                      ? _s.copyWith(requireLocationCheck: true)
                      : _s.copyWith(requireLocationCheck: false,
                      clearLocation: true);
                }),
              ),

              // Destination details — only when toggle is ON
              if (_s.requireLocationCheck) ...[
                const SizedBox(height: 14),

                // Map picker
                GestureDetector(
                  onTap: _pickLocation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _s.hasLocation
                          ? _kGreen.withValues(alpha: 0.07)
                          : Colors.grey.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _s.hasLocation
                              ? _kGreen.withValues(alpha: 0.4)
                              : Colors.grey.withValues(alpha: 0.2),
                          width: _s.hasLocation ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(
                            _s.hasLocation
                                ? Icons.location_on_rounded
                                : Icons.add_location_alt_rounded,
                            color: _kGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _s.hasLocation
                            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_s.address ?? 'Location pinned',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(
                              '${_s.latitude!.toStringAsFixed(5)}, '
                                  '${_s.longitude!.toStringAsFixed(5)}',
                              style: TextStyle(fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: Colors.grey.withValues(alpha: 0.65))),
                        ])
                            : Text('Tap to pin destination on map',
                            style: TextStyle(fontSize: 13,
                                color: Colors.grey.withValues(alpha: 0.6))),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.withValues(alpha: 0.5)),
                    ]),
                  ),
                ),

                const SizedBox(height: 14),

                // Arrival radius row
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ARRIVAL RADIUS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 3),
                      Text('Employee must be within this distance to confirm arrival',
                          style: TextStyle(fontSize: 11,
                              color: Colors.grey.withValues(alpha: 0.6))),
                    ],
                  )),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _radiusCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        suffixText: 'm',
                        suffixStyle: TextStyle(fontSize: 11,
                            color: Colors.grey.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: _kGreen, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: _kGreen),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "The employee sees an \"I've Reached the Destination\" button "
                              'when they arrive. GPS is verified against the pin before '
                              'they can mark the step complete.',
                          style: TextStyle(fontSize: 11, height: 1.5, color: _kGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Save button
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_primary, Pallete.primaryLightColor]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: _primary.withValues(alpha: 0.35),
                        blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Text('Save Step',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DESTINATION CHECK TOGGLE
// ═══════════════════════════════════════════════════════════════════════════

class _DestCheckToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _DestCheckToggle({required this.value, required this.onChanged});

  static const _kGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: value
          ? _kGreen.withValues(alpha: 0.07)
          : Colors.grey.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: value
              ? _kGreen.withValues(alpha: 0.38)
              : Colors.grey.withValues(alpha: 0.15),
          width: value ? 1.5 : 1),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: (value ? _kGreen : Colors.grey).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.where_to_vote_rounded, size: 18,
            color: value ? _kGreen : Colors.grey),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Destination Check',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                color: value ? _kGreen : Colors.grey)),
        Text('Employee must physically arrive at a pinned location',
            style: TextStyle(fontSize: 11,
                color: Colors.grey.withValues(alpha: 0.6))),
      ])),
      Switch.adaptive(value: value, onChanged: onChanged,
          activeColor: _kGreen,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
    ]),
  );
}

// ───────────────────────────────────────────────────────────────────────────

class _Lbl extends StatelessWidget {
  final String text;
  const _Lbl(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
  );
}

class _TimeBtn extends StatelessWidget {
  final String label, value;
  final bool isSet;
  final VoidCallback onTap;
  const _TimeBtn({required this.label, required this.value,
    required this.isSet, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isSet
            ? Pallete.primaryColor.withValues(alpha: 0.07)
            : Colors.grey.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isSet
                ? Pallete.primaryColor.withValues(alpha: 0.35)
                : Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: Colors.grey.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Row(children: [
          Icon(Icons.access_time_rounded, size: 12,
              color: isSet ? Pallete.primaryColor : Colors.grey),
          const SizedBox(width: 5),
          Flexible(child: Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isSet ? null : Colors.grey.withValues(alpha: 0.5)))),
        ]),
      ]),
    ),
  );
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.icon, required this.color, required this.label,
    required this.desc, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: (value ? color : Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: value ? color : Colors.grey),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
            color: value ? null : Colors.grey)),
        Text(desc, style: TextStyle(fontSize: 11,
            color: Colors.grey.withValues(alpha: 0.6))),
      ])),
      Switch.adaptive(value: value, onChanged: onChanged, activeColor: color,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
    ]),
  );
}