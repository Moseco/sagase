import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'flashcard_set_info_viewmodel.dart';

class FlashcardSetInfoView extends StackedView<FlashcardSetInfoViewModel> {
  final FlashcardSet flashcardSet;

  const FlashcardSetInfoView(this.flashcardSet, {super.key});

  @override
  FlashcardSetInfoViewModel viewModelBuilder(BuildContext context) =>
      FlashcardSetInfoViewModel(flashcardSet);

  @override
  Widget builder(context, viewModel, child) {
    final now = DateTime.now();
    final dayFormatter = DateFormat.EEEE();
    return Scaffold(
      appBar: AppBar(title: Text(flashcardSet.name)),
      body: SafeArea(
        bottom: false,
        child: viewModel.upcomingDueFlashcards == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.only(
                  left: 8,
                  top: 8,
                  right: 8,
                  bottom: 8 + MediaQuery.of(context).padding.bottom,
                ),
                children: [
                  CardWithTitleSection(
                    title: 'Upcoming due flashcards',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Today'),
                                  const Text('Tomorrow'),
                                  Text(dayFormatter.format(
                                      now.add(const Duration(days: 2)))),
                                  Text(dayFormatter.format(
                                      now.add(const Duration(days: 3)))),
                                  Text(dayFormatter.format(
                                      now.add(const Duration(days: 4)))),
                                  Text(dayFormatter.format(
                                      now.add(const Duration(days: 5)))),
                                  Text(dayFormatter.format(
                                      now.add(const Duration(days: 6)))),
                                  const Text('Afterwards')
                                ],
                              ),
                            ),
                            const VerticalDivider(),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(viewModel.upcomingDueFlashcards![0]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards![1]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards![2]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards![3]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards![4]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards![5]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards![6]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards![7]
                                      .toString()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: viewModel.toggleIntervalDisplay,
                    child: _IntervalLength(
                      flashcardIntervalCounts:
                          viewModel.flashcardIntervalCounts,
                      showIntervalAsPercent: viewModel.showIntervalAsPercent,
                      flashcardCount: viewModel.flashcardCount,
                    ),
                  ),
                  if (viewModel.maxDueFlashcardsCompleted != 0)
                    _HistoricalPerformance(
                      viewModel.flashcardSetReports,
                      viewModel.maxDueFlashcardsCompleted,
                    ),
                  if (viewModel.challengingFlashcards.isNotEmpty)
                    const _Challenging(),
                ],
              ),
      ),
    );
  }
}

class _IntervalLength extends StatelessWidget {
  final List<double> flashcardIntervalCounts;
  final bool showIntervalAsPercent;
  final int flashcardCount;

  const _IntervalLength({
    required this.flashcardIntervalCounts,
    required this.showIntervalAsPercent,
    required this.flashcardCount,
  });

  @override
  Widget build(BuildContext context) {
    return CardWithTitleSection(
      title: 'Flashcard interval length',
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      flashcardIntervalCounts
                          .reduce((a, b) => a + b)
                          .toInt()
                          .toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  PieChart(
                    PieChartData(
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: Colors.red,
                          value: flashcardIntervalCounts[0],
                          title: showIntervalAsPercent
                              ? '${(flashcardIntervalCounts[0] / flashcardCount * 100).round()}%'
                              : flashcardIntervalCounts[0].toStringAsFixed(0),
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffffff),
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.orange,
                          value: flashcardIntervalCounts[1],
                          title: showIntervalAsPercent
                              ? '${(flashcardIntervalCounts[1] / flashcardCount * 100).round()}%'
                              : flashcardIntervalCounts[1].toStringAsFixed(0),
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffffff),
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.green,
                          value: flashcardIntervalCounts[2],
                          title: showIntervalAsPercent
                              ? '${(flashcardIntervalCounts[2] / flashcardCount * 100).round()}%'
                              : flashcardIntervalCounts[2].toStringAsFixed(0),
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffffff),
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: flashcardIntervalCounts[3],
                          title: showIntervalAsPercent
                              ? '${(flashcardIntervalCounts[3] / flashcardCount * 100).round()}%'
                              : flashcardIntervalCounts[3].toStringAsFixed(0),
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffffff),
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.deepPurple,
                          value: flashcardIntervalCounts[4],
                          title: showIntervalAsPercent
                              ? '${(flashcardIntervalCounts[4] / flashcardCount * 100).round()}%'
                              : flashcardIntervalCounts[4].toStringAsFixed(0),
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffffff),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _Indicator(
                  color: Colors.red,
                  text: 'Not started',
                ),
                _Indicator(
                  color: Colors.orange,
                  text: 'Less than 1 week',
                ),
                _Indicator(
                  color: Colors.green,
                  text: '1-4 weeks',
                ),
                _Indicator(
                  color: Colors.blue,
                  text: '1-2 months',
                ),
                _Indicator(
                  color: Colors.deepPurple,
                  text: '2+ months',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text)
      ],
    );
  }
}

