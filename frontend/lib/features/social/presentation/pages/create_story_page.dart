import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:image_picker/image_picker.dart';

class CreateStoryPage extends ConsumerStatefulWidget {
  const CreateStoryPage({super.key});

  @override
  ConsumerState<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends ConsumerState<CreateStoryPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _useFrontCamera = true;
  String? _capturedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final camera = _cameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || _isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
        _isTakingPicture = false;
      });
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao tirar foto: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );

    if (image != null) {
      setState(() {
        _capturedImagePath = image.path;
      });
    }
  }

  Future<void> _uploadStory() async {
    if (_capturedImagePath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(socialRepositoryProvider);
      final result = await repository.createStory(_capturedImagePath!);

      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          },
          (story) {
            ref.invalidate(storiesProvider);
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar story: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _useFrontCamera = !_useFrontCamera;
    });

    final camera = _cameras!.firstWhere(
      (cam) => _useFrontCamera
          ? cam.lensDirection == CameraLensDirection.front
          : cam.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    await _cameraController?.dispose();

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_capturedImagePath != null) {
      return _buildPreviewScreen(isDark);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.flip_camera_ios,
                                color: Colors.white, size: 28),
                            onPressed: _cameras != null && _cameras!.length > 1
                                ? _switchCamera
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo_library,
                                color: Colors.white, size: 28),
                            onPressed: _pickFromGallery,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: GestureDetector(
                    onTap: _isTakingPicture ? null : _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isTakingPicture ? Colors.grey : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewScreen(bool isDark) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.file(
              File(_capturedImagePath!),
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                        onPressed: () {
                          setState(() {
                            _capturedImagePath = null;
                          });
                        },
                      ),
                      if (_isLoading)
                        const CircularProgressIndicator(
                          color: AppColors.primaryPurple,
                        )
                      else
                        InkWell(
                          onTap: _uploadStory,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: const BoxDecoration(
                              gradient: AppColors.brutalistGradient,
                            ),
                            child: const Center(
                              child: Text(
                                'Publicar',
                                style: TextStyle(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
