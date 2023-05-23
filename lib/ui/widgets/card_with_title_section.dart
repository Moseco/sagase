import 'package:flutter/material.dart';

class CardWithTitleSection extends StatelessWidget {
  final String title;
  final Widget? titleTrailing;
  final Widget child;

  const CardWithTitleSection({
    required this.title,
    this.titleTrailing,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: SelectionContainer.disabled(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (titleTrailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: titleTrailing!,
              ),
          ],
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: child,
        ),
      ],
    );
  }
}
