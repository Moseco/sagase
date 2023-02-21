import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StrokeOrderDiagramLarge extends StatelessWidget {
  final List<String> strokes;
  final int page;

  const StrokeOrderDiagramLarge({
    required this.strokes,
    required this.page,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final initialCoordinateStarting = RegExp(r'M|m');
    final initialCoordinateEnding = RegExp(r'C|c|S|s');
    String currentStrokeColor =
        Theme.of(context).brightness == Brightness.light ? 'black' : 'white';

    // Create svg widget from path data for the current stroke (page)
    final buffer = StringBuffer(
      '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg xmlns="http://www.w3.org/2000/svg" width="109" height="109" viewBox="0 0 109 109">
<g style="fill:none;stroke:grey;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;">
''',
    );

    // Add paths up to the current stroke in the same color
    for (int j = 0; j < page; j++) {
      buffer.write('<path d="');
      buffer.write(strokes[j]);
      buffer.write('"/>');
    }

    // Add path for current stroke in different color from previous strokes
    buffer.write('<path stroke="$currentStrokeColor" d="');
    buffer.write(strokes[page]);
    buffer.write('"/></g>');

    // Add circle at start of current stroke
    try {
      List<String> initialCoordinates = strokes[page]
          .substring(
            strokes[page].indexOf(initialCoordinateStarting) + 1,
            strokes[page].indexOf(initialCoordinateEnding),
          )
          .split(',');

      buffer.write(
          '<circle fill="$currentStrokeColor" r="3" cx="${initialCoordinates[0]}" cy="${initialCoordinates[1]}"/>');
    } catch (_) {}

    // Add closing svg tag
    buffer.write('</svg>');

    return LayoutBuilder(
      builder: (context, constraints) {
        double length = min(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          painter: _GridPainter(
            color: Colors.grey[700]!,
            strokeWidth: 1,
            dashLength: 4,
            dashSpaceLength: 3,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: SvgPicture.string(
              buffer.toString(),
              width: length,
              height: length,
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpaceLength;

  const _GridPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpaceLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    double startX = 1;
    while (startX < size.width - 1) {
      canvas.drawLine(
        Offset(startX, size.width / 2),
        Offset(startX + dashLength, size.width / 2),
        paint,
      );
      startX += dashLength + dashSpaceLength;
    }

    double startY = 1;
    while (startY < size.height - 1) {
      canvas.drawLine(
        Offset(size.height / 2, startY),
        Offset(size.height / 2, startY + dashLength),
        paint,
      );
      startY += dashLength + dashSpaceLength;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
