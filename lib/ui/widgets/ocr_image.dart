import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sagase/datamodels/recognized_text_block.dart';
import 'package:sagase/ui/painters/ocr_painter.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:shimmer/shimmer.dart';

class OcrImage extends StatefulWidget {
  final XFile image;
  final void Function(int)? onImageProcessed;
  final void Function() onImageError;
  final void Function(String) onTextSelected;
  final bool locked;
  final bool singleSelection;

  const OcrImage({
    super.key,
    required this.image,
    this.onImageProcessed,
    required this.onImageError,
    required this.locked,
    required this.onTextSelected,
    required this.singleSelection,
  });

  @override
  State<StatefulWidget> createState() => _OcrImageState();
}

class _OcrImageState extends State<OcrImage> {
  final _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.japanese);
  Uint8List? _currentImageBytes;
  late Size _imageSize;
  List<RecognizedTextBlock>? _recognizedTextBlocks;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final ocrImageDir = path.join(
      (await path_provider.getApplicationCacheDirectory()).path,
      constants.ocrImagesDir,
    );
    await Directory(ocrImageDir).create();

    final imagePath = path.join(ocrImageDir, widget.image.name);
    try {
      await File(widget.image.path).rename(imagePath);
    } catch (_) {
      if (File(widget.image.path).existsSync()) {
        File(widget.image.path).delete();
      }

      widget.onImageError();
      return;
    }

    final rotatedImage = await FlutterExifRotation.rotateImage(path: imagePath);

    final inputImage = InputImage.fromFilePath(rotatedImage.path);
    _currentImageBytes = await rotatedImage.readAsBytes();

    if (inputImage.metadata != null) {
      _imageSize = inputImage.metadata!.size;
    } else {
      final decodedImage = await decodeImageFromList(_currentImageBytes!);
      _imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
    }

    setState(() {});

    final recognizedText = await _textRecognizer.processImage(inputImage);

    _recognizedTextBlocks = [];
    for (final textBlock in recognizedText.blocks) {
      _recognizedTextBlocks!.add(
        RecognizedTextBlock(
          text: textBlock.text,
          points: textBlock.cornerPoints,
        ),
      );
    }

    setState(() {});

    if (widget.onImageProcessed != null) {
      widget.onImageProcessed!(_recognizedTextBlocks!.length);
    }

    await rotatedImage.delete();
  }

  void handleSelect(RecognizedTextBlock textBlock) {
    setState(() {
      if (!textBlock.selected) {
        widget.onTextSelected(textBlock.text);
      }

      if (widget.singleSelection) {
        for (final textBlock in _recognizedTextBlocks!) {
          textBlock.selected = false;
        }
      }

      textBlock.selected = true;
      _recognizedTextBlocks = List.from(_recognizedTextBlocks!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _currentImageBytes == null
        ? _OcrImageLoading()
        : _OcrImage(
            recognizedTextBlocks: _recognizedTextBlocks,
            imageSize: _imageSize,
            image: _currentImageBytes!,
            locked: widget.locked,
            onSelect: handleSelect,
          );
  }
}

class _OcrImageLoading extends StatelessWidget {
  const _OcrImageLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF3a3a3a) : Colors.grey.shade300,
        highlightColor: isDark ? const Color(0xFF4a4a4a) : Colors.grey.shade100,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class _OcrImage extends StatelessWidget {
  final List<RecognizedTextBlock>? recognizedTextBlocks;
  final Size imageSize;
  final Uint8List image;
  final bool locked;
  final void Function(RecognizedTextBlock) onSelect;

  const _OcrImage({
    this.recognizedTextBlocks,
    required this.imageSize,
    required this.image,
    required this.locked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              clipBehavior: Clip.hardEdge,
              fit: BoxFit.cover,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _handleTapUp,
                child: CustomPaint(
                  foregroundPainter: OcrPainter(
                    recognizedTextBlocks!,
                    imageSize,
                  ),
                  child: Image.memory(image),
                ),
              ),
            ),
          );
        },
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            constrained: false,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: FittedBox(
                clipBehavior: Clip.hardEdge,
                fit: BoxFit.contain,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _handleTapUp,
                  child: CustomPaint(
                    foregroundPainter: OcrPainter(
                      recognizedTextBlocks,
                      imageSize,
                    ),
                    child: Image.memory(image),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (recognizedTextBlocks != null) {
      for (final textBlock in recognizedTextBlocks!) {
        if (_pointInsideRectangle(details.localPosition, textBlock.offsets)) {
          onSelect(textBlock);
          break;
        }
      }
    }
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
