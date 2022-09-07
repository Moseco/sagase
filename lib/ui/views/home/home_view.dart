import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: kDebugMode
              ? [
                  IconButton(
                    onPressed: viewModel.navigateToDev,
                    icon: const Icon(Icons.bug_report),
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    border: OutlineInputBorder(borderSide: BorderSide()),
                  ),
                  onChanged: viewModel.searchOnChange,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: viewModel.searchResult.length,
                  itemBuilder: (context, index) {
                    final current = viewModel.searchResult[index];
                    return ListTile(
                      title: Text(
                        current.kanjiReadingPairs.first.kanjiWritings != null
                            ? current.kanjiReadingPairs.first.kanjiWritings!
                                .first.kanji
                            : current
                                .kanjiReadingPairs.first.readings.first.reading,
                      ),
                      onTap: () => viewModel.navigateToVocab(current),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
