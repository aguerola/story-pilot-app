import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/title_detail.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';

class TitleSessionHolder {
  TitleDetail? titleDetail;
  SubtitleDocument? subtitleDocument;
  SceneContext? sceneContext;
  TvEpisodeSelection? selectedEpisode;
  List<CastMember> get cast => titleDetail?.cast ?? const [];

  void setTitleDetail(TitleDetail detail) {
    titleDetail = detail;
  }

  void setSubtitleDocument(SubtitleDocument document) {
    subtitleDocument = document;
  }

  void setSceneContext(SceneContext context) {
    sceneContext = context;
  }

  void setSelectedEpisode(TvEpisodeSelection selection) {
    selectedEpisode = selection;
  }

  void clearPlaybackState() {
    subtitleDocument = null;
    sceneContext = null;
  }

  void clear() {
    titleDetail = null;
    subtitleDocument = null;
    sceneContext = null;
    selectedEpisode = null;
  }

  String titleKey(int id, MediaType type) => '${type.name}_$id';
}
