enum PostSearchFilter {
  all('all'),
  following('following'),
  followers('followers');

  const PostSearchFilter(this.wireValue);

  final String wireValue;
}

enum FeedType {
  explore('explore'),
  following('following');

  const FeedType(this.wireValue);

  final String wireValue;
}

enum FeedContentFilter {
  all('all'),
  socialOnly('social'),
  sellingOnly('selling');

  const FeedContentFilter(this.apiValue);

  final String apiValue;
}
