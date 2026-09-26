class ColorFilterMatrices {
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
