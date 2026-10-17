import 'dart:async';
import 'dart:io';

import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/task/view/widgets/voice_note_player.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Record → preview → delete control for the Create Task form.
/// The recorded file lives in the temp directory until the task is
/// submitted; the parent is told about changes via [onChanged].
class VoiceNoteRecorder extends StatefulWidget {
  final File? initialFile;
  final int initialDuration;
  final void Function(File? file, int durationSeconds) onChanged;
  final ValueChanged<bool> onRecordingChanged;

  const VoiceNoteRecorder({
    super.key,
    required this.onChanged,
    required this.onRecordingChanged,
    this.initialFile,
    this.initialDuration = 0,
  });

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  static const int _maxSeconds = 120;

  final AudioRecorder _rec = AudioRecorder();
  Timer? _timer;

  bool _recording = false;
  bool _busy = false;
  int _elapsed = 0;

  File? _file;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _file = widget.initialFile;
    _duration = widget.initialDuration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    final wasRecording = _recording;
    if (wasRecording) widget.onRecordingChanged(false);
    () async {
      try {
        if (wasRecording) await _rec.cancel(); // stops + deletes the partial file
        await _rec.dispose();
      } catch (_) {}
    }();
    super.dispose();
  }

  String _fmt(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  Future<void> _start() async {
    if (_busy || _recording) return;
    _busy = true;
    try {
      // record's hasPermission() requests the mic permission if needed and
      // works on both platforms without extra permission_handler setup.
      if (!await _rec.hasPermission()) {
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Microphone permission is needed to record. Enable it in Settings.',
            type: SnackType.error,
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _rec.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _recording = true;
        _elapsed = 0;
      });
      widget.onRecordingChanged(true);

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed++);
        if (_elapsed >= _maxSeconds) _stop();
      });
    } catch (e) {
      debugPrint('[VoiceNoteRecorder] start error: $e');
      if (mounted) {
        Helpers.showSnackBar(context, 'Could not start recording.',
            type: SnackType.error);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _timer?.cancel();
    final secs = _elapsed;

    String? path;
    try {
      path = await _rec.stop();
    } catch (e) {
      debugPrint('[VoiceNoteRecorder] stop error: $e');
    }

    if (!mounted) return;
    widget.onRecordingChanged(false);

    if (path == null || secs < 1) {
      setState(() => _recording = false);
      if (path != null) {
        try { File(path).deleteSync(); } catch (_) {}
      }
      Helpers.showSnackBar(context, 'Recording too short — try again.',
          type: SnackType.error);
      return;
    }

    final f = File(path);
    setState(() {
      _recording = false;
      _file = f;
      _duration = secs;
    });
    widget.onChanged(f, secs);
  }

  void _discard() {
    final old = _file;
    setState(() {
      _file = null;
      _duration = 0;
    });
    if (old != null) {
      try { old.deleteSync(); } catch (_) {}
    }
    widget.onChanged(null, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'VOICE NOTE (OPTIONAL)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.grey.withValues(alpha: 0.55),
            ),
          ),
        ),

        // ── Recorded: preview + delete ────────────────────────────────
        if (_file != null && !_recording)
          Row(
            children: [
              Expanded(
                child: VoiceNotePlayer(
                  key: ValueKey(_file!.path),
                  filePath: _file!.path,
                  durationSeconds: _duration,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _discard,
                tooltip: 'Remove voice note',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Pallete.kRed),
              ),
            ],
          )

        // ── Recording in progress ─────────────────────────────────────
        else if (_recording)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Pallete.kRed.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Pallete.kRed.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record_rounded,
                    size: 14, color: Pallete.kRed),
                const SizedBox(width: 8),
                Text(
                  'Recording  ${_fmt(_elapsed)} / ${_fmt(_maxSeconds)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Pallete.kRed),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Stop'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Pallete.kRed,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          )

        // ── Idle ──────────────────────────────────────────────────────
        else
          GestureDetector(
            onTap: _start,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Pallete.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Pallete.primaryColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic_rounded,
                      size: 18, color: Pallete.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Record a voice note',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: Pallete.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}