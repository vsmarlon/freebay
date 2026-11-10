import '../domain/color_math.dart';
import '../domain/crop_geometry.dart';
import '../domain/editor_models.dart';
import '../domain/filter_presets.dart';

class VideoPlan {
  VideoPlan({
    required this.args,
    required this.outW,
    required this.outH,
    required this.outDurationMs,
  });

  final List<String> args;
  final int outW;
  final int outH;
  final int outDurationMs;
}

int _even(num v) {
  final i = v.round();
  return i.isEven ? i : i + 1;
}

String _sec(int ms) => (ms / 1000).toStringAsFixed(3);

VideoPlan buildVideoPlan({
  required EditorState s,
  required String input,
  required String overlayPng,
  required String output,
  required int targetLongEdge,
  required int bitrateK,
  required String vcodecKind, // 'mediacodec'|'videotoolbox'|'libx264'
}) {
  final v = s.video!;
  final g = CropGeometry(s.crop, s.sourceSize);
  final rot = g.rotated;

  // crop em px no espaço rotacionado
  final cw = _even(g.crop.rect.width * rot.width);
  final ch = _even(g.crop.rect.height * rot.height);
  final cx = (g.crop.rect.left * rot.width).round();
  final cy = (g.crop.rect.top * rot.height).round();

  final f = (targetLongEdge / (cw > ch ? cw : ch)).clamp(0.0, 1.0);
  final outW = _even(cw * f);
  final outH = _even(ch * f);

  final vf = <String>[
    if (s.crop.flipH) 'hflip',
    ...switch (s.crop.quarterTurns) {
      1 => ['transpose=1'],
      2 => ['hflip', 'vflip'],
      3 => ['transpose=2'],
      _ => <String>[],
    },
    'crop=$cw:$ch:$cx:$cy',
    'scale=$outW:$outH:flags=bicubic',
    'setsar=1',
    ...adjustmentsToFfmpeg(effectiveAdjustments(s)),
    if (v.speed != 1) 'setpts=PTS/${v.speed}',
  ];

  final fc =
      '[0:v]${vf.join(',')}[b];'
      '[1:v]scale=$outW:$outH[o];'
      '[b][o]overlay=0:0:eof_action=repeat:format=auto[v]';

  List<String> venc() => switch (vcodecKind) {
    'mediacodec' => ['-c:v', 'h264_mediacodec', '-b:v', '${bitrateK}k'],
    'videotoolbox' => [
      '-c:v',
      'h264_videotoolbox',
      '-b:v',
      '${bitrateK}k',
      '-allow_sw',
      '1',
    ],
    _ => ['-c:v', 'libx264', '-preset', 'veryfast', '-crf', '23'],
  };

  String atempo(double sp) {
    final parts = <String>[];
    var r = sp;
    while (r > 2.0) {
      parts.add('atempo=2.0');
      r /= 2.0;
    }
    while (r < 0.5) {
      parts.add('atempo=0.5');
      r /= 0.5;
    }
    parts.add('atempo=${r.toStringAsFixed(3)}');
    return parts.join(',');
  }

  final args = <String>[
    '-y',
    '-ss',
    _sec(v.trimStartMs),
    '-t',
    _sec(v.trimmedMs),
    '-i',
    input,
    '-i',
    overlayPng,
    '-filter_complex',
    fc,
    '-map',
    '[v]',
    if (!v.muted) ...[
      '-map',
      '0:a?',
      if (v.speed != 1) ...['-af', atempo(v.speed)],
      '-c:a',
      'aac',
      '-b:a',
      '128k',
    ],
    if (v.muted) '-an',
    ...venc(),
    '-pix_fmt',
    'yuv420p',
    '-movflags',
    '+faststart',
    output,
  ];

  return VideoPlan(
    args: args,
    outW: outW,
    outH: outH,
    outDurationMs: (v.trimmedMs / v.speed).round(),
  );
}
