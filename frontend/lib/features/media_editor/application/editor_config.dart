/// Feature flags por ponto de entrada (guia seção 17 / matriz 1.3).
class EditorConfig {
  const EditorConfig({
    this.crop = true,
    this.aspects = const [null, 1, 4 / 5, 16 / 9, 9 / 16],
    this.text = true,
    this.draw = true,
    this.stickers = true,
    this.blur = false,
    this.filters = true,
    this.adjust = true,
    this.caption = true,
    this.hdToggle = true,
    this.viewOnce = false,
    this.multiMax = 10,
    this.forceAspect,
    this.circularPreview = false,
  });
  final bool crop,
      text,
      draw,
      stickers,
      blur,
      filters,
      adjust,
      caption,
      hdToggle,
      viewOnce,
      circularPreview;
  final List<double?> aspects;
  final int multiMax;
  final double? forceAspect;

  /// Chat/DM: tudo liberado, view once.
  static const chat = EditorConfig(viewOnce: true, blur: true);

  /// Post/feed: sem crop livre; 1:1 / 4:5 / 16:9.
  static const post = EditorConfig(aspects: [1, 4 / 5, 16 / 9]);

  /// Story: 9:16 travado. Caption continua ligada porque o fluxo de story
  /// deste app lê a legenda do editor (cria_story_page).
  static const story = EditorConfig(
    aspects: [],
    forceAspect: 9 / 16,
    multiMax: 1,
  );

  /// Avatar: só crop 1:1 (preview circular; export quadrado).
  static const avatar = EditorConfig(
    text: false,
    draw: false,
    stickers: false,
    filters: false,
    adjust: false,
    aspects: [],
    forceAspect: 1,
    caption: false,
    multiMax: 1,
    circularPreview: true,
  );

  /// Anúncio: sem texto/desenho; stickers de preço/vendido; blur liberado.
  static const listing = EditorConfig(
    text: false,
    draw: false,
    aspects: [1, 4 / 5],
    caption: false,
    blur: true,
  );
}
