import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/kana.dart';
import 'package:sagase/ui/widgets/selection_list_item.dart';
import 'package:stacked_services/stacked_services.dart';

class KanaPracticeSelectionDialog extends HookWidget {
  final _snackbarService = locator<SnackbarService>();

  final DialogRequest request;
  final Function(DialogResponse) completer;

  final Set<KanaScript> initialScripts;
  final Set<KanaType> initialTypes;

  KanaPracticeSelectionDialog({
    required this.request,
    required this.completer,
    super.key,
  })  : initialScripts = request.data.$1,
        initialTypes = request.data.$2;

  @override
  Widget build(BuildContext context) {
    final scripts = useState(initialScripts);
    final types = useState(initialTypes);
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 20, right: 20),
              child: Text(
                'Kana to practice',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            SelectionListItem(
              title: 'Hiragana',
              item: KanaScript.hiragana,
              selection: scripts,
            ),
            SelectionListItem(
              title: 'Katakana',
              item: KanaScript.katakana,
              selection: scripts,
            ),
            const Divider(indent: 20, endIndent: 20),
            SelectionListItem(
              title: 'Basic',
              subtitle: 'あ, か, さ',
              item: KanaType.basic,
              selection: types,
            ),
            SelectionListItem(
              title: 'Voiced',
              subtitle: 'が, ざ, だ',
              item: KanaType.voiced,
              selection: types,
            ),
            SelectionListItem(
              title: 'Semi-voiced',
              subtitle: 'ぱ, ぴ, ぷ',
              item: KanaType.semiVoiced,
              selection: types,
            ),
            SelectionListItem(
              title: 'Combinations',
              subtitle: 'きゃ, しゅ, ちょ',
              item: KanaType.combination,
              selection: types,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: const BorderSide(color: Colors.deepPurple),
                  ),
                ),
                onPressed: () {
                  if (scripts.value.isEmpty || types.value.isEmpty) {
                    if (!_snackbarService.isSnackbarOpen) {
                      _snackbarService.showSnackbar(
                        message:
                            'At least one script and one type must be selected',
                      );
                    }
                    return;
                  }

                  completer(
                    DialogResponse(data: (scripts.value, types.value)),
                  );
                },
                child: const Center(
                  child: Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
