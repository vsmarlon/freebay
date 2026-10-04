import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/widgets/story_text_styles.dart';

class StoryCanvas extends StatefulWidget {
  final List<StoryTextBlockEntity> blocks;
  final Widget background;
  final bool editable;
  final String? selectedId;
  final ValueChanged<List<StoryTextBlockEntity>>? onChanged;
  final ValueChanged<String?>? onSelected;

  const StoryCanvas({
    super.key,
    required this.blocks,
    required this.background,
    this.editable = false,
    this.selectedId,
    this.onChanged,
    this.onSelected,
  });

  @override
  State<StoryCanvas> createState() => _StoryCanvasState();
}

class _StoryCanvasState extends State<StoryCanvas> {
  late List<StoryTextBlockEntity> _blocks;
  final _editingController = TextEditingController();
  final _editingFocusNode = FocusNode();
  String? _selectedId;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _syncBlocks();
    _selectedId = widget.selectedId;
  }

  @override
  void didUpdateWidget(StoryCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blocks != widget.blocks) {
      final previousIds = oldWidget.blocks.map((block) => block.id).toSet();
      _syncBlocks();
      for (final block in widget.blocks.reversed) {
        if (!previousIds.contains(block.id) && widget.editable) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startEditing(block);
          });
          break;
        }
      }
    }
    if (oldWidget.selectedId != widget.selectedId) {
      _selectedId = widget.selectedId;
    }
  }

  @override
  void dispose() {
    _editingController.dispose();
    _editingFocusNode.dispose();
    super.dispose();
  }

  void _syncBlocks() {
    _blocks = [...widget.blocks]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  void _update(StoryTextBlockEntity block) {
    setState(() {
      _blocks = [
        for (final item in _blocks) item.id == block.id ? block : item,
      ];
    });
    widget.onChanged?.call(List.unmodifiable(_blocks));
  }

  void _startEditing(StoryTextBlockEntity block) {
    _editingController.value = TextEditingValue(
      text: block.text,
      selection: TextSelection(baseOffset: 0, extentOffset: block.text.length),
    );
    setState(() {
      _selectedId = block.id;
      _editingId = block.id;
    });
    widget.onSelected?.call(block.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editingFocusNode.requestFocus();
    });
  }

  void _finishEditing() {
    final editingId = _editingId;
    if (editingId == null) return;
    final text = _editingController.text.trim();
    setState(() {
      final index = _blocks.indexWhere((block) => block.id == editingId);
      if (index >= 0) {
        if (text.isEmpty) {
          _blocks.removeAt(index);
          _selectedId = null;
        } else {
          _blocks[index] = _blocks[index].copyWith(text: text);
        }
      }
      _editingId = null;
    });
    _editingFocusNode.unfocus();
    widget.onSelected?.call(_selectedId);
    widget.onChanged?.call(List.unmodifiable(_blocks));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.background,
            for (final block in _blocks)
              Positioned(
                left: block.x * size.width,
                top: block.y * size.height,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _buildBlock(block, size),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBlock(StoryTextBlockEntity block, Size canvasSize) {
    final selected = block.id == _selectedId;
    final editing = block.id == _editingId;
    final color = storyColorFromArgb(block.color);
    final style = storyTextStyle(block.style, color).copyWith(
      fontSize:
          storyTextStyle(block.style, Colors.white).fontSize! * block.scale,
    );

    if (editing) {
      return Transform.rotate(
        angle: block.rotation,
        child: SizedBox(
          width: canvasSize.width * 0.8,
          child: TextField(
            controller: _editingController,
            focusNode: _editingFocusNode,
            autofocus: true,
            maxLength: 200,
            maxLines: null,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            style: style,
            cursorColor: color,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.black54,
              isDense: true,
              contentPadding: EdgeInsets.all(8),
            ),
            onChanged: (text) => _update(block.copyWith(text: text)),
            onSubmitted: (_) => _finishEditing(),
            onTapOutside: (_) => _finishEditing(),
          ),
        ),
      );
    }

    final text = GestureDetector(
      onTap: widget.editable
          ? () {
              setState(() => _selectedId = block.id);
              widget.onSelected?.call(block.id);
            }
          : null,
      onDoubleTap: widget.editable ? () => _startEditing(block) : null,
      onScaleUpdate: widget.editable
          ? (details) {
              final x =
                  (block.x + details.focalPointDelta.dx / canvasSize.width)
                      .clamp(0.0, 1.0);
              final y =
                  (block.y + details.focalPointDelta.dy / canvasSize.height)
                      .clamp(0.0, 1.0);
              _update(
                block.copyWith(
                  x: x,
                  y: y,
                  scale: (block.scale * details.scale).clamp(0.5, 3.0),
                  rotation: (block.rotation + details.rotation).clamp(
                    -math.pi,
                    math.pi,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        padding: selected && widget.editable
            ? const EdgeInsets.all(4)
            : EdgeInsets.zero,
        color: selected && widget.editable
            ? Colors.black.withValues(alpha: 0.18)
            : null,
        child: Text(block.text, textAlign: TextAlign.center, style: style),
      ),
    );
    return Transform.rotate(angle: block.rotation, child: text);
  }
}
