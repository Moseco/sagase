import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sagase/datamodels/recognized_text_block.dart';

class OcrPainter extends CustomPainter {
  final List<RecognizedTextBlock>? recognizedTextBlocks;
  final Size imageSize;

  OcrPainter(this.recognizedTextBlocks, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (recognizedTextBlocks != null) {
      final unselectedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.lightBlueAccent;

      final selectedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.lightGreenAccent;

      for (final textBlock in recognizedTextBlocks!) {
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
  }

  @override
  bool shouldRepaint(OcrPainter oldDelegate) {
    return oldDelegate.recognizedTextBlocks != recognizedTextBlocks;
  }
}
