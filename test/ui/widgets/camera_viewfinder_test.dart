import 'dart:async';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/widgets/camera_viewfinder.dart';

import '../../helpers/fake_camera_platform.dart';

void main() {
  late FakeCameraPlatform cameraPlatform;

  setUp(() {
    cameraPlatform = FakeCameraPlatform();
    CameraPlatform.instance = cameraPlatform;
  });

  Widget buildViewfinder({void Function(XFile)? onPictureTaken}) {
    return MaterialApp(
      home: Scaffold(
        body: CameraViewfinder(onPictureTaken: onPictureTaken ?? (_) {}),
      ),
    );
  }

  testWidgets('Camera is released while inactive and reopened when resumed',
      (tester) async {
    await tester.pumpWidget(buildViewfinder());
    await tester.pumpAndSettle();

    expect(find.byType(CameraPreview), findsOne);
    expect(cameraPlatform.createdCameras, [0]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.byType(CameraPreview), findsNothing);
    expect(cameraPlatform.disposedCameras, [0]);

    // Going to the background and back only opens the camera once
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byType(CameraPreview), findsOne);
    expect(cameraPlatform.createdCameras, [0, 1]);
    expect(cameraPlatform.disposedCameras, [0]);

    // Removing the widget closes the camera
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    expect(cameraPlatform.disposedCameras, [0, 1]);
  });

  testWidgets('Lifecycle changes during initialization are ignored',
      (tester) async {
    cameraPlatform.initializeCompleter = Completer();

    await tester.pumpWidget(buildViewfinder());
    await tester.pump();

    // For example, the camera permission prompt makes the app inactive
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    cameraPlatform.initializeCompleter!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CameraPreview), findsOne);
    expect(cameraPlatform.createdCameras, [0]);
    expect(cameraPlatform.disposedCameras, isEmpty);
  });

  testWidgets('Permission denied', (tester) async {
    cameraPlatform.initializeError =
        PlatformException(code: 'CameraAccessDenied');

    await tester.pumpWidget(buildViewfinder());
    await tester.pumpAndSettle();

    expect(
        find.text('Confirm camera permissions in system settings'), findsOne);
  });

  testWidgets('Camera error after the widget is removed is ignored',
      (tester) async {
    cameraPlatform.initializeCompleter = Completer();
    cameraPlatform.initializeError =
        PlatformException(code: 'CameraAccessDenied');

    await tester.pumpWidget(buildViewfinder());
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    cameraPlatform.initializeCompleter!.complete();
    await tester.pumpAndSettle();

    expect(cameraPlatform.disposedCameras, [0]);
  });

  testWidgets('Taps are ignored while taking a picture', (tester) async {
    final pictures = <XFile>[];
    cameraPlatform.takePictureCompleter = Completer();

    await tester.pumpWidget(buildViewfinder(onPictureTaken: pictures.add));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    cameraPlatform.takePictureCompleter!.complete();
    await tester.pumpAndSettle();

    expect(cameraPlatform.picturesTaken, 1);
    expect(pictures.length, 1);
    expect(find.byType(CameraPreview), findsOne);
  });
}
