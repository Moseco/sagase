import 'package:flutter/material.dart' hide Ink;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

class HandWritingCanvas extends StatefulWidget {
  final void Function(Ink) onHandWritingChanged;
  final HandWritingController controller;

  const HandWritingCanvas({
    required this.onHandWritingChanged,
    required this.controller,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => HandWritingCanvasState();
}

class HandWritingCanvasState extends State<HandWritingCanvas> {
  final Ink _ink = Ink();
  List<StrokePoint> _points = [];

  @override
  void initState() {
    super.initState();
    widget.controller.clear = clear;
    widget.controller.undo = undo;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (DragStartDetails details) {
        _ink.strokes.add(Stroke());
      },
      onPanUpdate: (DragUpdateDetails details) {
        setState(() {
          final RenderObject? object = context.findRenderObject();
          final localPosition =
              (object as RenderBox?)?.globalToLocal(details.globalPosition);
          if (localPosition != null) {
            _points = List.from(_points)
              ..add(StrokePoint(
                x: localPosition.dx,
                y: localPosition.dy,
                t: DateTime.now().millisecondsSinceEpoch,
              ));
          }
          if (_ink.strokes.isNotEmpty) {
            _ink.strokes.last.points = _points.toList();
          }
        });
      },
      onPanEnd: (DragEndDetails details) {
        _points.clear();
        if (_ink.strokes.last.points.isEmpty) _ink.strokes.removeLast();
        setState(() {});
        widget.onHandWritingChanged(_ink);
      },
      child: ClipRect(
        child: CustomPaint(
          painter: _WritingPainter(ink: _ink),
          size: Size.infinite,
        ),
      ),
    );
  }

  void undo() {
    if (_ink.strokes.isNotEmpty) {
      setState(() {
        _ink.strokes.removeLast();
      });
      widget.onHandWritingChanged(_ink);
    }
  }

  void clear() {
    setState(() {
      _ink.strokes.clear();
    });
    widget.onHandWritingChanged(_ink);
  }
}

class _WritingPainter extends CustomPainter {
  Ink ink;

  _WritingPainter({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_WritingPainter oldDelegate) => true;
}

class HandWritingController {
  late VoidCallback undo;
  late VoidCallback clear;
}

class HandWritingControllerHook extends Hook<HandWritingController> {
  const HandWritingControllerHook();

  @override
  HandWritingControllerHookState createState() =>
      HandWritingControllerHookState();
}

class HandWritingControllerHookState
    extends HookState<HandWritingController, HandWritingControllerHook> {
  late HandWritingController controller;

  @override
  void initHook() {
    super.initHook();
    controller = HandWritingController();
  }

  @override
  HandWritingController build(BuildContext context) => controller;
}
