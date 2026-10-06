import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeCameraPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements CameraPlatform {
  final List<int> createdCameras = [];
  final List<int> disposedCameras = [];
  int picturesTaken = 0;

  // Complete to finish camera initialization, if null it finishes immediately
  Completer<void>? initializeCompleter;
  // Thrown by camera initialization if set
  Object? initializeError;
  // Complete to finish taking a picture, if null it finishes immediately
  Completer<void>? takePictureCompleter;

  @override
  Future<List<CameraDescription>> availableCameras() async {
    return const [
      CameraDescription(
        name: 'front',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 0,
      ),
      CameraDescription(
        name: 'back',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 0,
      ),
    ];
  }

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings? mediaSettings,
  ) async {
    final cameraId = createdCameras.length;
    createdCameras.add(cameraId);
    return cameraId;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    await initializeCompleter?.future;
    if (initializeError != null) throw initializeError!;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) {
    return Stream.value(
      CameraInitializedEvent(
        cameraId,
        1920,
        1080,
        ExposureMode.auto,
        true,
        FocusMode.auto,
        true,
      ),
    );
  }

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) {
    // Never closes like the real platform, an empty stream would make the
    // camera controller throw while waiting for the first error
    return StreamController<CameraErrorEvent>().stream;
  }

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() {
    return const Stream.empty();
  }

  @override
  Widget buildPreview(int cameraId) {
    return const SizedBox();
  }

  @override
  Future<XFile> takePicture(int cameraId) async {
    picturesTaken++;
    await takePictureCompleter?.future;
    return XFile('picture_$picturesTaken.jpg');
  }

  @override
  Future<void> dispose(int cameraId) async {
    disposedCameras.add(cameraId);
  }
}
