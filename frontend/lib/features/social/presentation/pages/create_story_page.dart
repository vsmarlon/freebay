import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/social/data/repositories/social_repository.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/chat/presentation/pages/image_editor_page.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/widgets/story_canvas.dart';
import 'package:freebay/shared/either/either.dart';

class StorySubmissionCoordinator {
  bool _isSubmitting = false;

  Future<Either<Failure, StoryEntity>?> submit({
    required SocialRepository repository,
    required String imagePath,
    String? caption,
    List<StoryTextBlockEntity> textBlocks = const [],
    required VoidCallback invalidateGlobalStories,
    required void Function(String userId) invalidateUserStories,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    try {
      final result = await repository.createStory(
        imagePath,
        caption: caption,
        textBlocks: textBlocks,
      );
      result.fold((_) {}, (story) {
        invalidateGlobalStories();
        invalidateUserStories(story.userId);
      });
      return result;
    } finally {
      _isSubmitting = false;
    }
  }
}

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
  String? _cameraError;
  final _captionController = TextEditingController();
  final List<StoryTextBlockEntity> _textBlocks = [];
  String? _selectedTextId;
  VideoPlayerController? _videoController;
  final StorySubmissionCoordinator _submissionCoordinator =
      StorySubmissionCoordinator();

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
      if (mounted) setState(() => _cameraError = 'Câmera indisponível: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || _isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() => _isTakingPicture = false);
      await _openImageEditor(image.path);
    } catch (e) {
      setState(() {
        _isTakingPicture = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível usar a câmera.')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickMedia();

      if (image != null) {
        if (_isVideo(image.path)) {
          await _setVideo(image.path);
        } else {
          await _openImageEditor(image.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível escolher a mídia: $e')),
        );
      }
    }
  }

  Future<void> _setVideo(String path) async {
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    await _videoController?.dispose();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _videoController = controller;
      _capturedImagePath = path;
    });
    await controller.setLooping(true);
    await controller.play();
  }

  bool _isVideo(String path) =>
      ['.mp4', '.mov', '.webm'].any(path.toLowerCase().endsWith);

