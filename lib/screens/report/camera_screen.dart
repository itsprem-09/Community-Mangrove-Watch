import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';

import '../../services/location_service.dart';

// import 'report_bloc.dart'; // Not needed for this screen

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Get current location
      final position = await context.read<LocationService>().getCurrentPosition();

      // Take picture
      final image = await _controller!.takePicture();

      // Navigate to report screen with image and location
      if (position != null) {
        context.go('/report', extra: {
          'imagePath': image.path,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      } else {
        // Navigate without location if not available
        context.go('/report', extra: {
          'imagePath': image.path,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Photo'),
        backgroundColor: Colors.green,
      ),
      body: _isInitialized
          ? Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePicture,
                backgroundColor: Colors.green,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
