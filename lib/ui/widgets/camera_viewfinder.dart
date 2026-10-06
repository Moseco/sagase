import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CameraViewfinder extends StatefulWidget {
  final void Function(XFile) onPictureTaken;

  const CameraViewfinder({super.key, required this.onPictureTaken});

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder>
    with WidgetsBindingObserver {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  CameraState _cameraState = CameraState.uninitialized;
  bool _releasedWhileInactive = false;
  Future<void>? _releasedCamera;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // The camera can't be opened again until the released one is closed
      await _releasedCamera;
      _cameras = await availableCameras();
      if (!mounted) return;
      if (_cameras.isEmpty) {
        setState(() => _cameraState = CameraState.permissionDenied);
        return;
      }
      CameraDescription cameraToUse = _cameras.first;
      for (final camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          cameraToUse = camera;
          break;
        }
      }

      // This is a temporary workaround for iPhone 17 family devices
      final iOS = Platform.isIOS ? await DeviceInfoPlugin().iosInfo : null;
      if (!mounted) return;

      final controller = CameraController(
        cameraToUse,
        iOS != null && iOS.utsname.machine.contains("iPhone18")
            ? ResolutionPreset.ultraHigh
            : ResolutionPreset.max,
        enableAudio: false,
      );
      // Assign before initializing so dispose can clean it up
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;
      setState(() => _cameraState = CameraState.initialized);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _cameraState = e.code == 'CameraAccessDenied'
          ? CameraState.permissionDenied
          : CameraState.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraState = CameraState.error);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) return;
      setState(() => _cameraState = CameraState.uninitialized);
      _controller = null;
      _releasedWhileInactive = true;
      _releasedCamera = controller.dispose().catchError((_) {});
    } else if (state == AppLifecycleState.resumed && _releasedWhileInactive) {
      _releasedWhileInactive = false;
      _initCamera();
    }
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    try {
      final image = await controller.takePicture();
      if (!mounted) return;
      widget.onPictureTaken(image);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraState = CameraState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_cameraState) {
      case CameraState.uninitialized:
        return const Center(child: CircularProgressIndicator());
      case CameraState.initialized:
        return Stack(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: FittedBox(
                clipBehavior: Clip.hardEdge,
                fit: BoxFit.cover,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: _takePhoto,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurple,
                  child: const Icon(Icons.camera_alt),
                ),
              ),
            ),
          ],
        );
      case CameraState.permissionDenied:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              Text(
                'Failed to start camera',
                style: TextStyle(fontSize: 16),
              ),
              Text('Confirm camera permissions in system settings'),
            ],
          ),
        );
      case CameraState.error:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4,
            children: [
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 16),
              ),
              Text('Please try again later'),
            ],
          ),
        );
    }
  }
}

enum CameraState {
  uninitialized,
  initialized,
  permissionDenied,
  error,
}
