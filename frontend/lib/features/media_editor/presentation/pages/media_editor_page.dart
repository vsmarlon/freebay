import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/services/error_reporter.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../application/editor_config.dart';
import '../../application/editor_controller.dart';
import '../../data/image_loader.dart';
import '../../data/media_exporter.dart';
import '../../data/video_probe.dart';
import '../../domain/crop_geometry.dart';
import '../../domain/edited_media.dart';
import '../../domain/editor_models.dart';
import '../editor_canvas.dart';
import '../widgets/crop_toolbar.dart';
import '../widgets/draw_palette.dart';
import '../widgets/editor_dialogs.dart';
import '../widgets/filter_adjust_sheet.dart';
import '../widgets/image_editor_models.dart';
import '../widgets/sticker_sheet.dart';
import '../widgets/video_trim_bar.dart';
import 'crop_tool.dart';
import 'text_editor_overlay.dart';

enum EditorActiveTool { none, draw, crop, filterAdjust }

/// Página principal do Media Editor (V2) para imagem e vídeo.
class MediaEditorPage extends ConsumerStatefulWidget {
  const MediaEditorPage({
    super.key,
    this.initialImageBytes,
    this.initialFile,
    this.config = EditorConfig.chat,
    this.purpose = ImageEditorPurpose.chat,
    this.initialViewOnce = false,
    this.onComplete,
  });

  final Uint8List? initialImageBytes;
  final File? initialFile;
  final EditorConfig config;
  final ImageEditorPurpose purpose;
  final bool initialViewOnce;
  final Future<bool> Function(ImageEditorResult result)? onComplete;

  static Future<EditedMedia?> push(
    BuildContext context, {
    Uint8List? imageBytes,
    File? file,
    EditorConfig config = EditorConfig.chat,
  }) => Navigator.of(context).push<EditedMedia>(
    MaterialPageRoute(
      builder: (_) => MediaEditorPage(
        initialImageBytes: imageBytes,
        initialFile: file,
        config: config,
      ),
    ),
  );

  @override
  ConsumerState<MediaEditorPage> createState() => _MediaEditorPageState();
}

class _MediaEditorPageState extends ConsumerState<MediaEditorPage> {
  final _sessionId = const Uuid().v4();
  final _exportKey = GlobalKey();
  final _overlayKey = GlobalKey();

  bool _initialized = false;
  FlutterErrorDetails? _initError;
  bool _isExporting = false;

  ui.Image? _decodedImage;
  VideoPlayerController? _videoController;

  EditorActiveTool _activeTool = EditorActiveTool.none;

  // Desenho
  final _liveStroke = ValueNotifier<Stroke?>(null);
  List<Offset> _currentStrokePoints = [];
  StrokeKind _strokeKind = StrokeKind.pen;
  Color _drawColor = AppColors.white;
  double _drawWidthPx = 8.0;

  // Ajustes ao vivo
  final _liveAdjustments = ValueNotifier<Adjustments?>(null);

  // Legenda
  late final TextEditingController _captionController;

