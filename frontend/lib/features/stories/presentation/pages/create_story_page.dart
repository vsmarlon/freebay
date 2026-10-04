import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/media_editor/media_editor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/services/error_reporter.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/controllers/story_submission_coordinator.dart';
import 'package:freebay/features/stories/presentation/widgets/story_capture_view.dart';
import 'package:freebay/features/stories/presentation/widgets/story_preview_view.dart';

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
  StoryAudience _audience = StoryAudience.everyone;
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
    } catch (error, stackTrace) {
      ErrorReporter.report('story-camera-init', error, stackTrace);
      if (mounted) {
        setState(() => _cameraError = l10n(context).feedCameraUnavailable);
      }
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
    } catch (error, stackTrace) {
      ErrorReporter.report('story-camera-capture', error, stackTrace);
      setState(() {
        _isTakingPicture = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).feedCameraUnavailable)),
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
    } catch (error, stackTrace) {
      ErrorReporter.report('story-media-pick', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).feedMediaPickFailed)),
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
    } catch (error, stackTrace) {
      ErrorReporter.report('story-image-edit', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).feedImageEditFailed)),
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
      final repository = ref.read(storiesRepositoryProvider);
      final result = await _submissionCoordinator.submit(
        repository: repository,
        imagePath: _capturedImagePath!,
        caption: _captionController.text,
        textBlocks: _textBlocks,
        audience: _audience,
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
    } catch (error, stackTrace) {
      ErrorReporter.report('story-upload', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n(context).feedStoryUploadFailed)),
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

    return StoryCaptureView(
      cameraController: _cameraController,
      isInitialized: _isInitialized,
      isTakingPicture: _isTakingPicture,
      canSwitchCamera: _cameras != null && _cameras!.length > 1,
      cameraError: _cameraError,
      onClose: () => Navigator.pop(context),
      onSwitchCamera: _switchCamera,
      onPickFromGallery: _pickFromGallery,
      onTakePicture: _takePicture,
    );
  }

  Widget _buildPreviewScreen(BuildContext context) {
    return StoryPreviewView(
      mediaPath: _capturedImagePath!,
      videoController: _videoController,
      textBlocks: _textBlocks,
      selectedTextId: _selectedTextId,
      captionController: _captionController,
      isLoading: _isLoading,
      audience: _audience,
      onAudienceChanged: (audience) => setState(() => _audience = audience),
      onManageCloseFriends: () => context.push(AppRoutes.profileCloseFriends),
      onClose: () => setState(() => _capturedImagePath = null),
      onUpload: _uploadStory,
      onBlocksChanged: (blocks) => setState(() {
        _textBlocks
          ..clear()
          ..addAll(blocks);
      }),
      onSelected: (id) => setState(() => _selectedTextId = id),
      onAddText: _addTextBlock,
      onRemoveText: () => setState(_removeLastTextBlock),
      onCycleStyle: _cycleSelectedStyle,
      onCycleColor: _cycleSelectedColor,
      onBringForward: _bringSelectedForward,
    );
  }

  void _addTextBlock() {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _textBlocks.add(
        StoryTextBlockEntity(
          id: id,
          text: l10n(context).chatEditorTextDefault,
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
