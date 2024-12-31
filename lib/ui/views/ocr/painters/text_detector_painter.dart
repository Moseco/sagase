import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sagase/datamodels/recognized_text_block.dart';

class TextRecognizerPainter extends CustomPainter {
  final List<RecognizedTextBlock> recognizedTextBlocks;
  final Size imageSize;

  TextRecognizerPainter(this.recognizedTextBlocks, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final unselectedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.blueGrey;

    final selectedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.lightGreenAccent;

    for (final textBlock in recognizedTextBlocks) {
      final List<Offset> cornerPoints = [];
      for (final point in textBlock.points) {
        double x = point.x.toDouble() * size.width / imageSize.width;
        double y = point.y.toDouble() * size.height / imageSize.height;
        cornerPoints.add(Offset(x, y));
      }

      textBlock.offsets = List.from(cornerPoints);

      cornerPoints.add(cornerPoints.first);
      canvas.drawPoints(
        PointMode.polygon,
        cornerPoints,
        textBlock.selected ? selectedPaint : unselectedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TextRecognizerPainter oldDelegate) {
    //TODO figure out efficient way to detect change?
    return true;
    // return oldDelegate.recognizedTextBlocks != recognizedTextBlocks;
  }

  @override
  bool? hitTest(Offset position) {
    for (final textBlock in recognizedTextBlocks) {
      if (_pointInsideRectangle(position, textBlock.offsets)) {
        textBlock.selected = true;
        return true;
      }
    }

    return false;
  }

  bool _pointInsideRectangle(Offset point, List<Offset> rectCorners) {
    double x1 = rectCorners[0].dx;
    double x2 = rectCorners[1].dx;
    double x3 = rectCorners[2].dx;
    double x4 = rectCorners[3].dx;

    double y1 = rectCorners[0].dy;
    double y2 = rectCorners[1].dy;
    double y3 = rectCorners[2].dy;
    double y4 = rectCorners[3].dy;

    double a1 = sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
    double a2 = sqrt((x2 - x3) * (x2 - x3) + (y2 - y3) * (y2 - y3));
    double a3 = sqrt((x3 - x4) * (x3 - x4) + (y3 - y4) * (y3 - y4));
    double a4 = sqrt((x4 - x1) * (x4 - x1) + (y4 - y1) * (y4 - y1));

    double b1 = sqrt(
        (x1 - point.dx) * (x1 - point.dx) + (y1 - point.dy) * (y1 - point.dy));
    double b2 = sqrt(
        (x2 - point.dx) * (x2 - point.dx) + (y2 - point.dy) * (y2 - point.dy));
    double b3 = sqrt(
        (x3 - point.dx) * (x3 - point.dx) + (y3 - point.dy) * (y3 - point.dy));
    double b4 = sqrt(
        (x4 - point.dx) * (x4 - point.dx) + (y4 - point.dy) * (y4 - point.dy));

    double u1 = (a1 + b1 + b2) / 2;
    double u2 = (a2 + b2 + b3) / 2;
    double u3 = (a3 + b3 + b4) / 2;
    double u4 = (a4 + b4 + b1) / 2;

    double area1 = sqrt(u1 * (u1 - a1) * (u1 - b1) * (u1 - b2));
    double area2 = sqrt(u2 * (u2 - a2) * (u2 - b2) * (u2 - b3));
    double area3 = sqrt(u3 * (u3 - a3) * (u3 - b3) * (u3 - b4));
    double area4 = sqrt(u4 * (u4 - a4) * (u4 - b4) * (u4 - b1));

    double difference = 0.95 * (area1 + area2 + area3 + area4) - a1 * a2;
    return difference < 1;
  }
}
