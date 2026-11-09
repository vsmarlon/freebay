import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:uuid/uuid.dart';

import '../../domain/editor_models.dart';

/// Overlay fullscreen de edição de texto (estilo Instagram): campo central,
/// slider vertical de tamanho, alinhamento e fundo cíclicos, fontes e paleta
/// acima do teclado. Retorna um [TextLayer] ou null (cancelado/vazio).
class TextEditorOverlay extends StatefulWidget {
  const TextEditorOverlay({super.key, this.initial});
  final TextLayer? initial;

  static Future<TextLayer?> show(BuildContext context, {TextLayer? initial}) =>
      showGeneralDialog<TextLayer>(
        context: context,
        barrierColor: Colors.transparent,
        pageBuilder: (_, _, _) => TextEditorOverlay(initial: initial),
      );

  @override
  State<TextEditorOverlay> createState() => _TextEditorOverlayState();
}

class _TextEditorOverlayState extends State<TextEditorOverlay> {
  static const fonts = ['SpaceGrotesk', 'Inter'];
  static const palette = [
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF34C759),
    Color(0xFF00C7BE),
    Color(0xFF0A84FF),
    Color(0xFF5E5CE6),
    Color(0xFFFF2D55),
  ];

  late final _controller = TextEditingController(
    text: widget.initial?.text ?? '',
  );
  late TextLayer _layer =
      widget.initial ?? TextLayer(id: const Uuid().v4(), text: '');

  void _cycleBg() => setState(
    () =>
        _layer = _layer.copyWith(bg: TextBg.values[(_layer.bg.index + 1) % 3]),
  );

  void _cycleAlign() => setState(
    () => _layer = _layer.copyWith(
      align: switch (_layer.align) {
        TextAlign.center => TextAlign.left,
        TextAlign.left => TextAlign.right,
        _ => TextAlign.center,
      },
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: context.colors.scrim.withAlpha(191),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Concluir',
                  icon: const Icon(Icons.check, color: AppColors.white),
                  onPressed: () => Navigator.pop(
                    context,
                    _controller.text.trim().isEmpty
                        ? null
                        : _layer.copyWith(text: _controller.text),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.format_align_center,
                    color: AppColors.white,
                  ),
                  onPressed: _cycleAlign,
                ),
                IconButton(
                  icon: const Icon(Icons.text_fields, color: AppColors.white),
                  onPressed: _cycleBg,
                ),
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  // slider vertical de tamanho
                  SizedBox(
                    height: 220,
                    width: 48,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _layer.sizeFactor,
                        min: .04,
                        max: .2,
                        onChanged: (v) => setState(
                          () => _layer = _layer.copyWith(sizeFactor: v),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (_, constraints) {
                          final fontSize =
                              constraints.maxWidth * _layer.sizeFactor;
                          return TextField(
                            controller: _controller,
                            autofocus: true,
                            maxLines: null,
                            textAlign: _layer.align,
                            cursorColor: AppColors.white,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: AppTypography.h2.copyWith(
                              fontFamily: _layer.font,
                              fontSize: fontSize,
                              color: _layer.color,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final font in fonts)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('Aa'),
                        labelStyle: AppTypography.labelLarge.weight(700).copyWith(
                          fontFamily: font,
                        ),
                        selected: _layer.font == font,
                        onSelected: (_) => setState(
                          () => _layer = _layer.copyWith(font: font),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final color in palette)
                    GestureDetector(
                      onTap: () => setState(
                        () => _layer = _layer.copyWith(color: color),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(
                            color: AppColors.white,
                            width: _layer.color == color ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: keyboard),
          ],
        ),
      ),
    );
  }
}
