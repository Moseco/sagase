import 'package:flutter/material.dart';

class CardWithTitleExpandable extends StatefulWidget {
  final String title;
  final Widget child;
  final bool startExpanded;
  final void Function(bool)? expandedChanged;

  const CardWithTitleExpandable({
    required this.title,
    required this.child,
    this.startExpanded = true,
    this.expandedChanged,
    super.key,
  });

  @override
  State<CardWithTitleExpandable> createState() =>
      _CardWithTitleExpandableState();
}

class _CardWithTitleExpandableState extends State<CardWithTitleExpandable> {
  late bool _expanded = widget.startExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (widget.expandedChanged != null) {
              widget.expandedChanged!(_expanded);
            }
          },
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
                  crossFadeState: _expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 150),
                  firstChild: const Icon(Icons.expand_more),
                  secondChild: const Icon(Icons.expand_less),
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
