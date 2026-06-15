import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';

class TitleSessionHolder {
  TitleDetail? titleDetail;
  SceneContext? sceneContext;
  TvEpisodeSelection? selectedEpisode;
  int? durationMs;

  List<CastMember> get cast => titleDetail?.cast ?? const [];

  void setTitleDetail(TitleDetail detail) {
    titleDetail = detail;
    if (detail.summary.mediaType == MediaType.movie) {
      selectedEpisode = null;
    }
  }

  void setSceneContext(SceneContext context) {
    sceneContext = context;
  }

  void setSelectedEpisode(TvEpisodeSelection selection) {
    selectedEpisode = selection;
  }

  void setDurationMs(int value) {
    durationMs = value;
  }

  void clearPlaybackState() {
    durationMs = null;
    sceneContext = null;
  }

  void clear() {
    titleDetail = null;
    sceneContext = null;
    selectedEpisode = null;
    durationMs = null;
  }

  String titleKey(int id, MediaType type) => '${type.name}_$id';
}
