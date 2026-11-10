import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

import '../../domain/editor_models.dart';
import '../../domain/filter_presets.dart';

enum FilterAdjustTab { filters, adjustments }

class FilterAdjustBar extends StatefulWidget {
  const FilterAdjustBar({
    super.key,
    required this.selectedFilterId,
    required this.filterIntensity,
    required this.adjustments,
    required this.onFilterChanged,
    required this.onFilterIntensityChanged,
    required this.onAdjustmentsLive,
    required this.onAdjustmentsCommit,
    required this.onClose,
  });

  final String selectedFilterId;
  final double filterIntensity;
  final Adjustments adjustments;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<double> onFilterIntensityChanged;
  final ValueChanged<Adjustments> onAdjustmentsLive;
  final ValueChanged<Adjustments> onAdjustmentsCommit;
  final VoidCallback onClose;

  @override
  State<FilterAdjustBar> createState() => _FilterAdjustBarState();
}

class _FilterAdjustBarState extends State<FilterAdjustBar> {
  FilterAdjustTab _tab = FilterAdjustTab.filters;
  late Adjustments _liveAdjustments = widget.adjustments;
  late double _intensity = widget.filterIntensity;
  String _activeAdjustProp = 'brightness';

  @override
  void didUpdateWidget(covariant FilterAdjustBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adjustments != widget.adjustments) {
      _liveAdjustments = widget.adjustments;
    }
    if (oldWidget.filterIntensity != widget.filterIntensity) {
      _intensity = widget.filterIntensity;
    }
  }

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
          // Header com abas e fechar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _HeaderTab(
                  label: strings.chatEditorTitleFilters,
                  isSelected: _tab == FilterAdjustTab.filters,
                  onTap: () => setState(() => _tab = FilterAdjustTab.filters),
                ),
                const SizedBox(width: 12),
                _HeaderTab(
                  label: strings.chatEditorTitleAdjust,
                  isSelected: _tab == FilterAdjustTab.adjustments,
                  onTap: () =>
                      setState(() => _tab = FilterAdjustTab.adjustments),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_tab == FilterAdjustTab.filters) _buildFiltersView(strings),
          if (_tab == FilterAdjustTab.adjustments)
            _buildAdjustmentsView(strings),
        ],
      ),
    );
  }

  Widget _buildFiltersView(AppLocalizations strings) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.selectedFilterId != 'none')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                Text(
                  strings.mediaEditorIntensity,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _intensity,
                    activeColor: AppColors.primaryContainer,
                    onChanged: (v) {
                      setState(() => _intensity = v);
                      widget.onFilterIntensityChanged(v);
                    },
                  ),
                ),
                Text(
                  '${(_intensity * 100).round()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final preset in filterPresets)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      _labelForPreset(preset.id, strings),
                      style: TextStyle(
                        color: widget.selectedFilterId == preset.id
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: widget.selectedFilterId == preset.id,
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white10,
                    shape: const RoundedRectangleBorder(),
                    onSelected: (_) => widget.onFilterChanged(preset.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentsView(AppLocalizations strings) {
    final props = [
      (
        'brightness',
        strings.chatEditorBrightness,
        -1.0,
        1.0,
        _liveAdjustments.brightness,
      ),
      (
        'contrast',
        strings.chatEditorContrast,
        -1.0,
        1.0,
        _liveAdjustments.contrast,
      ),
      (
        'saturation',
        strings.chatEditorSaturation,
        -1.0,
        1.0,
        _liveAdjustments.saturation,
      ),
      ('warmth', strings.mediaEditorWarmth, -1.0, 1.0, _liveAdjustments.warmth),
      ('fade', strings.mediaEditorFade, 0.0, 1.0, _liveAdjustments.fade),
      (
        'vignette',
        strings.mediaEditorVignette,
        0.0,
        1.0,
        _liveAdjustments.vignette,
      ),
    ];

    final current = props.firstWhere((p) => p.$1 == _activeAdjustProp);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slider do ajuste selecionado
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 75,
                child: Text(
                  current.$2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: current.$5.clamp(current.$3, current.$4),
                  min: current.$3,
                  max: current.$4,
                  activeColor: AppColors.primaryContainer,
                  onChanged: (val) {
                    setState(() {
                      _liveAdjustments = _updateProp(
                        _liveAdjustments,
                        current.$1,
                        val,
                      );
                    });
                    widget.onAdjustmentsLive(_liveAdjustments);
                  },
                  onChangeEnd: (val) {
                    final updated = _updateProp(
                      _liveAdjustments,
                      current.$1,
                      val,
                    );
                    widget.onAdjustmentsCommit(updated);
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(current.$5 * 100).round()}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Fileira de botões para escolher o ajuste
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final p in props)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      p.$2,
                      style: TextStyle(
                        color: _activeAdjustProp == p.$1
                            ? Colors.black
                            : Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    selected: _activeAdjustProp == p.$1,
                    selectedColor: Colors.white,
                    backgroundColor: Colors.white12,
                    shape: const RoundedRectangleBorder(),
                    onSelected: (_) => setState(() => _activeAdjustProp = p.$1),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Adjustments _updateProp(Adjustments base, String prop, double val) {
    return switch (prop) {
      'brightness' => base.copyWith(brightness: val),
      'contrast' => base.copyWith(contrast: val),
      'saturation' => base.copyWith(saturation: val),
      'warmth' => base.copyWith(warmth: val),
      'fade' => base.copyWith(fade: val),
      'vignette' => base.copyWith(vignette: val),
      _ => base,
    };
  }

  String _labelForPreset(String id, AppLocalizations strings) {
    return switch (id) {
      'none' => strings.chatEditorFilterNormal,
      'vivid' => strings.mediaEditorFilterVivid,
      'warm' => strings.mediaEditorFilterWarm,
      'cool' => strings.mediaEditorFilterCool,
      'vintage' => strings.mediaEditorFilterVintage,
      'bw' => strings.mediaEditorFilterBW,
      'drama' => strings.mediaEditorFilterDrama,
      'fade' => strings.mediaEditorFade,
      'sepia' => strings.mediaEditorFilterSepia,
      _ => id,
    };
  }
}

class _HeaderTab extends StatelessWidget {
  const _HeaderTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white54),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
