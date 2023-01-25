import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:stacked/stacked.dart';

import 'flashcard_set_info_viewmodel.dart';

class FlashcardSetInfoView extends StatelessWidget {
  final FlashcardSet flashcardSet;

  const FlashcardSetInfoView(this.flashcardSet, {super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayFormatter = DateFormat.EEEE();
    return ViewModelBuilder<FlashcardSetInfoViewModel>.reactive(
      viewModelBuilder: () => FlashcardSetInfoViewModel(flashcardSet),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(title: Text(flashcardSet.name)),
        body: viewModel.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(8),
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
                                  Text(viewModel.upcomingDueFlashcards[0]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards[1]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards[2]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards[3]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards[4]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards[5]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards[6]
                                      .toString()),
                                  Text(viewModel.upcomingDueFlashcards[7]
                                      .toString()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CardWithTitleSection(
                    title: 'Flashcard due date length',
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 0,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    color: Colors.red,
                                    value: viewModel.flashcardIntervalCounts[0],
                                    title: viewModel.flashcardIntervalCounts[0]
                                        .toStringAsFixed(0),
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffffffff),
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.orange,
                                    value: viewModel.flashcardIntervalCounts[1],
                                    title: viewModel.flashcardIntervalCounts[1]
                                        .toStringAsFixed(0),
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffffffff),
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: viewModel.flashcardIntervalCounts[2],
                                    title: viewModel.flashcardIntervalCounts[2]
                                        .toStringAsFixed(0),
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffffffff),
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.blue,
                                    value: viewModel.flashcardIntervalCounts[3],
                                    title: viewModel.flashcardIntervalCounts[3]
                                        .toStringAsFixed(0),
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffffffff),
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: Colors.deepPurple,
                                    value: viewModel.flashcardIntervalCounts[4],
                                    title: viewModel.flashcardIntervalCounts[4]
                                        .toStringAsFixed(0),
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
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: const [
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
    Key? key,
  }) : super(key: key);

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
