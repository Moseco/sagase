import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/constants.dart' show radicals;

import 'kanji_viewmodel.dart';

class KanjiView extends StatelessWidget {
  final Kanji kanji;

  const KanjiView(this.kanji, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiViewModel>.reactive(
      viewModelBuilder: () => KanjiViewModel(kanji),
      fireOnModelReadyOnce: true,
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(kanji.kanji),
          actions: [
            IconButton(
              onPressed: viewModel.openMyDictionaryListsSheet,
              icon: Icon(
                kanji.myDictionaryListLinks.isEmpty
                    ? Icons.star_border
                    : Icons.star,
              ),
            ),
          ],
        ),
        // Can throw exception "'!_selectionStartsInScrollable': is not true."
        // when long press then try to scroll on disabled areas.
        // But seems to work okay in release builds.
        body: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      kanji.kanji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  Expanded(child: Text(kanji.meanings ?? 'NO MEANING')),
                ],
              ),
              _StrokeOrder(kanji.strokes),
              CardWithTitleSection(
                title: 'Reading',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kanji.onReadings != null)
                        _TitleInfoText(
                          title: 'On readings',
                          content: kanji.onReadings!.join(', '),
                        ),
                      if (kanji.kunReadings != null)
                        KanjiKunReadings(
                          kanji.kunReadings!,
                          leading: const TextSpan(
                            text: 'Kun readings: ',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          maxLines: 99,
                        ),
                      if (kanji.nanori != null)
                        _TitleInfoText(
                          title: 'Nanori',
                          content: kanji.nanori!.join(', '),
                        ),
                    ],
                  ),
                ),
              ),
              CardWithTitleSection(
                title: 'Info',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleInfoText(
                        title: 'Radical',
                        content: radicals[kanji.radical].radical,
                      ),
                      if (kanji.components != null)
                        _TitleInfoText(
                          title: 'Components',
                          content: kanji.components!.join(', '),
                        ),
                      _TitleInfoText(
                        title: 'Stroke count',
                        content: kanji.strokeCount.toString(),
                      ),
                      if (kanji.grade != 255)
                        _TitleInfoText(
                          title: 'Grade',
                          content: kanji.grade.toString(),
                        ),
                      if (kanji.frequency != null)
                        _TitleInfoText(
                          title: 'Frequency',
                          content: kanji.frequency.toString(),
                        ),
                      if (kanji.jlpt != 255)
                        _TitleInfoText(
                          title: 'JLPT',
                          content: kanji.jlpt.toString(),
                        ),
                    ],
                  ),
                ),
              ),
              if (kanji.compounds.isNotEmpty)
                SelectionContainer.disabled(
                  child: CardWithTitleSection(
                    title: 'Compounds',
                    child: Column(
                      children: [
                        ListView.separated(
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Colors.grey,
                            indent: 8,
                            endIndent: 8,
                          ),
                          shrinkWrap: true,
                          primary: false,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: kanji.compounds.length < 10
                              ? kanji.compounds.length
                              : 10,
                          itemBuilder: (context, index) => VocabListItem(
                            vocab: kanji.compounds.elementAt(index),
                            onPressed: () => viewModel.navigateToVocab(
                                kanji.compounds.elementAt(index)),
                          ),
                        ),
                        if (kanji.compounds.length > 10)
                          TextButton(
                            onPressed: viewModel.showAllCompounds,
                            child: const Text('Show all compounds'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleInfoText extends StatelessWidget {
  final String title;
  final String content;

  const _TitleInfoText({
    required this.title,
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(
            text: ': ',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: content,
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class _StrokeOrder extends ViewModelWidget<KanjiViewModel> {
  final List<String>? strokes;

  const _StrokeOrder(
    this.strokes, {
    Key? key,
  }) : super(key: key, reactive: false);

  @override
  Widget build(BuildContext context, KanjiViewModel viewModel) {
    if (strokes == null || strokes!.isEmpty) {
      return const Text('Stroke order unavailable');
    } else {
      final initialCoordinateStarting = RegExp(r'M|m');
      final initialCoordinateEnding = RegExp(r'C|c|S|s');

      List<Widget> svgs = [];

      // Create svg widgets from path data
      for (int i = 0; i < strokes!.length; i++) {
        final buffer = StringBuffer(
          '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg xmlns="http://www.w3.org/2000/svg" width="109" height="109" viewBox="0 0 109 109">
<g style="fill:none;stroke:grey;stroke-width:3;stroke-linecap:round;stroke-linejoin:round;">
''',
        );

        // Add paths up to the current stroke in the same color
        for (int j = 0; j < i; j++) {
          buffer.write('<path d="');
          buffer.write(strokes![j]);
          buffer.write('"/>');
        }

        // Add path for current stroke in different color from previous strokes
        buffer.write('<path stroke="black" d="');
        buffer.write(strokes![i]);
        buffer.write('"/></g>');

        // Add circle at start of current stroke
        try {
          List<String> initialCoordinates = strokes![i]
              .substring(
                strokes![i].indexOf(initialCoordinateStarting) + 1,
                strokes![i].indexOf(initialCoordinateEnding),
              )
              .split(',');

          buffer.write(
              '<circle fill="red" r="4" cx="${initialCoordinates[0]}" cy="${initialCoordinates[1]}"/>');
        } catch (_) {}

        // Add closing svg tag
        buffer.write('</svg>');

        svgs.add(
          CustomPaint(
            painter: _GridPainter(
              color: Colors.grey[400]!,
              strokeWidth: 1,
              dashLength: 4,
              dashSpaceLength: 3,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 1),
              ),
              child: SvgPicture.string(
                buffer.toString(),
                width: 60,
                height: 60,
              ),
            ),
          ),
        );
      }

      return Wrap(
        spacing: -1,
        runSpacing: -1,
        children: svgs,
      );
    }
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
