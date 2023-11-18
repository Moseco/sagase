import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked_services/stacked_services.dart';

class SelectVocabBottomSheet extends StatelessWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  const SelectVocabBottomSheet({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
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
          return VocabListItem(
            vocab: request.data[index],
            onPressed: () => locator<NavigationService>().navigateTo(
              Routes.vocabView,
              arguments: VocabViewArguments(vocab: request.data[index]),
            ),
          );
        },
      ),
    );
  }
}
