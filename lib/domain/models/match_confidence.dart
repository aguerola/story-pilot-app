enum MatchConfidence {
  high,
  medium,
  low;

  String get label => switch (this) {
        MatchConfidence.high => 'Alta',
        MatchConfidence.medium => 'Media',
        MatchConfidence.low => 'Baja',
      };
}
