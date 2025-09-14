import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraViewfinder extends StatefulWidget {
  final void Function(XFile) onPictureTaken;

  const CameraViewfinder({super.key, required this.onPictureTaken});

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _cameraInitialized = false;
  bool _cameraError = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) {
      setState(() {
        _cameraError = true;
      });
    }
    CameraDescription cameraToUse = _cameras!.first;
    for (final camera in _cameras!) {
      if (camera.lensDirection == CameraLensDirection.back) {
        cameraToUse = camera;
        break;
      }
    }
    _controller = CameraController(
      cameraToUse,
      ResolutionPreset.max,
      enableAudio: false,
    );

    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() => _cameraInitialized = true);
      }
    }).catchError((Object e) {
      setState(() {
        _cameraError = true;
      });
    });
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
      setState(() => _cameraInitialized = false);
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _takePhoto() async {
    if (!_controller!.value.isInitialized) return;
    final image = await _controller!.takePicture();
    widget.onPictureTaken(image);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError) {
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
    }

    if (_cameraInitialized) {
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
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}
