import 'editor_models.dart';

/// Presets paramétricos: um modelo → ColorMatrix (imagem) e filtros FFmpeg
/// (vídeo, Fase 2). Labels resolvem via l10n na UI (chave por id).
class FilterPreset {
  const FilterPreset(this.id, this.params);
  final String id;
  final Adjustments params;
}

const filterPresets = [
  FilterPreset('none', Adjustments()),
  FilterPreset('vivid', Adjustments(contrast: .15, saturation: .35)),
  FilterPreset('warm', Adjustments(warmth: .45, saturation: .1)),
  FilterPreset('cool', Adjustments(warmth: -.45, contrast: .05)),
  FilterPreset(
    'vintage',
    Adjustments(fade: .5, warmth: .3, saturation: -.25, vignette: .35),
  ),
  FilterPreset('bw', Adjustments(saturation: -1, contrast: .2)),
  FilterPreset(
    'drama',
    Adjustments(contrast: .4, saturation: -.15, vignette: .4),
  ),
  FilterPreset('fade', Adjustments(fade: .7, contrast: -.1)),
  FilterPreset('sepia', Adjustments(saturation: -.7, warmth: .8, fade: .2)),
];

/// Preset (escalado pela intensidade) + ajustes manuais.
Adjustments effectiveAdjustments(EditorState s) {
  final f = filterPresets.firstWhere(
    (p) => p.id == s.filterId,
    orElse: () => filterPresets.first,
  );
  return f.params.scaled(s.filterIntensity).plus(s.adjustments);
}