  // Vídeo
  int _videoPositionMs = 0;
  final List<File> _videoThumbs = [];

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    try {
      if (widget.initialFile != null && _isVideo(widget.initialFile!.path)) {
        final (controller, size, durationMs) = await VideoProbe.open(
          widget.initialFile!.path,
        );
        _videoController = controller;
        controller.addListener(_onVideoTick);
        await controller.play();

        final cropState = widget.config.forceAspect != null
            ? CropState(
                rect: centeredAspectCrop(size, widget.config.forceAspect),
                lockedAspect: widget.config.forceAspect,
              )
            : const CropState();

        final initial = EditorState(
          kind: MediaKind.video,
          sourcePath: widget.initialFile!.path,
          sourceSize: size,
          crop: cropState,
          video: VideoEdits(durationMs: durationMs),
          viewOnce: widget.initialViewOnce,
        );

        ref
            .read(editorControllerProvider(_sessionId).notifier)
            .initialize(initial);
      } else {
        Uint8List bytes;
        String? path;
        if (widget.initialImageBytes != null) {
          bytes = widget.initialImageBytes!;
        } else if (widget.initialFile != null) {
          bytes = await widget.initialFile!.readAsBytes();
          path = widget.initialFile!.path;
        } else {
          throw const FormatException('No media provided to editor');
        }

        final image = await decodeForPreview(bytes);
        _decodedImage = image;

        final sourceSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );
        final cropState = widget.config.forceAspect != null
            ? CropState(
                rect: centeredAspectCrop(sourceSize, widget.config.forceAspect),
                lockedAspect: widget.config.forceAspect,
              )
            : const CropState();

        final initial = EditorState(
          sourcePath: path,
          sourceSize: sourceSize,
          crop: cropState,
          viewOnce: widget.initialViewOnce,
        );

        ref
            .read(editorControllerProvider(_sessionId).notifier)
            .initialize(initial);
      }

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('media-editor-load diagnostic: $error\n$stackTrace');
      ErrorReporter.report('media-editor-load', error, stackTrace);
      if (mounted) {
        setState(() {
          _initError = FlutterErrorDetails(exception: error, stack: stackTrace);
        });
      }
    }
  }

  bool _isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.webm');
  }

  void _onVideoTick() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    final state = ref.read(editorControllerProvider(_sessionId)).present;
    final v = state.video;
    if (v == null) return;

    final pos = c.value.position.inMilliseconds;
    if (mounted) {
      setState(() => _videoPositionMs = pos);
    }
    if (pos >= v.trimEndMs || pos < v.trimStartMs - 200) {
      c.seekTo(Duration(milliseconds: v.trimStartMs));
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]);
    _captionController.dispose();
    _liveStroke.dispose();
    _liveAdjustments.dispose();
    _decodedImage?.dispose();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  Future<bool> _handlePop() async {
    final history = ref.read(editorControllerProvider(_sessionId));
    if (!history.hasChanges) return true;
    final discard = await showDiscardEditorDialog(context);
    return discard == true;
  }

  // --- Ações de Desenho ---

  void _onStrokeStart(Offset normalized) {
    _currentStrokePoints = [normalized];
    final wFactor =
        _drawWidthPx /
        (ref
            .read(editorControllerProvider(_sessionId))
            .present
            .sourceSize
            .width
            .clamp(100.0, 4000.0));
    _liveStroke.value = Stroke(
      kind: _strokeKind,
      points: _currentStrokePoints,
      color: _drawColor,
      widthFactor: wFactor,
    );
  }

  void _onStrokeUpdate(Offset normalized) {
    _currentStrokePoints.add(normalized);
    final wFactor =
        _drawWidthPx /
        (ref
            .read(editorControllerProvider(_sessionId))
            .present
            .sourceSize
            .width
            .clamp(100.0, 4000.0));
    _liveStroke.value = Stroke(
      kind: _strokeKind,
      points: List.of(_currentStrokePoints),
      color: _drawColor,
      widthFactor: wFactor,
    );
  }

  void _onStrokeEnd() {
    final stroke = _liveStroke.value;
    _liveStroke.value = null;
    _currentStrokePoints = [];
    if (stroke != null && stroke.points.length > 1) {
      ref.read(editorControllerProvider(_sessionId).notifier).addStroke(stroke);
    }
  }

  // --- Ações de Texto ---

  Future<void> _openTextEditor({TextLayer? existing}) async {
    final result = await TextEditorOverlay.show(context, initial: existing);
    if (result != null) {
      final ctrl = ref.read(editorControllerProvider(_sessionId).notifier);
      if (existing != null) {
        ctrl.updateLayer(result);
      } else {
        ctrl.addLayer(result);
      }
    }
  }

  // --- Export ---

  Future<void> _onExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final ctrl = ref.read(editorControllerProvider(_sessionId).notifier);
      ctrl.setCaption(_captionController.text.trim());
      final state = ref.read(editorControllerProvider(_sessionId)).present;

      final edited = await MediaExporter().run(
        state,
        exportKey: _exportKey,
        overlayKey: _overlayKey,
        ctrl: ctrl,
      );

      if (widget.onComplete != null) {
        final bytes = await edited.file.readAsBytes();
        final result = ImageEditorResult(
          imageBytes: bytes,
          caption: edited.caption.isEmpty ? null : edited.caption,
          viewOnce: edited.viewOnce,
        );
        final success = await widget.onComplete!(result);
        if (success && mounted) {
          Navigator.of(context).pop();
        }
      } else if (mounted) {
        Navigator.of(context).pop(edited);
      }
    } catch (error, stackTrace) {
      ErrorReporter.report('media-editor-export', error, stackTrace);
      if (mounted) {
        AppSnackbar.error(context, l10n(context).chatEditorProcessingError);
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(editorControllerProvider(_sessionId));
    if (_initError != null) {
      // Regra do owner: nunca mostrar a exceção cru — cópia genérica + log.
      return Scaffold(
        backgroundColor: context.bgColor,
        body: AppErrorWidget(
          details: _initError!,
          action: AppErrorAction.back,
          onRecover: () async => Navigator.pop(context),
        ),
      );
    }

    if (!_initialized) {
      return Scaffold(
        backgroundColor: context.bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = history.present;
    final isVideo = state.kind == MediaKind.video;

    return PopScope(
      canPop: !history.hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _handlePop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Stack(
            children: [
              // 1. ÁREA CENTRAL: CANVAS WYSIWYG ou CROP CANVAS
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 56,
                    bottom: _activeTool == EditorActiveTool.none ? 90 : 120,
                  ),
                  child: _isToolModeCrop(state)
                      ? CropCanvas(
                          image: _decodedImage!,
                          crop: state.crop,
                          circular: widget.config.circularPreview,
                          onChanged: (c) {},
                          onCommit: (c) => ref
                              .read(
                                editorControllerProvider(_sessionId).notifier,
                              )
                              .setCrop(c),
                        )
                      : EditorCanvas(
                          sessionId: _sessionId,
                          exportKey: _exportKey,
                          overlayKey: _overlayKey,
                          image: _decodedImage,
                          video: _videoController,
                          liveStroke: _liveStroke,
                          liveAdjustments: _liveAdjustments,
                          interactive: _activeTool == EditorActiveTool.none,
                          onStrokeStart: _activeTool == EditorActiveTool.draw
                              ? _onStrokeStart
                              : null,
                          onStrokeUpdate: _activeTool == EditorActiveTool.draw
                              ? _onStrokeUpdate
                              : null,
                          onStrokeEnd: _activeTool == EditorActiveTool.draw
                              ? _onStrokeEnd
                              : null,
                          onLayerEdit: (layer) {
                            if (layer is TextLayer) {
                              _openTextEditor(existing: layer);
                            }
                          },
                        ),
                ),
              ),

              // 2. TOPO: BOTÕES DE NAVEGAÇÃO E HISTÓRICO
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(history, state, isVideo),
              ),

              // 3. BARRA DE FERRAMENTAS FLUTUANTE (Modo Normal)
              if (_activeTool == EditorActiveTool.none)
                Positioned(top: 60, right: 12, child: _buildSideToolbar(state)),

              // 4. FERRAMENTA ATIVA (Crop Toolbar, Draw Palette ou Filter Sheet)
              if (_activeTool == EditorActiveTool.crop)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CropToolbar(
                    crop: state.crop,
                    availableAspects: widget.config.aspects,
                    onAspectSelected: (aspect) => ref
                        .read(editorControllerProvider(_sessionId).notifier)
                        .setAspect(aspect),
                    onRotate90: () => ref
                        .read(editorControllerProvider(_sessionId).notifier)
                        .rotate90(),
                    onFlip: () => ref
                        .read(editorControllerProvider(_sessionId).notifier)
                        .flip(),
                    onStraightenChanged: (deg) => ref
                        .read(editorControllerProvider(_sessionId).notifier)
                        .setStraighten(deg),
                    onDone: () =>
                        setState(() => _activeTool = EditorActiveTool.none),
                  ),
                ),

              if (_activeTool == EditorActiveTool.draw)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DrawPalette(
                        strokeKind: _strokeKind,
                        blur:
                            widget.config.blur && state.kind == MediaKind.image,
                        color: _drawColor,
                        widthPx: _drawWidthPx,
                        onStrokeKind: (k) => setState(() => _strokeKind = k),
                        onColor: (c) => setState(() => _drawColor = c),
                        onWidthPx: (w) => setState(() => _drawWidthPx = w),
                      ),
                      Container(
                        color: context.surfaceHighColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppButton(
                              label: l10n(context).commonDone,
                              size: AppButtonSize.compact,
                              onPressed: () => setState(
                                () => _activeTool = EditorActiveTool.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (_activeTool == EditorActiveTool.filterAdjust)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: FilterAdjustBar(
                    selectedFilterId: state.filterId,
                    filterIntensity: state.filterIntensity,
                    adjustments: state.adjustments,
                    onFilterChanged: (id) => ref
                        .read(editorControllerProvider(_sessionId).notifier)
                        .setFilter(id),
                    onFilterIntensityChanged: (val) => ref
                        .read(editorControllerProvider(_sessionId).notifier)
                        .setFilter(state.filterId, intensity: val),
                    onAdjustmentsLive: (adj) => _liveAdjustments.value = adj,
                    onAdjustmentsCommit: (adj) {
                      _liveAdjustments.value = null;
                      ref
                          .read(editorControllerProvider(_sessionId).notifier)
                          .setAdjustments(adj);
                    },
                    onClose: () {
                      _liveAdjustments.value = null;
                      setState(() => _activeTool = EditorActiveTool.none);
                    },
                  ),
                ),

              // 5. BASE (Modo Normal): Legenda + Controles de Envio
              if (_activeTool == EditorActiveTool.none)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  // resizeToAvoidBottomInset: false → sobe só a barra do teclado.
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: _buildBottomBar(state, isVideo),
                  ),
                ),

              // 6. OVERLAY DE EXPORTAÇÃO (Loading)
              if (_isExporting)
                Positioned.fill(
                  child: Container(
                    color: context.colors.scrim.withAlpha(138),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.white),
                          Spacing.vMd,
                          Text(
                            l10n(context).mediaEditorProcessing,
                            style: AppTypography.bodyMedium.weight(700).copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToolModeCrop(EditorState state) =>
      _activeTool == EditorActiveTool.crop &&
      widget.config.crop &&
      _decodedImage != null;

  Widget _buildTopBar(EditorHistory history, EditorState state, bool isVideo) {
    final ctrl = ref.read(editorControllerProvider(_sessionId).notifier);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      color: context.surfaceColor,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: context.textPrimary),
            onPressed: () async {
              if (await _handlePop() && mounted) Navigator.pop(context);
            },
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.undo,
              color: history.canUndo
                  ? context.textPrimary
                  : context.textSecondary,
            ),
            onPressed: history.canUndo ? ctrl.undo : null,
          ),
          IconButton(
            icon: Icon(
              Icons.redo,
              color: history.canRedo
                  ? context.textPrimary
                  : context.textSecondary,
            ),
            onPressed: history.canRedo ? ctrl.redo : null,
          ),
          if (widget.config.hdToggle) ...[
            Spacing.hXs,
            GestureDetector(
              onTap: () => ctrl.setHd(!state.hd),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: state.hd
                      ? context.colors.primaryContainer
                      : Colors.transparent,
                  border: Border.all(
                    color: state.hd
                        ? context.colors.primaryContainer
                        : context.borderColor,
                  ),
                ),
                child: Text(
                  'HD',
                  style: AppTypography.labelSmall.copyWith(
                    color: state.hd
                        ? context.colors.onPrimaryContainer
                        : context.textPrimary,
                  ),
                ),
              ),
            ),
          ],
          if (isVideo && state.video != null) ...[
            Spacing.hXs,
            IconButton(
              icon: Icon(
                state.video!.muted ? Icons.volume_off : Icons.volume_up,
                color: context.textPrimary,
              ),
              onPressed: () {
                final next = state.video!.copyWith(muted: !state.video!.muted);
                ctrl.setVideo(next);
                _videoController?.setVolume(next.muted ? 0 : 1);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSideToolbar(EditorState state) {
    final strings = l10n(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.xs),
      decoration: BoxDecoration(
        color: context.surfaceHighColor,
        border: Border.all(color: context.borderSoftColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.config.crop && state.kind == MediaKind.image)
            _ToolIcon(
              icon: Icons.crop,
              tooltip: strings.chatEditorCrop,
              onTap: () => setState(() => _activeTool = EditorActiveTool.crop),
            ),
          if (widget.config.text)
            _ToolIcon(
              icon: Icons.title,
              tooltip: strings.chatEditorText,
              onTap: _openTextEditor,
            ),
          if (widget.config.stickers)
            _ToolIcon(
              icon: Icons.emoji_emotions_outlined,
              tooltip: strings.mediaEditorSticker,
              onTap: () => StickerPicker.show(
                context: context,
                onAddSticker: (layer) => ref
                    .read(editorControllerProvider(_sessionId).notifier)
                    .addLayer(layer),
              ),
            ),
          if (widget.config.draw)
            _ToolIcon(
              icon: Icons.brush,
              tooltip: strings.chatEditorDraw,
              onTap: () => setState(() => _activeTool = EditorActiveTool.draw),
            ),
          if (widget.config.filters || widget.config.adjust)
            _ToolIcon(
              icon: Icons.tune,
              tooltip: strings.chatEditorFilter,
              onTap: () =>
                  setState(() => _activeTool = EditorActiveTool.filterAdjust),
            ),
          if (widget.config.blur && state.kind == MediaKind.image)
            _ToolIcon(
              icon: Icons.blur_on,
              tooltip: strings.mediaEditorBlur,
              onTap: () {
                setState(() {
                  _strokeKind = StrokeKind.blur;
                  _activeTool = EditorActiveTool.draw;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(EditorState state, bool isVideo) {
    final ctrl = ref.read(editorControllerProvider(_sessionId).notifier);
    final strings = l10n(context);

    return Container(
      color: context.surfaceColor,
      padding: EdgeInsets.only(
        left: Spacing.md,
        right: Spacing.md,
        top: Spacing.sm,
        bottom: MediaQuery.viewPaddingOf(context).bottom + Spacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVideo && state.video != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: VideoTrimBar(
                thumbs: _videoThumbs,
                durationMs: state.video!.durationMs,
                startMs: state.video!.trimStartMs,
                endMs: state.video!.trimEndMs,
                positionMs: _videoPositionMs,
                onChanged: (start, end) {
                  _videoController?.pause();
                  _videoController?.seekTo(Duration(milliseconds: start));
                },
                onChangeEnd: (start, end) {
                  final next = state.video!.copyWith(
                    trimStartMs: start,
                    trimEndMs: end,
                  );
                  ctrl.setVideo(next);
                  _videoController?.seekTo(Duration(milliseconds: start));
                  _videoController?.play();
                },
              ),
            ),
          Row(
            children: [
              if (widget.config.caption)
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                    color: context.surfaceHighColor,
                    child: TextField(
                      controller: _captionController,
                      minLines: 1,
                      maxLines: 3,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: strings.chatImageCaption,
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: context.textSecondary,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: ctrl.setCaption,
                    ),
                  ),
                ),
              if (widget.config.viewOnce) ...[
                Spacing.hSm,
                Semantics(
                  button: true,
                  selected: state.viewOnce,
                  label: strings.chatViewOnce,
                  child: GestureDetector(
                    onTap: () => ctrl.setViewOnce(!state.viewOnce),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: state.viewOnce
                            ? context.colors.primaryContainer
                            : context.surfaceHighColor,
                        border: Border.all(
                          color: state.viewOnce
                              ? context.colors.primaryContainer
                              : context.borderColor,
                        ),
                      ),
                      child: Icon(
                        Icons.looks_one,
                        color: state.viewOnce
                            ? context.colors.onPrimaryContainer
                            : context.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
              Spacing.hSm,
              FloatingActionButton(
                backgroundColor: context.colors.primaryContainer,
                shape: const RoundedRectangleBorder(),
                onPressed: _onExport,
                child: Icon(Icons.send, color: context.colors.onPrimaryContainer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: context.textPrimary, size: 22),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}
