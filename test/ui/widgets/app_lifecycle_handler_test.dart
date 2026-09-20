import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/widgets/app_lifecycle_handler.dart';

void main() {
  testWidgets('Calls the callback of the new state', (tester) async {
    final calls = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: AppLifecycleHandler(
          onResumed: () => calls.add('resumed'),
          onInactive: () => calls.add('inactive'),
          onHidden: () => calls.add('hidden'),
          onPaused: () => calls.add('paused'),
          onDetached: () => calls.add('detached'),
          child: const SizedBox(),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    expect(calls, ['inactive']);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(calls, [
      'inactive',
      'hidden',
      'paused',
      'hidden',
      'inactive',
      'resumed',
    ]);
  });

  testWidgets('Does not require a callback for every state', (tester) async {
    int resumedCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppLifecycleHandler(
          onResumed: () => resumedCalls++,
          child: const SizedBox(),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    expect(resumedCalls, 1);
  });

  testWidgets('Ignores changes while another route is on top', (tester) async {
    int resumedCalls = 0;
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: AppLifecycleHandler(
          onResumed: () => resumedCalls++,
          onlyWhenCurrentRoute: true,
          child: const SizedBox(),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(resumedCalls, 1);

    // Push a route on top of the handler
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const SizedBox()),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(resumedCalls, 1);

    // Return to the handler
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(resumedCalls, 2);
  });
}
