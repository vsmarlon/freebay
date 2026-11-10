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
  final String? viewOnceOpeningKey;
  final VoidCallback? onViewOnceClose;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.durationMs,
    this.viewOnceOpeningKey,
    this.onViewOnceClose,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _loading = false;
  bool _ready = false;
  bool _playing = false;
  File? _viewOnceTemporaryFile;
  Duration _position = Duration.zero;
  Duration? _total;
  double? _dragPositionMs;

  @override
  void initState() {
    super.initState();
    final ms = widget.durationMs;
    if (ms != null && ms > 0) _total = Duration(milliseconds: ms);
    _positionSub = _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(
          () => _playing =
              state.playing &&
              state.processingState != ProcessingState.completed,
        );
      }
      if (state.processingState == ProcessingState.completed) {
        if (widget.viewOnceOpeningKey != null) {
          widget.onViewOnceClose?.call();
        }
      }
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
          options: Options(
            responseType: ResponseType.bytes,
            headers: mediaAuthHeaders(
              url,
              viewOnceOpeningKey: widget.viewOnceOpeningKey,
            ),
          ),
        );
        final bytes = response.data;
        if (bytes == null) throw const FormatException('Áudio vazio');
        final isViewOnce = widget.viewOnceOpeningKey != null;
        final file = File(
          '${Directory.systemTemp.path}/freebay_audio_${isViewOnce ? DateTime.now().microsecondsSinceEpoch : url.hashCode.toUnsigned(32)}.m4a',
        );
        if (isViewOnce || !await file.exists()) {
          await file.writeAsBytes(bytes, flush: true);
        }
        if (isViewOnce) _viewOnceTemporaryFile = file;
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
      unawaited(
        _player.play().then<void>(
          (_) {},
          onError: (Object _) {
            if (mounted) setState(() => _playing = false);
          },
        ),
      );
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
    _playerStateSub?.cancel();
    _player.dispose();
    final viewOnceFile = _viewOnceTemporaryFile;
    if (viewOnceFile != null) {
      unawaited(
        viewOnceFile.delete().then<void>((_) {}, onError: (Object _) {}),
      );
    }
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
    final totalMs = total?.inMilliseconds ?? 0;
    final positionMs = (_dragPositionMs ?? _position.inMilliseconds.toDouble())
        .clamp(0.0, totalMs.toDouble());

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
              semanticLabel: _loading
                  ? 'Baixando áudio'
                  : _playing
                  ? 'Pausar áudio'
                  : 'Reproduzir áudio',
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
                  Slider(
                    value: positionMs,
                    max: totalMs > 0 ? totalMs.toDouble() : 1,
                    semanticFormatterCallback: (value) =>
                        '${_label(Duration(milliseconds: value.round()))} / ${_label(total ?? Duration.zero)}',
                    onChanged: _ready && totalMs > 0
                        ? (value) => setState(() => _dragPositionMs = value)
                        : null,
                    onChangeEnd: (value) {
                      setState(() {
                        _position = Duration(milliseconds: value.round());
                        _dragPositionMs = null;
                      });
                      unawaited(_player.seek(_position));
                    },
                  ),
                  Text(
                    total == null
                        ? '--:--'
                        : '${_label(Duration(milliseconds: positionMs.round()))} / ${_label(total)}',
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
