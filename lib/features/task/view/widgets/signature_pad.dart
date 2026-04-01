import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// Requires NO extra packages — pure Flutter canvas.

class SignaturePadSheet extends StatefulWidget {
  final String? signerLabel; // e.g. "Customer" | "Supervisor" | "Manager"
  final void Function(String base64Png) onSigned;

  const SignaturePadSheet({
    super.key,
    required this.onSigned,
    this.signerLabel,
  });

  static Future<void> show(
      BuildContext context, {
        required void Function(String base64Png) onSigned,
        String? signerLabel,
      }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        builder: (_) => SignaturePadSheet(onSigned: onSigned, signerLabel: signerLabel),
      );

  @override
  State<SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends State<SignaturePadSheet> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  final _repaintKey = GlobalKey();
  bool _isEmpty = true;
  bool _exporting = false;

  static const _kInk = Color(0xFF1a1a2e);
  static const _kCanvas = Colors.white;

  void _onPanStart(DragStartDetails d) {
    _currentStroke = [d.localPosition];
    setState(() => _isEmpty = false);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _currentStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    _strokes.add(List.from(_currentStroke));
    _currentStroke = [];
    setState(() {});
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _isEmpty = true;
    });
  }

  Future<void> _confirm() async {
    if (_isEmpty) return;
    setState(() => _exporting = true);

    try {
      // Capture canvas as PNG bytes
      final boundary = _repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final b64 = _bytesToBase64(bytes);

      widget.onSigned(b64);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Signature export error: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // Simple base64 without importing dart:convert (avoid extra dep confusion)
  String _bytesToBase64(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buf = StringBuffer();
    for (int i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      buf.write(chars[(b0 >> 2) & 63]);
      buf.write(chars[((b0 & 3) << 4) | ((b1 >> 4) & 15)]);
      buf.write(i + 1 < bytes.length ? chars[((b1 & 15) << 2) | ((b2 >> 6) & 3)] : '=');
      buf.write(i + 2 < bytes.length ? chars[b2 & 63] : '=');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final sw = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 60, 12, 0),
      decoration: const BoxDecoration(
        color: Color(0xFF12121E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(99)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.draw_rounded, color: Color(0xFF6C63FF), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signature Required',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        if (widget.signerLabel != null)
                          Text(
                            'Sign below — ${widget.signerLabel}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clear,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh_rounded, color: Colors.white54, size: 14),
                            SizedBox(width: 5),
                            Text('Clear', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),

          // ── Canvas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: RepaintBoundary(
                key: _repaintKey,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: Container(
                    width: double.infinity,
                    height: 240,
                    color: _kCanvas,
                    child: CustomPaint(
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                        inkColor: _kInk,
                      ),
                      child: _isEmpty
                          ? Center(
                        child: Text(
                          'Sign here',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.withValues(alpha: 0.35),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Footer line guide hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('X', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w900)),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Buttons
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('Cancel', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _isEmpty || _exporting ? null : _confirm,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: _isEmpty
                            ? null
                            : const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)]),
                        color: _isEmpty ? Colors.white12 : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isEmpty ? null : [
                          BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Center(
                        child: _exporting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                            : Text(
                          'Confirm Signature',
                          style: TextStyle(
                            color: _isEmpty ? Colors.white30 : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
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

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color inkColor;

  const _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.inkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = inkColor
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> pts) {
      if (pts.length < 2) {
        if (pts.length == 1) canvas.drawCircle(pts.first, 1.5, paint..style = PaintingStyle.fill);
        return;
      }
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length - 1; i++) {
        final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }

    for (final s in strokes) drawStroke(s);
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}