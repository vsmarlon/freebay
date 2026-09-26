import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class StoryCaptureView extends StatelessWidget {
  final CameraController? cameraController;
  final bool isInitialized;
  final bool isTakingPicture;
  final bool canSwitchCamera;
  final String? cameraError;
  final VoidCallback onClose;
  final VoidCallback onSwitchCamera;
  final VoidCallback onPickFromGallery;
  final VoidCallback onTakePicture;

  const StoryCaptureView({
    super.key,
    required this.cameraController,
    required this.isInitialized,
    required this.isTakingPicture,
    required this.canSwitchCamera,
    required this.cameraError,
    required this.onClose,
    required this.onSwitchCamera,
    required this.onPickFromGallery,
    required this.onTakePicture,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onSurface,
      body: Stack(
        children: [
          if (isInitialized && cameraController != null)
            SizedBox.expand(child: CameraPreview(cameraController!))
          else
            Center(
              child: Text(
                cameraError ?? 'Inicializando câmera…',
                style: const TextStyle(color: AppColors.onPrimary),
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
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.onPrimary,
                          size: 28,
                        ),
                        onPressed: onClose,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: AppColors.onPrimary,
                              size: 28,
                            ),
                            onPressed: canSwitchCamera ? onSwitchCamera : null,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.photo_library,
                              color: AppColors.onPrimary,
                              size: 28,
                            ),
                            onPressed: onPickFromGallery,
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
                    onTap: isTakingPicture ? null : onTakePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.onPrimary,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isTakingPicture
                              ? context.textSecondary
                              : AppColors.onPrimary,
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
}
