import 'package:flutter/material.dart';

class ListNavigationScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final int? index;
  final int? length;
  final void Function() onPrevious;
  final void Function() onNext;

  const ListNavigationScaffold({
    this.appBar,
    required this.body,
    required this.index,
    required this.length,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      extendBody: true,
      bottomNavigationBar: index != null && length != null
          ? _ListNavigationBar(
              index: index!,
              length: length!,
              onPrevious: onPrevious,
              onNext: onNext,
            )
          : null,
    );
  }
}

class ListNavigationSpacer extends StatelessWidget {
  const ListNavigationSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.of(context).padding.bottom);
  }
}

class _ListNavigationBar extends StatelessWidget {
  final int index;
  final int length;
  final void Function() onPrevious;
  final void Function() onNext;

  const _ListNavigationBar({
    required this.index,
    required this.length,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: Theme.of(context).iconTheme.color,
      shape: const StadiumBorder(),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Center(
          heightFactor: 1,
          child: Card(
            elevation: 8,
            margin: EdgeInsets.zero,
            shape: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: index > 0 ? onPrevious : null,
                    style: buttonStyle,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(opacity: 0, child: Text('$length / $length')),
                        Text(
                          '${index + 1} / $length',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: index < length - 1 ? onNext : null,
                    style: buttonStyle,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                    iconAlignment: IconAlignment.end,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