  Future<void> _openImageEditor(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      await context.push(
        AppRoutes.imageEditor,
        extra: {
          'imageBytes': bytes,
          'purpose': ImageEditorPurpose.story,
          'onComplete': (ImageEditorResult result) async {
            final editedFile = File(
              '${Directory.systemTemp.path}${Platform.pathSeparator}freebay_story_${DateTime.now().microsecondsSinceEpoch}.png',
            );
            await editedFile.writeAsBytes(result.imageBytes, flush: true);
            if (mounted) {
              setState(() {
                _capturedImagePath = editedFile.path;
                _captionController.text = result.caption ?? '';
              });
            }
            return true;
          },
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível editar a imagem: $e')),
        );
      }
    }
  }

  Future<void> _uploadStory() async {
    if (_capturedImagePath == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(socialRepositoryProvider);
      final result = await _submissionCoordinator.submit(
        repository: repository,
        imagePath: _capturedImagePath!,
        caption: _captionController.text,
        textBlocks: _textBlocks,
        invalidateGlobalStories: () => ref.invalidate(storiesProvider),
        invalidateUserStories: (userId) =>
            ref.invalidate(userStoriesProvider(userId)),
      );

      if (result == null) return;
      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(failure.message)));
          },
          (story) {
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar o story.')),
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
    if (_capturedImagePath != null) {
      return _buildPreviewScreen(context);
    }

    return Scaffold(
      backgroundColor: AppColors.onSurface,
      body: Stack(
        children: [
          if (_isInitialized && _cameraController != null)
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else
            Center(
              child: Text(
                _cameraError ?? 'Inicializando câmera…',
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: AppColors.onPrimary,
                              size: 28,
                            ),
                            onPressed: _cameras != null && _cameras!.length > 1
                                ? _switchCamera
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.photo_library,
                              color: AppColors.onPrimary,
                              size: 28,
                            ),
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
                        border: Border.all(
                          color: AppColors.onPrimary,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isTakingPicture
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

  Widget _buildPreviewScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onSurface,
      body: Stack(
        children: [
          Positioned.fill(
            child: StoryCanvas(
              editable: true,
              blocks: List.unmodifiable(_textBlocks),
              selectedId: _selectedTextId,
              onChanged: (blocks) => setState(() {
                _textBlocks
                  ..clear()
                  ..addAll(blocks);
              }),
              onSelected: (id) => setState(() => _selectedTextId = id),
              background:
                  _isVideo(_capturedImagePath!) &&
                      _videoController?.value.isInitialized == true
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : Image.file(File(_capturedImagePath!), fit: BoxFit.cover),
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
                        onPressed: () {
                          setState(() {
                            _capturedImagePath = null;
                          });
                        },
                      ),
                      if (_isLoading)
                        const ShimmerBlock(width: 20, height: 20)
                      else
                        AppButton(label: 'Publicar', onPressed: _uploadStory),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _captionController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Adicionar legenda',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black54,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AppButton(
                          label: 'ADICIONAR TEXTO',
                          onPressed: _addTextBlock,
                        ),
                        const SizedBox(width: 8),
                        if (_textBlocks.isNotEmpty) ...[
                          AppButton(
                            label: 'APAGAR',
                            onPressed: () => setState(_removeLastTextBlock),
                          ),
                          const SizedBox(width: 8),
                        ],
                        AppButton(
                          label: 'ESTILO',
                          onPressed: _cycleSelectedStyle,
                        ),
                        const SizedBox(width: 8),
                        AppButton(label: 'COR', onPressed: _cycleSelectedColor),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'CAMADA',
                          onPressed: _bringSelectedForward,
                        ),
                      ],
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

  void _addTextBlock() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _textBlocks.add(
        StoryTextBlockEntity(
          id: id,
          text: 'Texto',
          x: 0.5,
          y: 0.5,
          scale: 1,
          rotation: 0,
          color: Colors.white.toARGB32(),
          style: StoryTextStyle.classic,
          zIndex: _textBlocks.length,
        ),
      );
      _selectedTextId = id;
    });
  }

  void _removeLastTextBlock() {
    final index = _selectedTextId == null
        ? _textBlocks.length - 1
        : _textBlocks.indexWhere((block) => block.id == _selectedTextId);
    if (index >= 0) _textBlocks.removeAt(index);
    _selectedTextId = null;
  }

  void _updateSelected(
    StoryTextBlockEntity Function(StoryTextBlockEntity) update,
  ) {
    final index = _textBlocks.indexWhere(
      (block) => block.id == _selectedTextId,
    );
    if (index < 0) return;
    setState(() => _textBlocks[index] = update(_textBlocks[index]));
  }

  void _cycleSelectedStyle() {
    _updateSelected((block) {
      final styles = StoryTextStyle.values;
      return block.copyWith(
        style: styles[(styles.indexOf(block.style) + 1) % styles.length],
      );
    });
  }

  void _cycleSelectedColor() {
    const colors = [
      Colors.white,
      Colors.black,
      AppColors.primaryContainer,
      AppColors.warning,
    ];
    _updateSelected((block) {
      final current = colors.indexWhere(
        (color) => color.toARGB32() == block.color,
      );
      return block.copyWith(
        color: colors[(current + 1) % colors.length].toARGB32(),
      );
    });
  }

  void _bringSelectedForward() {
    final index = _textBlocks.indexWhere(
      (block) => block.id == _selectedTextId,
    );
    if (index < 0 || index == _textBlocks.length - 1) return;
    setState(() {
      final next = _textBlocks[index + 1];
      final current = _textBlocks[index];
      _textBlocks[index] = current.copyWith(zIndex: next.zIndex);
      _textBlocks[index + 1] = next.copyWith(zIndex: current.zIndex);
    });
  }
}
