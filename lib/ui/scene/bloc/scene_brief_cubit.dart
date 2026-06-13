import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/repositories/ask_repository.dart';
import 'package:storypilot/domain/models/ai_usage.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/match_confidence.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/utils/text_utils.dart';

/// Generates the scene "brief" shown automatically when a scene loads:
/// summary + present characters + suggested questions, all in one call.
/// It is free for the user (never consumes the daily quota) and always Lite.
class SceneBriefCubit extends Cubit<SceneBriefState> {
  SceneBriefCubit(this._repository) : super(const SceneBriefInitial());

  final AskRepository _repository;

  Future<void> load(SceneContext context, List<CastMember> cast) async {
    emit(const SceneBriefLoading());
    final result = await _repository.brief(
      context: context,
      cast: cast,
      model: GeminiModel.flashLite25,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          SceneBriefReady(
            summary: data.summary,
            characters: _resolveCharacters(data.presentCharacterNames, cast),
            questions: data.questions,
            usage: data.usage,
          ),
        );
      case Error(:final failure):
        emit(SceneBriefFailure(failure.message));
    }
  }

  /// Maps AI-returned character names back to TMDB cast members so they render
  /// with avatars, exactly like the heuristic chips. Names without a cast match
  /// are dropped — we only show real TMDB characters.
  List<SceneCharacter> _resolveCharacters(
    List<String> names,
    List<CastMember> cast,
  ) {
    final byName = <String, CastMember>{};
    for (final member in cast) {
      byName.putIfAbsent(normalizeText(member.characterName), () => member);
    }
    final seen = <int>{};
    final characters = <SceneCharacter>[];
    for (final name in names) {
      final member = byName[normalizeText(name)];
      if (member == null || !seen.add(member.id)) continue;
      characters.add(
        SceneCharacter(
          castMember: member,
          confidence: MatchConfidence.high,
          matchedBy: 'Detectado por IA',
        ),
      );
    }
    return characters;
  }
}

sealed class SceneBriefState extends Equatable {
  const SceneBriefState();

  @override
  List<Object?> get props => [];
}

final class SceneBriefInitial extends SceneBriefState {
  const SceneBriefInitial();
}

final class SceneBriefLoading extends SceneBriefState {
  const SceneBriefLoading();
}

final class SceneBriefReady extends SceneBriefState {
  const SceneBriefReady({
    required this.summary,
    required this.characters,
    required this.questions,
    this.usage,
  });

  final String summary;
  final List<SceneCharacter> characters;
  final List<String> questions;
  final AiUsage? usage;

  @override
  List<Object?> get props => [summary, characters, questions, usage];
}

final class SceneBriefFailure extends SceneBriefState {
  const SceneBriefFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
