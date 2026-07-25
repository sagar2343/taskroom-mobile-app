import 'package:flutter/material.dart';
import '../../../../config/theme/app_pallete.dart';
import '../../../../main.dart';
import '../../data/export_service.dart';

// ── Export type ────────────────────────────────────────────────────────────────
enum ExportType { attendance, tasks, teamSummary }

// ── Report config model ────────────────────────────────────────────────────────
class _ReportOption {
  final String  id;
  final String  label;
  final String  description;
  final IconData icon;
  final ExportType type;
  final bool    hasPdf;
  final bool    hasExcel;
  final bool    hasEmployeeFilter;
  final bool    hasStatusFilter;

  const _ReportOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.type,
    this.hasPdf              = true,
    this.hasExcel            = true,
    this.hasEmployeeFilter   = false,
    this.hasStatusFilter     = false,
  });
}

// ── All available reports (mirrors backend routes) ─────────────────────────────
const _reports = <_ReportOption>[
  _ReportOption(
    id:                  'attendance',
    label:               'Attendance report',
    description:         'Daily punch-in/out, hours worked, sessions per employee',
    icon:                Icons.people_outline_rounded,
    type:                ExportType.attendance,
    hasEmployeeFilter:   true,
  ),
  _ReportOption(
    id:                  'tasks',
    label:               'Task report',
    description:         'All tasks with status, priority, steps, and assignee details',
    icon:                Icons.task_alt_rounded,
    type:                ExportType.tasks,
    hasEmployeeFilter:   true,
    hasStatusFilter:     true,
  ),
  _ReportOption(
    id:                  'team_summary',
    label:               'Team productivity summary',
    description:         'Org-wide productivity scores, completion rates, and averages',
    icon:                Icons.bar_chart_rounded,
    type:                ExportType.teamSummary,
    hasExcel:            false,   // backend only has PDF for team summary
  ),
];

// ── Date-range preset ──────────────────────────────────────────────────────────
class _Preset {
  final String   label;
  final DateTime from;
  final DateTime to;
  const _Preset(this.label, this.from, this.to);
}

List<_Preset> _buildPresets() {
  final now = DateTime.now();
  return [
    _Preset('Last 7 days',  now.subtract(const Duration(days: 7)),  now),
    _Preset('Last 30 days', now.subtract(const Duration(days: 30)), now),
    _Preset('Last 90 days', now.subtract(const Duration(days: 90)), now),
    _Preset('This month',
        DateTime(now.year, now.month, 1), now),
    _Preset('Last month',
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 0)),
    _Preset('Custom range', now.subtract(const Duration(days: 30)), now),
  ];
}

// ── Public show helper ─────────────────────────────────────────────────────────
class ExportSheet extends StatelessWidget {
  const ExportSheet._();

  static void show(BuildContext context) {
    showModalBottomSheet(
      context:             context,
      isScrollControlled:  true,
      backgroundColor:     Colors.transparent,
      builder: (_) => const _ExportSheetInner(),
    );
  }

  @override
  Widget build(BuildContext context) => const _ExportSheetInner();
}

// ── Inner stateful widget ──────────────────────────────────────────────────────
class _ExportSheetInner extends StatefulWidget {
  const _ExportSheetInner();

  @override
  State<_ExportSheetInner> createState() => _ExportSheetInnerState();
}

class _ExportSheetInnerState extends State<_ExportSheetInner> {
  final _svc     = ExportService();
  final _presets = _buildPresets();

  // ── State ──
  int      _reportIdx   = 0;
  int      _presetIdx   = 1;          // default: last 30 days
  DateTime _customFrom  = DateTime.now().subtract(const Duration(days: 30));
  DateTime _customTo    = DateTime.now();
  String   _format      = 'pdf';
  String   _taskStatus  = '';
  String?  _employeeId;               // null = all employees
  bool     _isExporting = false;

  // ── Derived ──
  _ReportOption get _report => _reports[_reportIdx];
  bool get _isCustom => _presetIdx == _presets.length - 1;
  DateTime get _from => _isCustom ? _customFrom : _presets[_presetIdx].from;
  DateTime get _to   => _isCustom ? _customTo   : _presets[_presetIdx].to;

