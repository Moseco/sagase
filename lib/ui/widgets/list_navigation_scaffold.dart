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
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavigationButton(
                    icon: Icons.chevron_left,
                    text: 'Previous',
                    iconFirst: true,
                    onTap: index > 0 ? onPrevious : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  _NavigationButton(
                    icon: Icons.chevron_right,
                    text: 'Next',
                    iconFirst: false,
                    onTap: index < length - 1 ? onNext : null,
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

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool iconFirst;
  final void Function()? onTap;

  const _NavigationButton({
    required this.icon,
    required this.text,
    required this.iconFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = onTap != null
        ? Theme.of(context).iconTheme.color
        : Theme.of(context).disabledColor;

    final children = [
      Icon(icon, color: foreground),
      Text(text, style: TextStyle(color: foreground)),
    ];

    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: iconFirst ? children : children.reversed.toList(),
          ),
        ),
      ),
    );
  }
}
