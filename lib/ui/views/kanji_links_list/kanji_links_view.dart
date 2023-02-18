import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:stacked/stacked.dart';

import 'kanji_links_viewmodel.dart';

class KanjiLinksView extends StatelessWidget {
  final String title;
  final IsarLinks<Kanji> links;

  const KanjiLinksView({
    required this.title,
    required this.links,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiLinksViewModel>.reactive(
      viewModelBuilder: () => KanjiLinksViewModel(links),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: viewModel.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                itemCount: links.length,
                itemBuilder: (context, index) {
                  final current = links.elementAt(index);

                  return KanjiListItem(
                    kanji: current,
                    onPressed: () => viewModel.navigateToKanji(current),
                  );
                },
              ),
      ),
    );
  }
}
