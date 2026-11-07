class ColorFilterMatrices {
  static List<double> combine(List<List<double>> matrices) {
    var result = _identity();
    for (final next in matrices) {
      final combined = List<double>.filled(20, 0);
      for (var row = 0; row < 4; row++) {
        for (var column = 0; column < 4; column++) {
          for (var k = 0; k < 4; k++) {
            combined[row * 5 + column] +=
                next[row * 5 + k] * result[k * 5 + column];
          }
        }
        combined[row * 5 + 4] = next[row * 5 + 4];
        for (var k = 0; k < 4; k++) {
          combined[row * 5 + 4] += next[row * 5 + k] * result[k * 5 + 4];
        }
      }
      result = combined;
    }
    return result;
  }

  static List<double> warmth(double value) => [
    1,
    0,
    0,
    0,
    value * 30,
    0,
    1,
    0,
    0,
    value * 5,
    0,
    0,
    1,
    0,
    -value * 30,
    0,
    0,
    0,
    1,
    0,
  ];

  static List<double> brightness(double value) {
    if (value == 0) return _identity();
    final v = value * 255;
    return [1, 0, 0, 0, v, 0, 1, 0, 0, v, 0, 0, 1, 0, v, 0, 0, 0, 1, 0];
  }

  static List<double> contrast(double value) {
    if (value == 1) return _identity();
    final v = value;
    final o = 128 * (1 - v);
    return [v, 0, 0, 0, o, 0, v, 0, 0, o, 0, 0, v, 0, o, 0, 0, 0, 1, 0];
  }

  static List<double> saturation(double value) {
    if (value == 1) return _identity();
    final invSat = 1 - value;
    final r = 0.213 * invSat;
    final g = 0.715 * invSat;
    final b = 0.072 * invSat;
    return [
      r + value,
      g,
      b,
      0,
      0,
      r,
      g + value,
      b,
      0,
      0,
      r,
      g,
      b + value,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> _identity() {
    return [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  }

  // Predefined Filters
  static const List<double> normal = [
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

  static const List<double> clarendon = [
    1.2,
    0,
    0,
    0,
    10,
    0,
    1.2,
    0,
    0,
    20,
    0,
    0,
    1.2,
    0,
    30,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> gingham = [
    0.8,
    0,
    0,
    0,
    20,
    0,
    0.8,
    0,
    0,
    10,
    0,
    0,
    0.8,
    0,
    5,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> moon = [
    // Grayscale + Contrast
    1.2, 1.2, 1.2, 0, -20,
    1.2, 1.2, 1.2, 0, -20,
    1.2, 1.2, 1.2, 0, -20,
    0, 0, 0, 1, 0,
  ];

  static const List<double> lark = [
    1.0,
    0.1,
    0.1,
    0,
    5,
    0.1,
    1.1,
    0.1,
    0,
    10,
    0.1,
    0.1,
    1.2,
    0,
    15,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> reyes = [
    1.1,
    0,
    0,
    0,
    20,
    0,
    1.1,
    0,
    0,
    30,
    0,
    0,
    0.9,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> juno = [
    1.2,
    0.1,
    0,
    0,
    15,
    0,
    1.1,
    0,
    0,
    5,
    0,
    0,
    0.9,
    0,
    -5,
    0,
    0,
    0,
    1,
    0,
  ];
}
