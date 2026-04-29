// lib/features/widgets/image_preview.dart
//
// Usage anywhere in the app:
//
//   // Network image (Cloudinary URL)
//   ImagePreview.show(context, url: 'https://res.cloudinary.com/...');
//
//   // Local file (captured photo before upload)
//   ImagePreview.show(context, file: capturedPhoto);
//
//   // With hero tag (wrap your thumbnail in Hero(tag: tag) for a smooth transition)
//   ImagePreview.show(context, url: url, heroTag: 'step_photo_123');

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImagePreview {
  /// Open the full-screen viewer.
  ///
  /// Supply either [url] (network) or [file] (local), not both.
  /// [heroTag] — optional; wrap the source thumbnail in a Hero widget
  ///             with the same tag for a seamless open/close transition.
  /// [label]   — optional caption shown at the bottom (e.g. "Photo Proof").
  static void show(
      BuildContext context, {
        String? url,
        File?   file,
        String? heroTag,
        String? label,
      }) {
    assert(url != null || file != null, 'Provide either url or file');

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque:              false,
        barrierColor:        Colors.transparent,
        transitionDuration:  const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: _ImagePreviewPage(
              url:     url,
              file:    file,
              heroTag: heroTag,
              label:   label,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ImagePreviewPage extends StatefulWidget {
  final String? url;
  final File?   file;
  final String? heroTag;
  final String? label;

  const _ImagePreviewPage({this.url, this.file, this.heroTag, this.label});

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage>
    with TickerProviderStateMixin {

  late final TransformationController _transformCtrl;
  late final AnimationController      _bgCtrl;
  late final AnimationController      _resetCtrl;
  Animation<Matrix4>?                 _resetAnimation;

  // Track vertical drag for swipe-to-dismiss
  double _dragOffset = 0;
  bool   _isDragging = false;

  static const double _kMinScale = 1.0;
  static const double _kMaxScale = 5.0;

  @override
  void initState() {
    super.initState();
    _transformCtrl = TransformationController();
    _bgCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _resetCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 260),
    );

    // Hide status bar for a true full-screen feel
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    _bgCtrl.dispose();
    _resetCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Double-tap to zoom in / reset ─────────────────────────────────────────
  void _onDoubleTapDown(TapDownDetails details) {
    final isZoomedIn = _transformCtrl.value != Matrix4.identity();

    final Matrix4 target;
    if (isZoomedIn) {
      target = Matrix4.identity();
    } else {
      // Zoom to 2.5× centred on the tap point
      final pos   = details.localPosition;
      const scale = 2.5;
      target = Matrix4.identity()
        ..translate(-pos.dx * (scale - 1), -pos.dy * (scale - 1))
        ..scale(scale);
    }

    _resetAnimation = Matrix4Tween(
      begin: _transformCtrl.value,
      end:   target,
    ).animate(CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutCubic));

    _resetAnimation!.addListener(() {
      _transformCtrl.value = _resetAnimation!.value;
    });

    _resetCtrl
      ..reset()
      ..forward();
  }

  // ── Swipe-to-dismiss logic (only when not zoomed in) ─────────────────────
  bool get _isAtIdentity =>
      _transformCtrl.value.getMaxScaleOnAxis() < 1.05;

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (!_isAtIdentity) return;
    setState(() {
      _isDragging = true;
      _dragOffset += d.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (!_isAtIdentity) return;
    if (_dragOffset.abs() > 80 ||
        d.primaryVelocity != null && d.primaryVelocity!.abs() > 600) {
      _close();
    } else {
      setState(() { _dragOffset = 0; _isDragging = false; });
    }
  }

  void _close() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pop();
  }

  // ── Background opacity tied to drag distance ──────────────────────────────
  double get _bgOpacity {
    if (!_isDragging) return 1.0;
    return (1.0 - (_dragOffset.abs() / 250)).clamp(0.3, 1.0);
  }

  // ── Build the image widget ─────────────────────────────────────────────────
  Widget _buildImage() {
    final image = widget.file != null
        ? Image.file(widget.file!,     fit: BoxFit.contain)
        : Image.network(
      widget.url!,
      fit:          BoxFit.contain,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                progress.expectedTotalBytes!
                : null,
            color: Colors.white54,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (_, __, ___) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.broken_image_rounded, color: Colors.white38, size: 56),
          SizedBox(height: 12),
          Text('Could not load image',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: image);
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd:    _onVerticalDragEnd,
      child: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, __) {
          return Scaffold(
            backgroundColor: Colors.black.withValues(
              alpha: _bgOpacity * CurvedAnimation(
                parent: _bgCtrl, curve: Curves.easeOut,
              ).value,
            ),
            body: Stack(
              children: [

                // ── Zoomable image ───────────────────────────────────────────
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, _dragOffset),
                    child: GestureDetector(
                      onDoubleTapDown: _onDoubleTapDown,
                      onDoubleTap:     () {},   // consumed by onDoubleTapDown
                      child: InteractiveViewer(
                        transformationController: _transformCtrl,
                        minScale:  _kMinScale,
                        maxScale:  _kMaxScale,
                        clipBehavior: Clip.none,
                        child: Center(child: _buildImage()),
                      ),
                    ),
                  ),
                ),

                // ── Top bar: close button + label ────────────────────────────
                Positioned(
                  top:   0,
                  left:  0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity:  _isDragging ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            // Close button
                            GestureDetector(
                              onTap: _close,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:        Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white12, width: 1),
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Label
                            if (widget.label != null)
                              Expanded(
                                child: Text(
                                  widget.label!,
                                  style: const TextStyle(
                                    color:      Colors.white,
                                    fontSize:   15,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 8),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom hint (shown only when not zoomed) ─────────────────
                Positioned(
                  bottom: 0,
                  left:   0,
                  right:  0,
                  child: AnimatedOpacity(
                    opacity: _isDragging ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color:        Colors.black45,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Pinch or double-tap to zoom  •  Swipe down to close',
                              style: TextStyle(
                                  color:    Colors.white54,
                                  fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}