import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/conjugation_practice.dart';
import 'package:stacked_services/stacked_services.dart';

class ConjugationPracticeSelectionDialog extends HookWidget {
  final _snackbarService = locator<SnackbarService>();

  final DialogRequest request;
  final Function(DialogResponse) completer;

  final Set<ConjugationPracticeWordType> initialTypes;
  final Set<ConjugationPracticeForm> initialForms;

  ConjugationPracticeSelectionDialog({
    required this.request,
    required this.completer,
    super.key,
  })  : initialTypes = request.data.$1,
        initialForms = request.data.$2;

  @override
  Widget build(BuildContext context) {
    final types = useState(initialTypes);
    final forms = useState(initialForms);

    final verbTypes =
        ConjugationPracticeWordType.values.where((e) => !e.isAdjective).toSet();
    final adjectiveTypes =
        ConjugationPracticeWordType.values.where((e) => e.isAdjective).toSet();

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 20, right: 20),
              child: Text(
                'Conjugations to practice',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      title: 'Verbs',
                      selectedCount: types.value.intersection(verbTypes).length,
                      totalCount: verbTypes.length,
                      onToggleAll: (selectAll) =>
                          _toggleAll(types, verbTypes, selectAll),
                      children: [
                        for (final type in verbTypes)
                          _SelectionItem(
                            title: type.title,
                            subtitle: type.examples,
                            selected: types.value.contains(type),
                            onChanged: () => _toggle(types, type),
                          ),
                      ],
                    ),
                    _Section(
                      title: 'Adjectives',
                      selectedCount:
                          types.value.intersection(adjectiveTypes).length,
                      totalCount: adjectiveTypes.length,
                      onToggleAll: (selectAll) =>
                          _toggleAll(types, adjectiveTypes, selectAll),
                      children: [
                        for (final type in adjectiveTypes)
                          _SelectionItem(
                            title: type.title,
                            subtitle: type.examples,
                            selected: types.value.contains(type),
                            onChanged: () => _toggle(types, type),
                          ),
                      ],
                    ),
                    _Section(
                      title: 'Forms',
                      selectedCount: forms.value.length,
                      totalCount: ConjugationPracticeForm.values.length,
                      onToggleAll: (selectAll) => _toggleAll(
                        forms,
                        ConjugationPracticeForm.values.toSet(),
                        selectAll,
                      ),
                      children: [
                        for (final form in ConjugationPracticeForm.values)
                          _SelectionItem(
                            title: form.title,
                            subtitle: form.examples,
                            selected: forms.value.contains(form),
                            onChanged: () => _toggle(forms, form),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
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
                  String? error;
                  if (types.value.isEmpty || forms.value.isEmpty) {
                    error = 'At least one word type and one form must be '
                        'selected';
                  } else if (ConjugationPracticeQuestion.getAll(
                    types: types.value,
                    forms: forms.value,
                  ).isEmpty) {
                    error = 'The selected forms do not apply to the selected '
                        'word types';
                  }

                  if (error != null) {
                    if (!_snackbarService.isSnackbarOpen) {
                      _snackbarService.showSnackbar(message: error);
                    }
                    return;
                  }

                  completer(DialogResponse(data: (types.value, forms.value)));
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

  void _toggleAll<T>(
    ValueNotifier<Set<T>> selection,
    Set<T> items,
    bool selectAll,
  ) {
    if (selectAll) {
      selection.value = selection.value.union(items);
    } else {
      selection.value = selection.value.difference(items);
    }
  }
}

/// Collapsible group of selection items. Starts collapsed and shows how many
/// items are selected so the sections can be navigated without scrolling
/// through every item.
class _Section extends HookWidget {
  final String title;
  final int selectedCount;
  final int totalCount;
  final void Function(bool selectAll) onToggleAll;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.selectedCount,
    required this.totalCount,
    required this.onToggleAll,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final expanded = useState(false);
    final allSelected = selectedCount == totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => expanded.value = !expanded.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '$selectedCount of $totalCount selected',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onToggleAll(!allSelected),
                  child: Text(allSelected ? 'Select none' : 'Select all'),
                ),
                AnimatedCrossFade(
                  crossFadeState: expanded.value
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 150),
                  firstChild: const Icon(Icons.expand_less),
                  secondChild: const Icon(Icons.expand_more),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          crossFadeState: expanded.value
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 150),
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(children: children),
        ),
      ],
    );
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
