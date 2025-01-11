import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/ui/bottom_sheets/base_bottom_sheet.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase/ui/widgets/proper_noun_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked_services/stacked_services.dart';

class DictionaryItemsBottomSheet extends StatelessWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  const DictionaryItemsBottomSheet({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      child: ListView.separated(
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 8,
          endIndent: 8,
        ),
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        itemCount: request.data.length,
        itemBuilder: (context, index) {
          final current = request.data[index];
          if (current is Vocab) {
            return VocabListItem(
              vocab: current,
              onPressed: () => locator<NavigationService>().navigateTo(
                Routes.vocabView,
                arguments: VocabViewArguments(vocab: current),
              ),
            );
          } else if (current is Kanji) {
            return KanjiListItemLarge(
              kanji: current,
              onPressed: () => locator<NavigationService>().navigateTo(
                Routes.kanjiView,
                arguments: KanjiViewArguments(kanji: current),
              ),
            );
          } else {
            return ProperNounListItem(
              properNoun: current,
              onPressed: () => locator<NavigationService>().navigateTo(
                Routes.properNounView,
                arguments: ProperNounViewArguments(properNoun: current),
              ),
            );
          }
        },
      ),
    );
  }
}
