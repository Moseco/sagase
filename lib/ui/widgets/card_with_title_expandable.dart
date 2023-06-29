import 'package:flutter/material.dart';

class CardWithTitleExpandable extends StatefulWidget {
  final String title;
  final Widget child;

  const CardWithTitleExpandable({
    required this.title,
    required this.child,
    super.key,
  });

  @override
  State<CardWithTitleExpandable> createState() =>
      _CardWithTitleExpandableState();
}

class _CardWithTitleExpandableState extends State<CardWithTitleExpandable> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showFirst = !_showFirst),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: SelectionContainer.disabled(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: AnimatedCrossFade(
                  crossFadeState: _showFirst
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 150),
                  firstChild: const Icon(Icons.keyboard_arrow_down),
                  secondChild: const Icon(Icons.keyboard_arrow_up),
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          crossFadeState:
              _showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 150),
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: widget.child,
          ),
        )
      ],
    );
  }
}
