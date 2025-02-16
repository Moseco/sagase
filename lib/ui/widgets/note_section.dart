import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';

class NoteSection extends StatelessWidget {
  final String? note;
  final void Function() editNote;

  const NoteSection({
    required this.note,
    required this.editNote,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: editNote,
      child: CardWithTitleSection(
        title: 'Note',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: Text(note ?? 'Tap to add'),
        ),
      ),
    );
  }
}
