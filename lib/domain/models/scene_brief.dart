import 'package:equatable/equatable.dart';

/// Structured "scene brief" produced by the AI in a single call: a short
/// summary, the names of cast members present at the selected moment, and a
/// few scene-specific suggested questions.
class SceneBrief extends Equatable {
  const SceneBrief({
    required this.summary,
    this.presentCharacterNames = const [],
    this.questions = const [],
  });

  final String summary;

  /// Character names the AI judges present in the scene. These should match
  /// TMDB `CastMember.characterName` so they can be resolved back to avatars.
  final List<String> presentCharacterNames;

  /// Scene-specific questions the viewer might want to ask.
  final List<String> questions;

  factory SceneBrief.fromJson(Map<String, dynamic> json) => SceneBrief(
        summary: (json['summary'] as String?)?.trim() ?? '',
        presentCharacterNames: _stringList(json['characters']),
        questions: _stringList(json['questions']),
      );

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [summary, presentCharacterNames, questions];
}
