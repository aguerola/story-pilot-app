import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';

class SubtitleDocument extends Equatable {
  const SubtitleDocument({
    required this.titleId,
    required this.language,
    required this.lines,
    required this.fileId,
  });

  final int titleId;
  final String language;
  final List<SubtitleLine> lines;
  final String fileId;

  Map<String, dynamic> toJson() => {
        'titleId': titleId,
        'language': language,
        'fileId': fileId,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory SubtitleDocument.fromJson(Map<String, dynamic> json) =>
      SubtitleDocument(
        titleId: json['titleId'] as int,
        language: json['language'] as String,
        fileId: json['fileId'] as String? ?? '',
        lines: (json['lines'] as List<dynamic>)
            .map((l) => SubtitleLine.fromJson(l as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [titleId, language, lines, fileId];
}