  String _fmtDate(DateTime d) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${mo[d.month - 1]} ${d.year}';
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: isFrom ? _customFrom : _customTo,
      firstDate:   DateTime(2023),
      lastDate:    DateTime.now(),
      builder:     (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme
              .copyWith(primary: Pallete.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _customFrom = picked;
        else        _customTo   = picked;
      });
    }
  }

  // ── Export ─────────────────────────────────────────────────────────────────
  Future<void> _doExport() async {
    final type   = _report.type;
    final empId  = _employeeId;
    final from   = _from;
    final to     = _to;
    final format = _format;
    final status = _taskStatus;

    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 300));

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    switch (type) {
      case ExportType.attendance:
        format == 'pdf'
            ? await _svc.attendancePdf(
            context: ctx, employeeId: empId, from: from, to: to)
            : await _svc.attendanceExcel(
            context: ctx, employeeId: empId, from: from, to: to);
      case ExportType.tasks:
        format == 'pdf'
            ? await _svc.tasksPdf(
            context: ctx, employeeId: empId, from: from, to: to,
            status: status.isEmpty ? null : status)
            : await _svc.tasksExcel(
            context: ctx, employeeId: empId, from: from, to: to,
            status: status.isEmpty ? null : status);
      case ExportType.teamSummary:
        format == 'pdf'
            ? await _svc.teamSummaryPdf(context: ctx, from: from, to: to)
            : await _svc.teamSummaryExcel(context: ctx, from: from, to: to);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [

          // ── Handle ──
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color:        cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:        Pallete.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.download_rounded,
                    color: Pallete.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Export report',
                    style: Theme.of(context).textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.w800, fontSize: 17)),
                Text('Select report type and options',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45))),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        cs.onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Divider(height: 1, color: cs.outline.withValues(alpha: 0.1)),
          ),

          // ── Scrollable body ──
          Expanded(
            child: ListView(
              controller: controller,
              padding:    const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children:   [

                // ── 1. Report type ──────────────────────────────────────────
                _sectionLabel(context, 'Report type'),
                const SizedBox(height: 10),
                ..._reports.asMap().entries.map((e) {
                  final i   = e.key;
                  final rep = e.value;
                  final sel = _reportIdx == i;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _reportIdx = i;
                      _format    = rep.hasPdf ? 'pdf' : 'excel';
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: sel
                            ? Pallete.primaryColor.withValues(alpha: 0.06)
                            : cs.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel
                              ? Pallete.primaryColor.withValues(alpha: 0.5)
                              : cs.outline.withValues(alpha: 0.15),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: sel
                                ? Pallete.primaryColor.withValues(alpha: 0.12)
                                : cs.onSurface.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(rep.icon,
                              size: 18,
                              color: sel
                                  ? Pallete.primaryColor
                                  : cs.onSurface.withValues(alpha: 0.45)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rep.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize:   14,
                                    color: sel
                                        ? Pallete.primaryColor
                                        : cs.onSurface)),
                            const SizedBox(height: 2),
                            Text(rep.description,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.45),
                                    height: 1.4)),
                          ],
                        )),
                        if (sel)
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color:  Pallete.primaryColor,
                              shape:  BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                size: 13, color: Colors.white),
                          ),
                      ]),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // ── 2. Date range ───────────────────────────────────────────
                _sectionLabel(context, 'Date range'),
                const SizedBox(height: 10),

                // Preset chips
                Wrap(spacing: 8, runSpacing: 8, children: _presets
                    .asMap()
                    .entries
                    .map((e) {
                  final i   = e.key;
                  final pre = e.value;
                  final sel = _presetIdx == i;
                  return GestureDetector(
                    onTap: () => setState(() => _presetIdx = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? Pallete.primaryColor
                            : cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: sel
                              ? Pallete.primaryColor
                              : cs.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(pre.label,
                          style: TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : cs.onSurface.withValues(alpha: 0.6))),
                    ),
                  );
                }).toList()),

                // Custom range pickers
                if (_isCustom) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _datePicker(
                        context, 'From', _customFrom,
                        isDark, () => _pickDate(true))),
                    const SizedBox(width: 10),
                    Expanded(child: _datePicker(
                        context, 'To', _customTo,
                        isDark, () => _pickDate(false))),
                  ]),
                ] else ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:        cs.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: cs.outline.withValues(alpha: 0.12)),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: Pallete.primaryColor),
                      const SizedBox(width: 8),
                      Text('${_fmtDate(_from)}  →  ${_fmtDate(_to)}',
                          style: TextStyle(
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.7))),
                    ]),
                  ),
                ],

                const SizedBox(height: 20),

                // ── 3. Task status filter (tasks only) ──────────────────────
                if (_report.hasStatusFilter) ...[
                  _sectionLabel(context, 'Filter by status'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _statusChip(context, 'All',         '',            cs),
                    _statusChip(context, 'Completed',   'completed',   cs),
                    _statusChip(context, 'In progress', 'in_progress', cs),
                    _statusChip(context, 'Pending',     'pending',     cs),
                    _statusChip(context, 'Cancelled',   'cancelled',   cs),
                    _statusChip(context, 'Overdue',     'overdue',     cs),
                  ]),
                  const SizedBox(height: 20),
                ],

                // ── 4. Format ───────────────────────────────────────────────
                _sectionLabel(context, 'Format'),
                const SizedBox(height: 10),
                Row(children: [
                  if (_report.hasPdf)
                    Expanded(child: _formatBtn(
                        context, 'PDF', 'pdf',
                        Icons.picture_as_pdf_rounded, cs)),
                  if (_report.hasPdf && _report.hasExcel)
                    const SizedBox(width: 10),
                  if (_report.hasExcel)
                    Expanded(child: _formatBtn(
                        context, 'Excel (.xlsx)', 'excel',
                        Icons.table_chart_rounded, cs)),
                ]),

                const SizedBox(height: 8),
                // Format info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        cs.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _format == 'pdf'
                              ? 'PDF is formatted for printing and sharing. Opens in any PDF viewer.'
                              : 'Excel file saved to your Downloads folder. Open with Google Sheets or Microsoft Excel.',
                          style: TextStyle(
                              fontSize: 11,
                              height:   1.5,
                              color: cs.onSurface.withValues(alpha: 0.45)),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),

          // ── Sticky download button ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                  top: BorderSide(
                      color: cs.outline.withValues(alpha: 0.1))),
            ),
            child: Column(children: [
              // Summary line
              Row(children: [
                Icon(Icons.receipt_long_rounded,
                    size: 14,
                    color: cs.onSurface.withValues(alpha: 0.35)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_report.label}  ·  ${_fmtDate(_from)} – ${_fmtDate(_to)}  ·  ${_format.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width:  double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isExporting
                        ? cs.onSurface.withValues(alpha: 0.1)
                        : Pallete.primaryColor,
                    foregroundColor: Colors.white,
                    elevation:       0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isExporting ? null : _doExport,
                  icon: _isExporting
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation(Colors.white)))
                      : const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    _isExporting
                        ? 'Generating report…'
                        : 'Download ${_format.toUpperCase()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ]),
          ),

        ]),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(BuildContext context, String label) => Text(
    label.toUpperCase(),
    style: TextStyle(
        fontSize:      10,
        fontWeight:    FontWeight.w800,
        letterSpacing: 0.7,
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.4)),
  );

  Widget _datePicker(BuildContext context, String label, DateTime value,
      bool isDark, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontSize:   9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 13, color: Pallete.primaryColor),
            const SizedBox(width: 6),
            Text(_fmtDate(value),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String label, String value,
      ColorScheme cs) {
    final sel = _taskStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _taskStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: sel
              ? Pallete.primaryColor
              : cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: sel
                ? Pallete.primaryColor
                : cs.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color: sel
                    ? Colors.white
                    : cs.onSurface.withValues(alpha: 0.6))),
      ),
    );
  }

  Widget _formatBtn(BuildContext context, String label, String val,
      IconData icon, ColorScheme cs) {
    final sel = _format == val;
    return GestureDetector(
      onTap: () => setState(() => _format = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: sel
              ? Pallete.primaryColor.withValues(alpha: 0.08)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel
                ? Pallete.primaryColor
                : cs.outline.withValues(alpha: 0.18),
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              size:  18,
              color: sel
                  ? Pallete.primaryColor
                  : cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 7),
          Text(label,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color: sel
                      ? Pallete.primaryColor
                      : cs.onSurface.withValues(alpha: 0.55))),
        ]),
      ),
    );
  }
}