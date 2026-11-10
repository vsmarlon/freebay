import 'editor_models.dart';

/// ColorMatrix 4x5 (linha de baixo implícita 0 0 0 0 1). Offsets em 0..255.
const _identity = <double>[
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// out = A(B(x)).
List<double> mulM(List<double> a, List<double> b) {
  final o = List<double>.filled(20, 0);
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 5; c++) {
      var v = 0.0;
      for (var k = 0; k < 4; k++) {
        v += a[r * 5 + k] * b[k * 5 + c];
      }
      if (c == 4) v += a[r * 5 + 4];
      o[r * 5 + c] = v;
    }
  }
  return o;
}

List<double> _contrast(double c) {
  final s = 1 + c * .5, t = 127.5 * (1 - s);
  return [s, 0, 0, 0, t, 0, s, 0, 0, t, 0, 0, s, 0, t, 0, 0, 0, 1, 0];
}

List<double> _brightness(double b) {
  final o = b * .3 * 255;
  return [1, 0, 0, 0, o, 0, 1, 0, 0, o, 0, 0, 1, 0, o, 0, 0, 0, 1, 0];
}

List<double> _saturation(double s) {
  final v = 1 + s;
  const lr = .2126, lg = .7152, lb = .0722;
  return [
    lr * (1 - v) + v, lg * (1 - v), lb * (1 - v), 0, 0, //
    lr * (1 - v), lg * (1 - v) + v, lb * (1 - v), 0, 0, //
    lr * (1 - v), lg * (1 - v), lb * (1 - v) + v, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

List<double> _warmth(double w) {
  final o = w * 25;
  return [
    1 + w * .08,
    0,
    0,
    0,
    o,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1 - w * .08,
    0,
    -o,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _fade(double f) {
  final lift = 30 * f, s = 1 - lift / 255;
  return [s, 0, 0, 0, lift, 0, s, 0, 0, lift, 0, 0, s, 0, lift, 0, 0, 0, 1, 0];
}

/// Ajustes -> uma única ColorMatrix (preview e export de imagem usam a mesma).
List<double> adjustmentsToMatrix(Adjustments a) {
  var m = _identity;
  if (a.contrast != 0) m = mulM(_contrast(a.contrast), m);
  if (a.brightness != 0) m = mulM(_brightness(a.brightness), m);
  if (a.saturation != 0) m = mulM(_saturation(a.saturation), m);
  if (a.warmth != 0) m = mulM(_warmth(a.warmth), m);
  if (a.fade != 0) m = mulM(_fade(a.fade), m);
  return m;
}

/// Parâmetros -> FFmpeg (export de vídeo, seção 12.3 do guia).
List<String> adjustmentsToFfmpeg(Adjustments a) {
  final f = <String>[];
  final eq = <String>[];
  if (a.brightness != 0) {
    eq.add('brightness=${(a.brightness * .3).toStringAsFixed(3)}');
  }
  if (a.contrast != 0) {
    eq.add('contrast=${(1 + a.contrast * .5).toStringAsFixed(3)}');
  }
  if (a.saturation != 0) {
    eq.add('saturation=${(1 + a.saturation).clamp(0, 3).toStringAsFixed(3)}');
  }
  if (eq.isNotEmpty) f.add('eq=${eq.join(':')}');
  if (a.warmth != 0) {
    final w = (a.warmth * .12).toStringAsFixed(3);
    f.add('colorbalance=rs=$w:rm=$w:bs=-$w:bm=-$w');
  }
  if (a.fade != 0) {
    final l = (a.fade * 30 / 255).toStringAsFixed(4);
    f.add("curves=all='0/$l 1/1'");
  }
  return f;
}
