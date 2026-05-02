// lib/features/attendance/view/widgets/online_toggle_widget.dart
//
// Drop this widget anywhere — home app bar, profile header, etc.
// It shows current online/offline status and lets the employee toggle.

import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/attendance/data/attendance_datasource.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:flutter/material.dart';

class OnlineToggleWidget extends StatefulWidget {
  /// Whether to show full card (true) or compact chip (false)
  final bool compact;
  final VoidCallback? onStatusChanged;

  const OnlineToggleWidget({
    super.key,
    this.compact = false,
    this.onStatusChanged,
  });

  @override
  State<OnlineToggleWidget> createState() => _OnlineToggleWidgetState();
}

class _OnlineToggleWidgetState extends State<OnlineToggleWidget> {
  final _ds = AttendanceDatasource();
  bool _isOnline  = false;
  bool _isLoading = true;
  bool _isWorking = false;
  String _totalFormatted = '0m';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final res = await _ds.getToday();
    if (!mounted) return;
    setState(() {
      _isOnline       = res?['data']?['isOnline'] == true;
      _totalFormatted = res?['data']?['totalFormatted']?.toString() ?? '0m';
      _isLoading      = false;
    });
  }

  Future<void> _toggle() async {
    if (_isWorking) return;

    if (_isOnline) {
      // Confirm before going offline
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Go Offline?'),
          content: const Text(
              'You will be marked as offline. Make sure you have no active tasks.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Go Offline', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _isWorking = true);

    final res = _isOnline
        ? await _ds.goOffline()
        : await _ds.goOnline();

    if (!mounted) return;
    setState(() => _isWorking = false);

    if (res?['success'] == true) {
      await _loadStatus();
      widget.onStatusChanged?.call();
      if (mounted) {
        Helpers.showSnackBar(
          context,
          _isOnline ? 'You are now online 🟢' : 'You are now offline 🔴',
          type: SnackType.success,
        );
      }
    } else {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          res?['message']?.toString() ?? 'Action failed',
          type: SnackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Pallete.primaryColor),
      );
    }

    if (widget.compact) return _buildCompactChip();
    return _buildFullCard();
  }

  // ── Compact chip (for app bar / home header) ──────────────────────────────
  Widget _buildCompactChip() {
    final color = _isOnline ? Pallete.kGreen : Colors.redAccent;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isWorking)
              SizedBox(
                width: 8, height: 8,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: color),
              )
            else
              Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color:  color,
                  shape:  BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color: color.withValues(alpha: 0.6), blurRadius: 4)],
                ),
              ),
            const SizedBox(width: 5),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color:      color,
                fontWeight: FontWeight.w700,
                fontSize:   12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Full card (for profile screen / dedicated attendance widget) ──────────
  Widget _buildFullCard() {
    final color = _isOnline ? Pallete.kGreen : Colors.redAccent;
    final tt    = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.14),
          color.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: color, size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Label + hours
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'You are Online 🟢' : 'You are Offline 🔴',
                  style: tt.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  'Today: $_totalFormatted worked',
                  style: tt.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),

          // Toggle button
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:        color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isWorking
                  ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : Text(
                _isOnline ? 'Go Offline' : 'Go Online',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}