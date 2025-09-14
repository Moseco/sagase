import 'dart:io';
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
  final void Function() onImageProcessed;
  final void Function() onImageError;
  final void Function(String) onTextSelected;
  final bool locked;
  final bool singleSelection;

  const OcrImage({
    super.key,
    required this.image,
    required this.onImageProcessed,
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
    widget.onImageProcessed();

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
              child: CustomPaint(
                foregroundPainter: recognizedTextBlocks == null
                    ? null
                    : OcrPainter(
                        recognizedTextBlocks!,
                        imageSize,
                        onSelect,
                      ),
                child: Image.memory(image),
              ),
            ),
          );
        },
      );
    } else {
      // TODO
      return LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            constrained: true,
            child: CustomPaint(
              foregroundPainter: recognizedTextBlocks == null
                  ? null
                  : OcrPainter(
                      recognizedTextBlocks!,
                      imageSize,
                      onSelect,
                    ),
              child: Image.memory(image),
            ),
          );
        },
      );
      // return LayoutBuilder(
      //   builder: (context, constraints) {
      //     return InteractiveViewer(
      //       constrained: false,
      //       child: CustomPaint(
      //         foregroundPainter: recognizedTextBlocks == null
      //             ? null
      //             : OcrPainter(
      //                 recognizedTextBlocks!,
      //                 imageSize,
      //               ),
      //         // child: IgnorePointer(
      //         //   child: FittedBox(
      //         //     clipBehavior: Clip.hardEdge,
      //         //     fit: BoxFit.contain,
      //         //     child: Image.memory(image),
      //         //   ),
      //         // ),
      //         // child: IgnorePointer(
      //         //   child: SizedBox(
      //         //     width: MediaQuery.of(context).size.width,
      //         //     child: FittedBox(
      //         //       clipBehavior: Clip.hardEdge,
      //         //       fit: BoxFit.contain,
      //         //       child: Image.memory(image),
      //         //     ),
      //         //   ),
      //         // ),
      //         child: IgnorePointer(
      //           child: SizedBox(
      //             width: constraints.maxWidth,
      //             child: Image.memory(
      //               image,
      //               // fit: BoxFit.fitWidth,
      //               fit: BoxFit.cover,
      //             ),
      //           ),
      //         ),
      //       ),
      //     );
      //   },
      // );
    }

    // return CustomPaint(
    //   foregroundPainter: recognizedTextBlocks == null
    //       ? null
    //       : OcrPainter(
    //           recognizedTextBlocks!,
    //           imageSize,
    //         ),
    //   child: Container(
    //     decoration: BoxDecoration(
    //       image: DecorationImage(
    //         image: MemoryImage(image),
    //         fit: BoxFit.cover,
    //       ),
    //     ),
    //   ),
    // );

    // return Container(
    //   decoration: BoxDecoration(
    //     image: DecorationImage(
    //       image: MemoryImage(image),
    //       fit: BoxFit.cover,
    //     ),
    //   ),
    // );

    // return Center(
    //   child: GestureDetector(
    //     // onTap: () => viewModel.rebuildUi(),
    //     child: CustomPaint(
    //       foregroundPainter: recognizedTextBlocks == null
    //           ? null
    //           : OcrPainter(
    //               recognizedTextBlocks!,
    //               imageSize,
    //             ),
    //       child: IgnorePointer(
    //         child: Image.memory(
    //           image,
    //           fit: BoxFit.fitWidth,
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }
}