class _HistoricalPerformance
    extends ViewModelWidget<FlashcardSetInfoViewModel> {
  final int maxFlashcardsCompleted;
  final List<FlashcardSetReport?> flashcardSetReports;

  const _HistoricalPerformance(
    this.flashcardSetReports,
    this.maxFlashcardsCompleted,
  );

  @override
  Widget build(BuildContext context, FlashcardSetInfoViewModel viewModel) {
    const double barsWidth = 8;

    return CardWithTitleSection(
      title: 'Recent performance',
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          top: 24,
          right: 16,
          bottom: 8,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchCallback: (p0, p1) {
                      if (p0 is FlTapUpEvent && p1?.spot != null) {
                        viewModel.showFlashcardSetReport(
                            p1!.spot!.touchedBarGroupIndex);
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (number, __) => Text(
                          DateFormat.E().format(DateTime.now()
                              .subtract(Duration(days: 6 - number.toInt()))),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: (maxFlashcardsCompleted / 3).ceilToDouble(),
                        getTitlesWidget: (number, __) => Text(
                          '${number.toInt()}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    flashcardSetReports.length,
                    (index) {
                      final current = flashcardSetReports[index];
                      if (current == null) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: 0,
                              rodStackItems: [
                                BarChartRodStackItem(0, 0, Colors.transparent),
                              ],
                              width: barsWidth,
                            ),
                            BarChartRodData(
                              toY: 0,
                              rodStackItems: [
                                BarChartRodStackItem(0, 0, Colors.transparent),
                              ],
                              width: barsWidth,
                            ),
                          ],
                        );
                      } else {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: current.dueFlashcardsCompleted.toDouble(),
                              rodStackItems: [
                                BarChartRodStackItem(
                                  0,
                                  current.dueFlashcardsCompleted.toDouble(),
                                  Colors.green,
                                ),
                              ],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              width: barsWidth,
                            ),
                            BarChartRodData(
                              toY: current.dueFlashcardsGotWrong.toDouble(),
                              rodStackItems: [
                                BarChartRodStackItem(
                                  0,
                                  current.dueFlashcardsGotWrong.toDouble(),
                                  Colors.red,
                                ),
                              ],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              width: barsWidth,
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            const Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _Indicator(
                  color: Colors.green,
                  text: 'Due flashcards completed',
                ),
                _Indicator(
                  color: Colors.red,
                  text: 'Due flashcards got wrong',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Challenging extends ViewModelWidget<FlashcardSetInfoViewModel> {
  const _Challenging();

  @override
  Widget build(BuildContext context, FlashcardSetInfoViewModel viewModel) {
    List<Widget> children = [
      viewModel.challengingFlashcards[0] is Vocab
          ? VocabListItem(
              vocab: viewModel.challengingFlashcards[0] as Vocab,
              onPressed: () => viewModel
                  .navigateToVocab(viewModel.challengingFlashcards[0] as Vocab),
            )
          : KanjiListItem(
              kanji: viewModel.challengingFlashcards[0] as Kanji,
              onPressed: () => viewModel
                  .navigateToKanji(viewModel.challengingFlashcards[0] as Kanji),
            ),
    ];

    for (int i = 1; i < viewModel.challengingFlashcards.length; i++) {
      final current = viewModel.challengingFlashcards[i];
      children.addAll([
        const Divider(
          height: 1,
          indent: 8,
          endIndent: 8,
        ),
        current is Vocab
            ? VocabListItem(
                vocab: current,
                onPressed: () => viewModel.navigateToVocab(current),
              )
            : KanjiListItem(
                kanji: current as Kanji,
                onPressed: () => viewModel.navigateToKanji(current),
              ),
      ]);
    }

    return CardWithTitleSection(
      title: 'Top challenging flashcards',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}
