import 'package:equatable/equatable.dart';

class SceneSegment extends Equatable {
  const SceneSegment({
    required this.startMs,
    required this.endMs,
    required this.summary,
    required this.detailedSummary,
    this.characters = const [],
  });

  factory SceneSegment.fromJson(Map<String, dynamic> json) {
    final rawCharacters = json['characters'];
    return SceneSegment(
      startMs: json['startMs'] as int? ?? 0,
      endMs: json['endMs'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      detailedSummary: json['detailedSummary'] as String? ?? '',
      characters: rawCharacters is List
          ? rawCharacters.map((item) => item.toString()).toList()
          : const [],
    );
  }

  final int startMs;
  final int endMs;
  final String summary;
  final String detailedSummary;
  final List<String> characters;

  String get displaySummary {
    final detailed = detailedSummary.trim();
    if (detailed.isNotEmpty) return detailed;
    return summary.trim();
  }

  @override
  List<Object?> get props => [
        startMs,
        endMs,
        summary,
        detailedSummary,
        characters,
      ];
}

class TitleBreakdown extends Equatable {
  const TitleBreakdown({
    required this.durationMs,
    required this.titleLabel,
    required this.scenes,
    required this.analysisVersion,
    required this.generatedAt,
  });

  factory TitleBreakdown.fromPreprocessingJson(Map<String, dynamic> json) {
    final rawScenes = json['scenes'];
    return TitleBreakdown(
      durationMs: json['durationMs'] as int? ?? 0,
      titleLabel: json['titleLabel'] as String? ?? '',
      scenes: rawScenes is List
          ? rawScenes
              .whereType<Map>()
              .map(
                (scene) => SceneSegment.fromJson(Map<String, dynamic>.from(scene)),
              )
              .toList()
          : const [],
      analysisVersion: json['analysisVersion'] as int? ?? 0,
      generatedAt: json['generatedAt'] as int? ?? 0,
    );
  }

  final int durationMs;
  final String titleLabel;
  final List<SceneSegment> scenes;
  final int analysisVersion;
  final int generatedAt;

  bool get hasScenes => scenes.isNotEmpty;

  @override
  List<Object?> get props => [
        durationMs,
        titleLabel,
        scenes,
        analysisVersion,
        generatedAt,
      ];
}
