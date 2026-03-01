import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/task/model/task_form_models.dart';
import 'package:field_work/features/task/view/screen/location_picker_screen.dart';
import 'package:field_work/features/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StepFormSheet extends StatefulWidget {
  final TaskFormStep step;
  final DateTime? taskStart;
  final DateTime? taskEnd;
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
        builder: (_) => StepFormSheet(step: step, onSave: onSave, taskStart: taskStart, taskEnd: taskEnd),
      );

  @override
  State<StepFormSheet> createState() => _StepFormSheetState();
}

class _StepFormSheetState extends State<StepFormSheet> {
  late TaskFormStep _s;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _radiusCtrl;

  static const primaryColor = Pallete.primaryColor;
  static const _kGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _s = widget.step;
    _titleCtrl = TextEditingController(text: _s.title);
    _descCtrl = TextEditingController(text: _s.description);
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
      title: _titleCtrl.text,
      description: _descCtrl.text,
      locationRadiusMeters: int.tryParse(_radiusCtrl.text) ?? 100,
    );
    final err = updated.validationError;
    if (err != null) {
      Helpers.showSnackBar(context, err, type: SnackType.error);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text(err), backgroundColor: Pallete.errorColor),
      // );
      return;
    }
    widget.onSave(updated);
    Navigator.pop(context);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final base = isStart
        ? (_s.startDatetime ?? widget.taskStart ?? DateTime.now())
        : (_s.endDatetime ?? widget.taskEnd ?? DateTime.now());

    final first = isStart
        ? (widget.taskStart ?? DateTime.now().subtract(const Duration(days: 1)))
        : (_s.startDatetime ?? widget.taskStart ?? DateTime.now());

    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(first) ? first : base,
      firstDate: first,
      lastDate: widget.taskEnd ?? DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _s = _s.copyWith(
        startDatetime: isStart ? dt : _s.startDatetime,
        endDatetime: isStart ? _s.endDatetime : dt,
      );
    });
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerScreen(
          initial: _s.hasLocation
              ? PickedLocation(latitude: _s.latitude!, longitude: _s.longitude!, address: _s.address)
              : null,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _s = _s.copyWith(latitude: result.latitude, longitude: result.longitude, address: result.address);
      });
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return 'Set time';
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${mo[dt.month - 1]}, $h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 50),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha:0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune_rounded, color: primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text('Configure Step', style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, Pallete.primaryLightColor]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(color: Colors.grey.withValues(alpha:0.1)),

          // ── Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Step type
                  _Label('STEP TYPE'),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeTile(
                          icon: Icons.work_outline_rounded,
                          label: 'Normal',
                          sublabel: 'Office or indoor work',
                          selected: !_s.isFieldWorkStep,
                          color: primaryColor,
                          onTap: () => setState(() {
                            _s = _s.copyWith(
                              isFieldWorkStep: false,
                              requireLocationTrace: false,
                              requireLocationCheck: false,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeTile(
                          icon: Icons.signpost_rounded,
                          label: 'Field Work',
                          sublabel: 'Employee travels to site',
                          selected: _s.isFieldWorkStep,
                          color: _kGreen,
                          onTap: () => setState(() {
                            _s = _s.copyWith(
                              isFieldWorkStep: true,
                              requireLocationTrace: true,
                              requireLocationCheck: true,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Title
                  _Label('STEP TITLE *'),
                  // Custom(controller: _titleCtrl, hint: 'e.g. Pick up order from warehouse'),
                  CustomTextField(controller: _titleCtrl, hint: 'e.g. Pick up order from warehouse'),

                  const SizedBox(height: 14),

                  // ── Description
                  _Label('DESCRIPTION'),
                  CustomTextField(controller: _descCtrl, hint: 'Extra instructions...', maxLines: 3),

                  const SizedBox(height: 20),

                  // ── Time
                  _Label('STEP TIME *'),
                  Row(
                    children: [
                      Expanded(child: _TimeBtn(label: 'Start', value: _fmt(_s.startDatetime), set: _s.startDatetime != null, onTap: () => _pickTime(isStart: true))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey.withValues(alpha:0.5)),
                      ),
                      Expanded(child: _TimeBtn(label: 'End', value: _fmt(_s.endDatetime), set: _s.endDatetime != null, onTap: () => _pickTime(isStart: false))),
                    ],
                  ),

                  // ── Field work extras
                  if (_s.isFieldWorkStep) ...[
                    const SizedBox(height: 20),

                    _Label('DESTINATION *'),
                    GestureDetector(
                      onTap: _pickLocation,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _s.hasLocation
                              ? _kGreen.withValues(alpha:0.07)
                              : theme.colorScheme.onSurface.withValues(alpha:0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _s.hasLocation ? _kGreen.withValues(alpha:0.4) : Colors.grey.withValues(alpha:0.2),
                            width: _s.hasLocation ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha:0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _s.hasLocation ? Icons.location_on_rounded : Icons.add_location_alt_rounded,
                                color: _kGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _s.hasLocation
                                  ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _s.address ?? 'Location pinned',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_s.latitude!.toStringAsFixed(5)}, ${_s.longitude!.toStringAsFixed(5)}',
                                    style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey.withValues(alpha:0.7)),
                                  ),
                                ],
                              )
                                  : Text(
                                'Tap to pin on map',
                                style: TextStyle(fontSize: 13, color: Colors.grey.withValues(alpha:0.6)),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey.withValues(alpha:0.5)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Arrival radius
                    Row(
                      children: [
                        const _Label('ARRIVAL RADIUS'),
                        const Spacer(),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _radiusCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            decoration: InputDecoration(
                              isDense: true,
                              suffix: Text(' m', style: TextStyle(fontSize: 11, color: Colors.grey.withValues(alpha:0.6))),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _kGreen, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Validations
                  _Label('REQUIRED FROM EMPLOYEE'),
                  _Toggle(
                    icon: Icons.camera_alt_rounded,
                    label: 'Photo proof',
                    desc: 'Employee must upload a photo',
                    value: _s.requirePhoto,
                    onChanged: (v) => setState(() => _s = _s.copyWith(requirePhoto: v)),
                    color: const Color(0xFFF59E0B),
                  ),
                  _Toggle(
                    icon: Icons.draw_rounded,
                    label: 'Signature',
                    desc: 'Collect a digital signature',
                    value: _s.requireSignature,
                    onChanged: (v) => setState(() => _s = _s.copyWith(requireSignature: v)),
                    color: const Color(0xFF3B82F6),
                  ),

                  // Signature from
                  if (_s.requireSignature) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 44, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signed by',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.withValues(alpha:0.7)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            children: ['customer', 'supervisor', 'manager'].map((who) {
                              final sel = _s.signatureFrom == who;
                              return GestureDetector(
                                onTap: () => setState(() => _s = _s.copyWith(signatureFrom: who)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFF3B82F6) : Colors.grey.withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: sel ? const Color(0xFF3B82F6) : Colors.grey.withValues(alpha:0.2),
                                    ),
                                  ),
                                  child: Text(
                                    '${who[0].toUpperCase()}${who.substring(1)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: sel ? Colors.white : Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  _Toggle(
                    icon: Icons.my_location_rounded,
                    label: 'Location check',
                    desc: 'Verify location on completion',
                    value: _s.requireLocationCheck,
                    onChanged: (v) => setState(() => _s = _s.copyWith(requireLocationCheck: v)),
                    color: _kGreen,
                  ),
                  _Toggle(
                    icon: Icons.route_rounded,
                    label: 'GPS route trace',
                    desc: 'Track full path during step',
                    value: _s.requireLocationTrace,
                    onChanged: (v) => setState(() => _s = _s.copyWith(requireLocationTrace: v)),
                    color: const Color(0xFFEF4444),
                  ),

                  const SizedBox(height: 24),

                  // ── Save
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _save,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, Pallete.primaryLightColor]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: primaryColor.withValues(alpha:0.35), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: const Text(
                          'Save Step',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal widgets ─────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.45),
      ),
    ),
  );
}

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeTile({
    required this.icon, required this.label, required this.sublabel,
    required this.selected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha:0.09) : Colors.grey.withValues(alpha:0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color.withValues(alpha:0.5) : Colors.grey.withValues(alpha:0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 22),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? color : Colors.grey)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha:0.7))),
          ],
        ),
      ),
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final String label, value;
  final bool set;
  final VoidCallback onTap;

  const _TimeBtn({required this.label, required this.value, required this.set, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: set ? Pallete.primaryColor.withValues(alpha:0.07) : Colors.grey.withValues(alpha:0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: set ? Pallete.primaryColor.withValues(alpha:0.35) : Colors.grey.withValues(alpha:0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.withValues(alpha:0.6))),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: set ? Pallete.primaryColor : Colors.grey),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: set ? null : Colors.grey.withValues(alpha:0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label, desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _Toggle({
    required this.icon, required this.label, required this.desc,
    required this.value, required this.onChanged, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? color.withValues(alpha:0.12) : Colors.grey.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: value ? color : Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: value ? null : Colors.grey)),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.withValues(alpha:0.6))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}