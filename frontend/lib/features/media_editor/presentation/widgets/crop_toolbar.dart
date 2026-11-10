import 'package:flutter/material.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

import '../../domain/editor_models.dart';

class CropToolbar extends StatelessWidget {
  const CropToolbar({
    super.key,
    required this.crop,
    required this.availableAspects,
    required this.onAspectSelected,
    required this.onRotate90,
    required this.onFlip,
    required this.onStraightenChanged,
    required this.onDone,
  });

  final CropState crop;
  final List<double?> availableAspects;
  final ValueChanged<double?> onAspectSelected;
  final VoidCallback onRotate90;
  final VoidCallback onFlip;
  final ValueChanged<double> onStraightenChanged;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      color: Colors.black.withAlpha(220),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom + 8,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Straighten dial/slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.straighten, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: crop.straightenDeg.clamp(-45.0, 45.0),
                    min: -45.0,
                    max: 45.0,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    onChanged: onStraightenChanged,
                  ),
                ),
                Text(
                  '${crop.straightenDeg.round()}°',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          // Botoes de girar, espelhar e aspectos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: strings.mediaEditorRotate90,
                  icon: const Icon(
                    Icons.rotate_90_degrees_cw,
                    color: Colors.white,
                  ),
                  onPressed: onRotate90,
                ),
                IconButton(
                  tooltip: strings.mediaEditorFlip,
                  icon: const Icon(Icons.flip, color: Colors.white),
                  onPressed: onFlip,
                ),
                const SizedBox(width: 8),
                for (final aspect in availableAspects)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        _aspectLabel(aspect, free: strings.chatEditorCropFree),
                        style: TextStyle(
                          color: _isAspectSelected(aspect)
                              ? Colors.black
                              : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: _isAspectSelected(aspect),
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white12,
                      shape: const RoundedRectangleBorder(),
                      onSelected: (_) => onAspectSelected(aspect),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: strings.commonDone,
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isAspectSelected(double? aspect) {
    if (aspect == null) return crop.lockedAspect == null;
    if (crop.lockedAspect == null) return false;
    return (crop.lockedAspect! - aspect).abs() < 0.01;
  }

  /// Rótulos numéricos de protocolo (1:1, 4:5...) — não traduzidos.
  String _aspectLabel(double? aspect, {required String free}) {
    if (aspect == null) return free;
    if ((aspect - 1.0).abs() < 0.01) return '1:1';
    if ((aspect - 4 / 5).abs() < 0.01) return '4:5';
    if ((aspect - 16 / 9).abs() < 0.01) return '16:9';
    if ((aspect - 9 / 16).abs() < 0.01) return '9:16';
    return aspect.toStringAsFixed(2);
  }
}
