enum ConversationMediaFilter {
  image('IMAGE'),
  gif('GIF'),
  video('VIDEO'),
  link('LINK');

  const ConversationMediaFilter(this.wireValue);

  final String wireValue;
}
