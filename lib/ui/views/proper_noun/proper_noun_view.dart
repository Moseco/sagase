import 'package:flutter/material.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase/utils/enum_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';

import 'proper_noun_viewmodel.dart';

class ProperNounView extends StackedView<ProperNounViewModel> {
  final ProperNoun properNoun;

  const ProperNounView(this.properNoun, {super.key});

  @override
  ProperNounViewModel viewModelBuilder(BuildContext context) =>
      ProperNounViewModel(properNoun);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(),
      // Can throw exception "'!_selectionStartsInScrollable': is not true."
      // when long press then try to scroll on disabled areas.
      // But seems to work okay in release builds.
      body: SafeArea(
        bottom: false,
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              const _WritingReading(),
              const _RomajiAndType(),
              if (viewModel.kanjiList.isNotEmpty) const _KanjiList(),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _WritingReading extends ViewModelWidget<ProperNounViewModel> {
  const _WritingReading();

  @override
  Widget build(BuildContext context, ProperNounViewModel viewModel) {
    if (viewModel.properNoun.writing == null) {
      return Text(
        viewModel.properNoun.reading,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32),
      );
    } else {
      return _RubyTextWrapper(
        pairs: viewModel.getRubyTextPairs(
          viewModel.properNoun.writing!,
          viewModel.properNoun.reading,
        ),
        fontSize: 32,
        textAlign: TextAlign.center,
      );
    }
  }
}

class _RubyTextWrapper extends StatelessWidget {
  final List<RubyTextPair> pairs;
  final double? fontSize;
  final TextAlign? textAlign;

  const _RubyTextWrapper({
    required this.pairs,
    this.fontSize,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    List<RubyTextData> rubyTextData = [];
    for (var rubyTextPair in pairs) {
      rubyTextData.add(
        RubyTextData(
          rubyTextPair.writing,
          ruby: rubyTextPair.reading,
        ),
      );
    }
    return RubyText(
      rubyTextData,
      textAlign: textAlign,
      style: TextStyle(letterSpacing: 0, height: 1.1, fontSize: fontSize),
    );
  }
}

class _RomajiAndType extends ViewModelWidget<ProperNounViewModel> {
  const _RomajiAndType();

  @override
  Widget build(BuildContext context, ProperNounViewModel viewModel) {
    return CardWithTitleSection(
      title: 'Romaji',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              viewModel.properNoun.types.map((e) => e.displayTitle).join(', '),
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(),
            Text(viewModel.properNoun.romaji),
          ],
        ),
      ),
    );
  }
}

class _KanjiList extends ViewModelWidget<ProperNounViewModel> {
  const _KanjiList();

  @override
  Widget build(BuildContext context, ProperNounViewModel viewModel) {
    return SelectionContainer.disabled(
      child: CardWithTitleSection(
        title: 'Kanji',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: viewModel.isBusy
                ? List.generate(
                    viewModel.kanjiList.length,
                    (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 12,
                              ),
                              child: Text(
                                viewModel.kanjiList[index],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Text(''), Text(''), Text('')],
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : List.generate(
                    viewModel.kanjiList.length,
                    (index) {
                      final current = viewModel.kanjiList[index];
                      return KanjiListItemLarge(
                        kanji: current,
                        onPressed: () => viewModel.navigateToKanji(current),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
