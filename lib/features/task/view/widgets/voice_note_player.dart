import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:field_work/config/theme/app_pallete.dart';
import 'package:flutter/material.dart';

/// Play / pause / seek control for a voice note.
/// Pass either a remote [url] (task detail screens) or a local [filePath]
/// (the recorder's preview before the task is created).
class VoiceNotePlayer extends StatefulWidget {
  final String? url;
  final String? filePath;
  final int? durationSeconds;

  const VoiceNotePlayer({
    super.key,
    this.url,
    this.filePath,
    this.durationSeconds,
  }) : assert(url != null || filePath != null,
  'VoiceNotePlayer needs a url or a filePath');

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subs = [];

  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = false;
  bool _failed = false;
  bool _seeking = false;

  Source get _source => widget.filePath != null
      ? DeviceFileSource(widget.filePath!)
      : UrlSource(widget.url!);

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null && widget.durationSeconds! > 0) {
      _duration = Duration(seconds: widget.durationSeconds!);
    }

    _subs.add(_player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    }));
    _subs.add(_player.onPositionChanged.listen((p) {
      if (mounted && !_seeking) setState(() => _position = p);
    }));
    _subs.add(_player.onDurationChanged.listen((d) {
      if (mounted && d > Duration.zero) setState(() => _duration = d);
    }));
    _subs.add(_player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _state = PlayerState.stopped;
        });
      }
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;

    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      if (_state == PlayerState.paused) {
        await _player.resume();
      } else {
        await _player.play(_source);
      }
    } catch (e) {
      debugPrint('[VoiceNotePlayer] play error: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playing = _state == PlayerState.playing;
    final totalMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(
        color: Pallete.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Pallete.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Pallete.primaryColor,
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? const Padding(
                padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Pallete.primaryColor,
                    inactiveTrackColor:
                    Pallete.primaryColor.withValues(alpha: 0.18),
                    thumbColor: Pallete.primaryColor,
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs > 0 ? totalMs.toDouble() : 1,
                    value: totalMs > 0 ? posMs.toDouble() : 0,
                    onChangeStart:
                    totalMs > 0 ? (_) => _seeking = true : null,
                    onChanged: totalMs > 0
                        ? (v) => setState(
                            () => _position = Duration(milliseconds: v.round()))
                        : null,
                    onChangeEnd: totalMs > 0
                        ? (v) async {
                      _seeking = false;
                      try {
                        await _player
                            .seek(Duration(milliseconds: v.round()));
                      } catch (_) {}
                    }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _failed
                            ? "Couldn't play voice note"
                            : _fmt(_position),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _failed
                              ? Pallete.kRed
                              : theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      Text(
                        _fmt(_duration),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}