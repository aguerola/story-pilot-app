import 'package:equatable/equatable.dart';

class SubtitleTrack extends Equatable {
  const SubtitleTrack({
    required this.fileId,
    required this.language,
    this.downloadCount,
    required this.format,
  });

  final String fileId;
  final String language;
  final int? downloadCount;
  final String format;

  @override
  List<Object?> get props => [fileId, language, downloadCount, format];
}
