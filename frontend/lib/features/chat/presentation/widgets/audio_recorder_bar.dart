import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:record/record.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class AudioRecording {
  final File file;
  final Duration duration;

  const AudioRecording({required this.file, required this.duration});
}

const maxAudioDuration = Duration(seconds: 60);

class AudioRecorderBar extends StatefulWidget {
  final ValueChanged<AudioRecording> onSend;
  final VoidCallback onCancel;

  const AudioRecorderBar({
    super.key,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<AudioRecorderBar> createState() => _AudioRecorderBarState();
}

class _AudioRecorderBarState extends State<AudioRecorderBar> {
  final _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _ticker;
  final _levels = <double>[];
  Duration _elapsed = Duration.zero;
  bool _starting = true;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final hasPermission = await _recorder.hasPermission();
    if (!mounted) return;
    if (!hasPermission) {
      widget.onCancel();
      return;
    }
    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}freebay_audio_${DateTime.now().microsecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(const RecordConfig(), path: path);
    } catch (_) {
      if (mounted) widget.onCancel();
      return;
    }
    if (!mounted) return;
    setState(() => _starting = false);
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((amp) {
          if (!mounted) return;
          setState(() {
            final level = ((amp.current + 50) / 50).clamp(0.08, 1.0);
            _levels.add(level);
            if (_levels.length > 48) _levels.removeAt(0);
          });
        });
    final startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed >= maxAudioDuration) {
        _finish(send: true);
        return;
      }
      setState(() => _elapsed = elapsed);
    });
  }

  Future<void> _finish({required bool send}) async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.cancel();
    await _ampSub?.cancel();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }
    if (!mounted) return;
    final tooShort = _elapsed < const Duration(milliseconds: 700);
    if (send && path != null && !tooShort) {
      widget.onSend(AudioRecording(file: File(path), duration: _elapsed));
    } else {
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      widget.onCancel();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String get _timerLabel {
    final s = _elapsed.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 2)),
      ),
      child: Row(
        children: [
          BrutalistIconButton(
            icon: Icons.close,
            semanticLabel: l10n(context).chatCancelRecording,
            onTap: () => _finish(send: false),
            size: 48,
            iconSize: 24,
            iconColor: context.textPrimary,
            borderColor: context.borderColor,
          ),
          Spacing.hSm,
          Container(width: 12, height: 12, color: AppColors.error),
          Spacing.hSm,
          Text(
            _starting ? '--:--' : _timerLabel,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          Spacing.hSm,
          Expanded(
            child: SizedBox(
              height: 40,
              child: CustomPaint(
                painter: _WaveformPainter(
                  levels: List.of(_levels),
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ),
          Spacing.hSm,
          BrutalistIconButton(
            icon: Icons.send,
            semanticLabel: l10n(context).chatSendAudio,
            onTap: () => _finish(send: true),
            size: 48,
            iconSize: 24,
            iconColor: AppColors.onPrimary,
            borderColor: AppColors.primaryContainer,
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> levels;
  final Color color;

  const _WaveformPainter({required this.levels, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final paint = Paint()..color = color;
    const barWidth = 3.0;
    const gap = 2.0;
    final maxBars = (size.width / (barWidth + gap)).floor();
    final visible = levels.length > maxBars
        ? levels.sublist(levels.length - maxBars)
        : levels;
    var dx = size.width - visible.length * (barWidth + gap);
    for (final level in visible) {
      final barHeight = math.max(4.0, level * size.height);
      final dy = (size.height - barHeight) / 2;
      canvas.drawRect(Rect.fromLTWH(dx, dy, barWidth, barHeight), paint);
      dx += barWidth + gap;
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.levels != levels;
}
