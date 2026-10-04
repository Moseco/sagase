import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/kana.dart';
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
            _SelectionItem(
              title: 'Hiragana',
              selected: scripts.value.contains(KanaScript.hiragana),
              onChanged: () => _toggle(scripts, KanaScript.hiragana),
            ),
            _SelectionItem(
              title: 'Katakana',
              selected: scripts.value.contains(KanaScript.katakana),
              onChanged: () => _toggle(scripts, KanaScript.katakana),
            ),
            const Divider(indent: 20, endIndent: 20),
            _SelectionItem(
              title: 'Basic',
              subtitle: 'あ, か, さ',
              selected: types.value.contains(KanaType.basic),
              onChanged: () => _toggle(types, KanaType.basic),
            ),
            _SelectionItem(
              title: 'Voiced',
              subtitle: 'が, ざ, だ',
              selected: types.value.contains(KanaType.voiced),
              onChanged: () => _toggle(types, KanaType.voiced),
            ),
            _SelectionItem(
              title: 'Semi-voiced',
              subtitle: 'ぱ, ぴ, ぷ',
              selected: types.value.contains(KanaType.semiVoiced),
              onChanged: () => _toggle(types, KanaType.semiVoiced),
            ),
            _SelectionItem(
              title: 'Combinations',
              subtitle: 'きゃ, しゅ, ちょ',
              selected: types.value.contains(KanaType.combination),
              onChanged: () => _toggle(types, KanaType.combination),
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

  void _toggle<T>(ValueNotifier<Set<T>> selection, T item) {
    if (selection.value.contains(item)) {
      selection.value = selection.value.difference({item});
    } else {
      selection.value = selection.value.union({item});
    }
  }
}

class _SelectionItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final void Function() onChanged;

  const _SelectionItem({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: selected,
      onChanged: (_) => onChanged(),
    );
  }
}
