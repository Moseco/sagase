import 'package:flutter/material.dart';

/// Checkbox list item that adds or removes [item] from [selection]. The parent
/// is expected to rebuild when [selection] changes, such as when it comes from
/// useState.
class SelectionListItem<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final T item;
  final ValueNotifier<Set<T>> selection;

  const SelectionListItem({
    required this.title,
    this.subtitle,
    required this.item,
    required this.selection,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selection.value.contains(item);

    return CheckboxListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: selected,
      onChanged: (_) => selection.value = selected
          ? selection.value.difference({item})
          : selection.value.union({item}),
    );
  }
}
