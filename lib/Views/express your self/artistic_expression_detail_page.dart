// lib/Views/express_your_self/artistic_expression_detail_page.dart

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:therapylink/utils/colors.dart';

enum Tool { pen, emoji, shape, eraser }
enum ShapeType { rectangle, circle, triangle, line, star }

extension on String {
  String capitalize() =>
      isEmpty ? this : substring(0, 1).toUpperCase() + substring(1);
}

class ArtisticExpressionDetailPage extends StatefulWidget {
  final String? entryId;
  const ArtisticExpressionDetailPage({super.key, this.entryId});

  @override
  _ArtisticExpressionDetailPageState createState() =>
      _ArtisticExpressionDetailPageState();
}

class _ArtisticExpressionDetailPageState
    extends State<ArtisticExpressionDetailPage> {
  final GlobalKey _canvasKey = GlobalKey();

  List<DrawnLine> _lines = [];
  DrawnLine? _currentLine;
  List<CanvasShape> _shapes = [];
  List<CanvasEmoji> _emojis = [];

  Tool _tool = Tool.pen;
  ShapeType _shape = ShapeType.rectangle;
  Color _color = Colors.white;
  double _thickness = 4.0;
  String _emoji = '😀';

  bool _showEmojiPicker = false;
  bool _showShapePicker = false;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .collection('artWorks')
        .doc(widget.entryId)
        .get();
    if (!doc.exists) return;
    final data = doc.data()!;
    // load lines
    final rawLines = data['lines'] as List? ?? [];
    _lines = rawLines.map((l) {
      final pts = (l['points'] as List)
          .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList();
      return DrawnLine(
        points: pts,
        paint: Paint()
          ..color = Color(l['color'] as int)
          ..strokeWidth = (l['strokeWidth'] as num).toDouble()
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
      );
    }).toList();

    // load shapes
    final rawShapes = data['shapes'] as List? ?? [];
    _shapes = rawShapes.map((s) {
      return CanvasShape(
        type: ShapeType.values.firstWhere((e) => describeEnum(e) == s['type']),
        offset: Offset((s['dx'] as num).toDouble(), (s['dy'] as num).toDouble()),
        paint: Paint()
          ..color = Color(s['color'] as int)
          ..strokeWidth = (s['strokeWidth'] as num).toDouble()
          ..style = PaintingStyle.stroke,
      );
    }).toList();

    // load emojis
    final rawEmojis = data['emojis'] as List? ?? [];
    _emojis = rawEmojis.map((e) {
      return CanvasEmoji(
        emoji: e['emoji'] as String,
        offset: Offset((e['dx'] as num).toDouble(), (e['dy'] as num).toDouble()),
      );
    }).toList();

    setState(() {});
  }

  // Drawing / Erasing / Shapes / Emoji

  void _startLine(Offset p) {
    _currentLine = DrawnLine(
      points: [p],
      paint: Paint()
        ..color = _color
        ..strokeWidth = _thickness
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
    _lines.add(_currentLine!);
  }

  void _onPanStart(DragStartDetails d) {
    final p = (context.findRenderObject() as RenderBox)
        .globalToLocal(d.globalPosition);
    if (_tool == Tool.pen) {
      _startLine(p);
    } else if (_tool == Tool.eraser) {
      _eraseAt(p);
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final p = (context.findRenderObject() as RenderBox)
        .globalToLocal(d.globalPosition);
    if (_tool == Tool.pen && _currentLine != null) {
      _currentLine!.points.add(p);
    } else if (_tool == Tool.eraser) {
      _eraseAt(p);
    }
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) => _currentLine = null;

  void _onTapDown(TapDownDetails d) {
    final p = (context.findRenderObject() as RenderBox)
        .globalToLocal(d.globalPosition);
    if (_tool == Tool.emoji) {
      _emojis.add(CanvasEmoji(emoji: _emoji, offset: p));
    } else if (_tool == Tool.shape) {
      _shapes.add(CanvasShape(
        type: _shape,
        offset: p,
        paint: Paint()
          ..color = _color
          ..strokeWidth = _thickness
          ..style = PaintingStyle.stroke,
      ));
    } else if (_tool == Tool.eraser) {
      _eraseAt(p);
    }
    setState(() {});
  }

  void _eraseAt(Offset p) {
    const tol = 50.0;
    // erase lines
    for (var i = _lines.length - 1; i >= 0; i--) {
      if (_lines[i].points.any((pt) => (pt - p).distance < tol)) {
        _lines.removeAt(i);
        return;
      }
    }
    // erase shapes
    for (var i = _shapes.length - 1; i >= 0; i--) {
      if ((_shapes[i].offset - p).distance < tol + _shapes[i].paint.strokeWidth) {
        _shapes.removeAt(i);
        return;
      }
    }
    // erase emojis
    for (var i = _emojis.length - 1; i >= 0; i--) {
      if ((_emojis[i].offset - p).distance < tol) {
        _emojis.removeAt(i);
        return;
      }
    }
  }

  // Save / Clear

  Future<void> _save() async {
    try {
      // render to image
      final boundary = _canvasKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 3.0);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = bd!.buffer.asUint8List();
      final b64 = base64Encode(bytes);

      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;
      final now = DateTime.now();
      final fmt = DateFormat('yyyy-MM-dd • HH:mm').format(now);
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .collection('artWorks');

      // prepare JSON arrays
      final linesJson = _lines.map((l) {
        return {
          'points': l.points
              .map((p) => {'x': p.dx, 'y': p.dy})
              .toList(),
          'color': l.paint.color.value,
          'strokeWidth': l.paint.strokeWidth,
        };
      }).toList();
      final shapesJson = _shapes.map((s) {
        return {
          'type': describeEnum(s.type),
          'dx': s.offset.dx,
          'dy': s.offset.dy,
          'color': s.paint.color.value,
          'strokeWidth': s.paint.strokeWidth,
        };
      }).toList();
      final emojisJson = _emojis.map((e) {
        return {
          'emoji': e.emoji,
          'dx': e.offset.dx,
          'dy': e.offset.dy,
        };
      }).toList();

      final data = {
        'base64Image': b64,
        'formattedDate': fmt,
        'timestamp': now,
        'lines': linesJson,
        'shapes': shapesJson,
        'emojis': emojisJson,
      };

      if (widget.entryId != null) {
        await col.doc(widget.entryId!).update(data);
      } else {
        await col.add(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }
  }

  void _clearAll() {
    _lines.clear();
    _shapes.clear();
    _emojis.clear();
    setState(() {});
  }

  Widget _toolBtn(IconData icon, String label, Tool t) {
    final sel = _tool == t;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tool = t;
          _showEmojiPicker = t == Tool.emoji;
          _showShapePicker = t == Tool.shape;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: sel ? Colors.amber : Colors.white),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _shapeBtn(IconData icon, ShapeType s) {
    final sel = _shape == s;
    return GestureDetector(
      onTap: () => setState(() => _shape = s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: sel ? Colors.amber : Colors.white),
          const SizedBox(height: 2),
          Text(describeEnum(s).capitalize(),
              style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId != null ? "Edit Art" : "New Art",
            style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.bgpurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _clearAll),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTapDown: _onTapDown,
                child: CustomPaint(
                  painter: _CanvasPainter(_lines, _shapes, _emojis),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),

          // Emoji picker
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (_, em) => setState(() {
                  _emoji = em.emoji;
                  _showEmojiPicker = false;
                }),
                config: const Config(
                  emojiViewConfig: EmojiViewConfig(emojiSizeMax: 28, columns: 7),
                  skinToneConfig: SkinToneConfig(),
                  categoryViewConfig: CategoryViewConfig(),
                  bottomActionBarConfig: BottomActionBarConfig(),
                  searchViewConfig: SearchViewConfig(),
                ),
              ),
            ),

          // Shape picker
          if (_showShapePicker)
            Container(
              color: AppColors.bgpurple.withOpacity(0.9),
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _shapeBtn(Icons.crop_square, ShapeType.rectangle),
                  _shapeBtn(Icons.circle, ShapeType.circle),
                  _shapeBtn(Icons.change_history, ShapeType.triangle),
                  _shapeBtn(Icons.remove, ShapeType.line),
                  _shapeBtn(Icons.star_outline, ShapeType.star),
                ],
              ),
            ),

          // Tool bar
          Container(
            color: AppColors.bgpurple.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _toolBtn(Icons.brush, 'Pen', Tool.pen),
                _toolBtn(Icons.emoji_emotions_outlined, 'Emoji', Tool.emoji),
                _toolBtn(Icons.category, 'Shape', Tool.shape),
                _toolBtn(Icons.cleaning_services, 'Erase', Tool.eraser),
              ],
            ),
          ),

          // Color & thickness
          Container(
            color: AppColors.bgpurple.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 12),
                for (final c in [
                  Colors.white,
                  Colors.black,
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.yellow
                ])
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? Colors.amber : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                const Icon(Icons.brush, color: Colors.white70),
                Expanded(
                  child: Slider(
                    value: _thickness,
                    min: 1,
                    max: 20,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    onChanged: (v) => setState(() => _thickness = v),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Models

class DrawnLine {
  List<Offset> points;
  Paint paint;
  DrawnLine({required this.points, required this.paint});
}

class CanvasShape {
  ShapeType type;
  Offset offset;
  Paint paint;
  bool isBackground;
  CanvasShape({
    required this.type,
    required this.offset,
    required this.paint,
    this.isBackground = false,
  });
}

class CanvasEmoji {
  String emoji;
  Offset offset;
  CanvasEmoji({required this.emoji, required this.offset});
}

// Painter

class _CanvasPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final List<CanvasShape> shapes;
  final List<CanvasEmoji> emojis;
  const _CanvasPainter(this.lines, this.shapes, this.emojis);

  @override
  void paint(Canvas canvas, Size size) {
    // gradient background
    final paintBg = Paint()
      ..shader = const LinearGradient(
        colors: [
          AppColors.backgroundGradientStart,
          AppColors.backgroundGradientEnd
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBg);

    // shapes
    for (var s in shapes) {
      if (s.isBackground) {
        canvas.drawRect(Offset.zero & size, s.paint);
      } else {
        switch (s.type) {
          case ShapeType.rectangle:
            canvas.drawRect(
                Rect.fromCenter(center: s.offset, width: 100, height: 100),
                s.paint);
            break;
          case ShapeType.circle:
            canvas.drawCircle(s.offset, 50, s.paint);
            break;
          case ShapeType.triangle:
            const half = 50.0;
            final path = Path()
              ..moveTo(s.offset.dx, s.offset.dy - half)
              ..lineTo(s.offset.dx - half, s.offset.dy + half)
              ..lineTo(s.offset.dx + half, s.offset.dy + half)
              ..close();
            canvas.drawPath(path, s.paint);
            break;
          case ShapeType.line:
            canvas.drawLine(s.offset.translate(-50, 0),
                s.offset.translate(50, 0), s.paint);
            break;
          case ShapeType.star:
            const outer = 50.0, inner = 25.0;
            final path = Path();
            for (int i = 0; i < 5; i++) {
              final a = (math.pi * 2 * i / 5) - math.pi / 2;
              final x = s.offset.dx + outer * math.cos(a);
              final y = s.offset.dy + outer * math.sin(a);
              if (i == 0) {
                path.moveTo(x, y);
              } else {
                path.lineTo(x, y);
              }
              final a2 = a + math.pi / 5;
              final x2 = s.offset.dx + inner * math.cos(a2);
              final y2 = s.offset.dy + inner * math.sin(a2);
              path.lineTo(x2, y2);
            }
            path.close();
            canvas.drawPath(path, s.paint);
            break;
        }
      }
    }

    // freehand strokes
    for (var ln in lines) {
      for (var i = 0; i < ln.points.length - 1; i++) {
        final p1 = ln.points[i], p2 = ln.points[i + 1];
        if (p1 != Offset.zero && p2 != Offset.zero) {
          canvas.drawLine(p1, p2, ln.paint);
        }
      }
    }

    // emojis
    for (var e in emojis) {
      final tp = TextPainter(
        text: TextSpan(text: e.emoji, style: const TextStyle(fontSize: 32)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, e.offset - const Offset(16, 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
