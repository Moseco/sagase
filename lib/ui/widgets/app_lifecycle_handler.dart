import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AppLifecycleHandler extends HookWidget {
  final VoidCallback? onResumed;
  final VoidCallback? onInactive;
  final VoidCallback? onHidden;
  final VoidCallback? onPaused;
  final VoidCallback? onDetached;
  final bool onlyWhenCurrentRoute;
  final Widget child;

  const AppLifecycleHandler({
    this.onResumed,
    this.onInactive,
    this.onHidden,
    this.onPaused,
    this.onDetached,
    this.onlyWhenCurrentRoute = false,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    useOnAppLifecycleStateChange((previous, current) {
      if (onlyWhenCurrentRoute &&
          !(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }

      switch (current) {
        case AppLifecycleState.resumed:
          onResumed?.call();
        case AppLifecycleState.inactive:
          onInactive?.call();
        case AppLifecycleState.hidden:
          onHidden?.call();
        case AppLifecycleState.paused:
          onPaused?.call();
        case AppLifecycleState.detached:
          onDetached?.call();
      }
    });

    return child;
  }
}
