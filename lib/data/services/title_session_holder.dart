import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/domain/models/subtitle_document.dart';
import 'package:storypilot/domain/models/title_detail.dart';

class TitleSessionHolder {
  TitleDetail? titleDetail;
  SubtitleDocument? subtitleDocument;
  SceneContext? sceneContext;
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

  void clear() {
    titleDetail = null;
    subtitleDocument = null;
    sceneContext = null;
  }

  String titleKey(int id, MediaType type) => '${type.name}_$id';
}
