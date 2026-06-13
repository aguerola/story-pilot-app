enum MediaType {
  movie,
  tv;

  String get tmdbValue => name;

  static MediaType fromTmdb(String value) {
    return switch (value) {
      'movie' => MediaType.movie,
      'tv' => MediaType.tv,
      _ => MediaType.movie,
    };
  }
}
