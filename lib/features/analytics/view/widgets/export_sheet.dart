import 'package:flutter/material.dart';
import '../../../../config/theme/app_pallete.dart';
import '../../data/export_service.dart';

enum ExportType { attendance, tasks, teamSummary }

class ExportSheet extends StatefulWidget {
  final ExportType type;
  final String?    employeeId;
  final String?    employeeName;

  const ExportSheet({
    super.key,
    required this.type,
    this.employeeId,
    this.employeeName,
  });

  static void show(BuildContext context, {
    required ExportType type,
    String? employeeId,
    String? employeeName,
  }) {
    showModalBottomSheet(
      context:           context,
      isScrollControlled: true,
      backgroundColor:   Colors.transparent,
      builder: (_) => ExportSheet(
        type:         type,
        employeeId:   employeeId,
        employeeName: employeeName,
      ),
    );
  }

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  final _svc = ExportService();

  DateTime _from       = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to         = DateTime.now();
  String   _format     = 'pdf';
  String   _taskStatus = '';
  bool     _isExporting = false;

  String get _title => switch (widget.type) {
    ExportType.attendance  => 'Export Attendance',
    ExportType.tasks       => 'Export Tasks',
    ExportType.teamSummary => 'Export Team Summary',
  };

  String get _dateRangeLabel =>
      '${_fmtDate(_from)}  –  ${_fmtDate(_to)}';

  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(height: 20),

            // Title
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color:        Pallete.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.download_rounded,
                    color: Pallete.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title,
                      style: Theme.of(context).textTheme.titleSmall!
                          .copyWith(fontWeight: FontWeight.w700)),
                  if (widget.employeeName != null)
                    Text(widget.employeeName!,
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.5),
                            fontSize: 12)),
                ],
              )),
            ]),
            const SizedBox(height: 20),

            // Date range
            Container(
              decoration: BoxDecoration(
                color:        cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Column(children: [
                _dateRow(context, 'FROM', _from,
                        (d) => setState(() => _from = d)),
                Divider(height: 1,
                    color: cs.outline.withValues(alpha: 0.15)),
                _dateRow(context, 'TO', _to,
                        (d) => setState(() => _to = d)),
              ]),
            ),
            const SizedBox(height: 16),

            // Task status filter
            if (widget.type == ExportType.tasks) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: _label(context, 'FILTER BY STATUS'),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chip(context, 'All',         '', _taskStatus == ''),
                  _chip(context, 'Completed',   'completed',   _taskStatus == 'completed'),
                  _chip(context, 'In Progress', 'in_progress', _taskStatus == 'in_progress'),
                  _chip(context, 'Pending',     'pending',     _taskStatus == 'pending'),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Format selector
            Align(alignment: Alignment.centerLeft, child: _label(context, 'FORMAT')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _fmtBtn(context, 'PDF', 'pdf', Icons.picture_as_pdf_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _fmtBtn(context, 'Excel', 'excel', Icons.table_chart_rounded)),
            ]),
            const SizedBox(height: 24),

            // Download button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isExporting ? null : _doExport,
                icon: _isExporting
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  _isExporting
                      ? 'Generating report…'
                      : 'Download ${_format.toUpperCase()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _dateRow(BuildContext context, String label, DateTime value,
      ValueChanged<DateTime> onPick) {
    return InkWell(
      onTap: () => _pickDate(context, value, onPick),
      borderRadius: label == 'FROM'
          ? const BorderRadius.vertical(top: Radius.circular(12))
          : const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.4),
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const Spacer(),
          Icon(Icons.calendar_today_rounded,
              color: Pallete.primaryColor, size: 14),
          const SizedBox(width: 6),
          Text(_fmtDate(value),
              style: Theme.of(context).textTheme.bodyMedium!
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.3)),
        ]),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime initial,
      ValueChanged<DateTime> onPick) async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: initial,
      firstDate:   DateTime(2023),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: Pallete.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPick(picked);
  }

  Widget _label(BuildContext context, String text) => Text(text,
      style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5));

  Widget _chip(BuildContext context, String label, String value, bool sel) {
    return GestureDetector(
      onTap: () => setState(() => _taskStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin:   const EdgeInsets.only(right: 8),
        padding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? Pallete.primaryColor
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: sel ? Pallete.primaryColor
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: sel ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12, fontWeight: FontWeight.w500,
            )),
      ),
    );
  }

  Widget _fmtBtn(BuildContext context, String label, String val, IconData icon) {
    final sel = _format == val;
    return GestureDetector(
      onTap: () => setState(() => _format = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel
              ? Pallete.primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? Pallete.primaryColor
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18,
              color: sel ? Pallete.primaryColor
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 7),
          Text(label,
              style: TextStyle(
                color: sel ? Pallete.primaryColor
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600, fontSize: 13,
              )),
        ]),
      ),
    );
  }

  Future<void> _doExport() async {
    setState(() => _isExporting = true);
    final ctx = context;
    Navigator.pop(context);

    switch (widget.type) {
      case ExportType.attendance:
        _format == 'pdf'
            ? await _svc.attendancePdf(
            context: ctx, employeeId: widget.employeeId, from: _from, to: _to)
            : await _svc.attendanceExcel(
            context: ctx, employeeId: widget.employeeId, from: _from, to: _to);
      case ExportType.tasks:
        _format == 'pdf'
            ? await _svc.tasksPdf(
            context: ctx, employeeId: widget.employeeId, from: _from, to: _to,
            status: _taskStatus.isEmpty ? null : _taskStatus)
            : await _svc.tasksExcel(
            context: ctx, employeeId: widget.employeeId, from: _from, to: _to,
            status: _taskStatus.isEmpty ? null : _taskStatus);
      case ExportType.teamSummary:
        await _svc.teamSummaryPdf(context: ctx, from: _from, to: _to);
    }

    if (mounted) setState(() => _isExporting = false);
  }

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
}
