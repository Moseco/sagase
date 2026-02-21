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

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
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

      _controller = CameraController(
        cameraToUse,
        iOS != null && iOS.utsname.machine.contains("iPhone18")
            ? ResolutionPreset.ultraHigh
            : ResolutionPreset.max,
        enableAudio: false,
      );

      _controller!.initialize().then((_) {
        if (mounted) {
          setState(() => _cameraState = CameraState.initialized);
        }
      }).catchError((Object e) {
        if (e is CameraException && e.code == 'CameraAccessDenied') {
          setState(() => _cameraState = CameraState.permissionDenied);
        } else {
          setState(() => _cameraState = CameraState.error);
        }
      });
    } catch (e) {
      setState(() => _cameraState = CameraState.error);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      setState(() => _cameraState = CameraState.uninitialized);
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _takePhoto() async {
    try {
      if (!_controller!.value.isInitialized) return;
      final image = await _controller!.takePicture();
      widget.onPictureTaken(image);
    } catch (e) {
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
