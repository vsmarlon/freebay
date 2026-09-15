import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:just_audio/just_audio.dart';

class AudioMessageBubble extends StatefulWidget {
  final String? audioUrl;
  final bool isMe;
  final int? durationMs;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.durationMs,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  bool _loading = false;
  bool _ready = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration? _total;

  @override
  void initState() {
    super.initState();
    final ms = widget.durationMs;
    if (ms != null && ms > 0) _total = Duration(milliseconds: ms);
    _positionSub = _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
  }

  String? get _url {
    final value = widget.audioUrl;
    return value == null || value.isEmpty ? null : mediaUrl(value);
  }

  Future<void> _toggle() async {
    if (_loading) return;
    if (!_ready) {
      final url = _url;
      if (url == null) return;
      setState(() => _loading = true);
      try {
        final response = await HttpClient.instance.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data;
        if (bytes == null) throw const FormatException('Áudio vazio');
        final file = File(
          '${Directory.systemTemp.path}/freebay_audio_${url.hashCode.toUnsigned(32)}.m4a',
        );
        if (!await file.exists()) {
          await file.writeAsBytes(bytes, flush: true);
        }
        await _player.setFilePath(file.path);
        if (!mounted) return;
        setState(() {
          _ready = true;
          _total = _player.duration ?? _total;
        });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted) return;
    if (_playing) {
      await _player.pause();
    } else {
      if (_total != null && _position >= _total!) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
    if (mounted) {
      setState(() {
        _playing = _player.playing;
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _label(Duration d) {
    final s = d.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) return const SizedBox.shrink();

    final total = _total;
    final progress = total != null && total.inMilliseconds > 0
        ? (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240, minWidth: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isMe ? context.surfaceHighColor : context.surfaceColor,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrutalistIconButton(
              icon: _loading
                  ? Icons.downloading
                  : _playing
                  ? Icons.pause
                  : Icons.play_arrow,
              onTap: _toggle,
              iconColor: AppColors.primaryContainer,
              borderColor: context.borderColor,
            ),
            Spacing.hSm,
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.textSecondary.withAlpha(60),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total == null
                        ? '--:--'
                        : '${_label(_position)} / ${_label(total)}',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
