import 'dart:async';
import 'dart:io';

import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';
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

class _CreateStoryPageState extends ConsumerState<CreateStoryPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _useFrontCamera = true;
  String? _capturedImagePath;
  bool _isLoading = false;
  StoryAudience _audience = StoryAudience.everyone;
  String? _cameraError;
  int _cameraGeneration = 0;
  bool _isInitializingCamera = false;
  CameraController? _disposingCamera;
  Future<void>? _cameraDisposal;
  final _captionController = TextEditingController();
  final List<StoryTextBlockEntity> _textBlocks = [];
  String? _selectedTextId;
  VideoPlayerController? _videoController;
  String? _editorOwnedVideoPath;
  final StorySubmissionCoordinator _submissionCoordinator =
      StorySubmissionCoordinator();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initCamera();
    } else {
      _cameraGeneration++;
      _isInitializingCamera = false;
      _isInitialized = false;
      final disposal = _disposeCamera();
      if (mounted) setState(() {});
      unawaited(disposal);
    }
  }

  Future<void> _initCamera() async {
    if (_isInitialized || _isInitializingCamera) return;
    _isInitializingCamera = true;
    final generation = ++_cameraGeneration;
    _cameraError = null;
    try {
      _cameras = await availableCameras().timeout(const Duration(seconds: 10));
      if (!mounted || generation != _cameraGeneration) return;
      if (_cameras!.isNotEmpty) {
        final camera = _cameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        await _initializeCameraController(
          camera,
          ResolutionPreset.medium,
          generation,
        );
      } else {
        throw StateError('No cameras available');
      }
    } catch (error, stackTrace) {
      _handleCameraError(error, stackTrace, generation);
    } finally {
      if (generation == _cameraGeneration) _isInitializingCamera = false;
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription camera,
    ResolutionPreset resolution,
    int generation,
  ) async {
    final pendingDisposal = _cameraDisposal;
    if (pendingDisposal != null) {
      await pendingDisposal.timeout(const Duration(seconds: 10));
    }
    if (!mounted || generation != _cameraGeneration) return;

    final controller = CameraController(camera, resolution, enableAudio: false);
    _cameraController = controller;
    await controller.initialize().timeout(const Duration(seconds: 10));
    if (!mounted || generation != _cameraGeneration) {
      await _disposeCamera(controller);
      return;
    }
    setState(() => _isInitialized = true);
  }

  Future<void> _disposeCamera([CameraController? controller]) {
    final target = controller ?? _cameraController;
    if (identical(_cameraController, target)) _cameraController = null;
    if (target == null) return Future<void>.value();
    if (identical(_disposingCamera, target)) return _cameraDisposal!;
    late final Future<void> disposal;
    disposal = target
        .dispose()
        .catchError((Object error, StackTrace stackTrace) {
          ErrorReporter.report('story-camera-dispose', error, stackTrace);
        })
        .whenComplete(() {
          if (identical(_cameraDisposal, disposal)) {
            _cameraDisposal = null;
            _disposingCamera = null;
          }
        });
    _disposingCamera = target;
    _cameraDisposal = disposal;
    return disposal;
  }

  void _handleCameraError(Object error, StackTrace stackTrace, int generation) {
    ErrorReporter.report('story-camera-init', error, stackTrace);
    if (!mounted || generation != _cameraGeneration) return;
    _isInitialized = false;
    unawaited(_disposeCamera());
    setState(() => _cameraError = l10n(context).feedCameraUnavailable);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraGeneration++;
    unawaited(_disposeCamera());
    _videoController?.dispose();
    final ownedVideo = _editorOwnedVideoPath;
    if (ownedVideo != null) {
      unawaited(File(ownedVideo).delete().catchError((_) => File(ownedVideo)));
    }
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
      if (!mounted) return;
      setState(() => _isTakingPicture = false);
      await _openImageEditor(image.path);
    } catch (error, stackTrace) {
      ErrorReporter.report('story-camera-capture', error, stackTrace);
      if (mounted) {
        setState(() => _isTakingPicture = false);
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
      if (!mounted) return;

      if (image != null) {
        if (_isVideo(image.path)) {
          final edited = await showVideoEditor(context, File(image.path));
          if (edited != null && mounted) {
            final previous = _editorOwnedVideoPath;
            _editorOwnedVideoPath = edited.path;
            await _setVideo(edited.path);
            if (previous != null) {
              try {
                await File(previous).delete();
              } on FileSystemException {
                /* already replaced */
              }
            }
          }
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
      final request = ImageEditorRouteRequest(
        imageBytes: bytes,
        purpose: ImageEditorPurpose.story,
        onComplete: (ImageEditorResult result) async {
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
      );
      await request.push<void>(context, AppRoutes.imageEditor);
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

  Future<void> _switchCamera() async {
    if (_isInitializingCamera || _cameras == null || _cameras!.length < 2) {
      return;
    }
    _isInitializingCamera = true;
    final generation = ++_cameraGeneration;
    final useFrontCamera = !_useFrontCamera;
    _cameraError = null;
    setState(() => _isInitialized = false);
    try {
      final camera = _cameras!.firstWhere(
        (cam) => useFrontCamera
            ? cam.lensDirection == CameraLensDirection.front
            : cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );
      await _disposeCamera();
      await _initializeCameraController(
        camera,
        ResolutionPreset.high,
        generation,
      );
      if (mounted && generation == _cameraGeneration && _isInitialized) {
        setState(() => _useFrontCamera = useFrontCamera);
      }
    } catch (error, stackTrace) {
      _handleCameraError(error, stackTrace, generation);
    } finally {
      if (generation == _cameraGeneration) _isInitializingCamera = false;
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
      onRetryCamera: _initCamera,
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
