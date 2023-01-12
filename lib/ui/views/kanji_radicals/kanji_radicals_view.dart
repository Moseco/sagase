import 'package:flutter/material.dart';
import 'package:sagase/utils/constants.dart' show radicals;
import 'package:stacked/stacked.dart';

import 'kanji_radicals_viewmodel.dart';

class KanjiRadicalsView extends StatelessWidget {
  const KanjiRadicalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiRadicalsViewModel>.nonReactive(
      viewModelBuilder: () => KanjiRadicalsViewModel(),
      builder: (context, viewModel, child) {
        final List<_RadicalStrokeCountGroup> radicalGroups = [];
        for (int i = 0; i < radicals.last.strokes; i++) {
          radicalGroups.add(_RadicalStrokeCountGroup(i + 1, []));
        }
        for (int i = 1; i < radicals.length; i++) {
          radicalGroups[radicals[i].strokes - 1].radicals.add(
                SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      Text(
                        radicals[i].radical,
                        style: const TextStyle(fontSize: 32),
                      ),
                      Text(
                        radicals[i].meaning,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (radicals[i].variants != null)
                        Text(
                          radicals[i].variants!,
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Radicals')),
          body: SelectionArea(
            child: ListView.builder(
              itemCount: radicalGroups.length,
              itemBuilder: (context, groupIndex) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.deepPurple,
                      padding: const EdgeInsets.all(8),
                      child: SelectionContainer.disabled(
                        child: Text(
                          radicalGroups[groupIndex].strokes == 1
                              ? '${radicalGroups[groupIndex].strokes} stroke'
                              : '${radicalGroups[groupIndex].strokes} strokes',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Wrap(children: radicalGroups[groupIndex].radicals),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RadicalStrokeCountGroup {
  final int strokes;
  final List<Widget> radicals;

  _RadicalStrokeCountGroup(this.strokes, this.radicals);
}
