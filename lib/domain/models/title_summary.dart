import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/media_type.dart';

class TitleSummary extends Equatable {
  const TitleSummary({
    required this.id,
    required this.mediaType,
    required this.title,
    this.year,
    this.posterUrl,
  });

  final int id;
  final MediaType mediaType;
  final String title;
  final int? year;
  final String? posterUrl;

  String get displayLabel =>
      year != null ? '$title ($year)' : title;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaType': mediaType.name,
        'title': title,
        'year': year,
        'posterUrl': posterUrl,
      };

  factory TitleSummary.fromJson(Map<String, dynamic> json) => TitleSummary(
        id: json['id'] as int,
        mediaType: MediaType.fromTmdb(json['mediaType'] as String),
        title: json['title'] as String,
        year: json['year'] as int?,
        posterUrl: json['posterUrl'] as String?,
      );

  @override
  List<Object?> get props => [id, mediaType, title, year, posterUrl];
}
