import 'package:equatable/equatable.dart';

class PersonKnownForCredit extends Equatable {
  const PersonKnownForCredit({
    required this.title,
    this.characterName,
    this.year,
    this.posterUrl,
    required this.mediaType,
  });

  final String title;
  final String? characterName;
  final int? year;
  final String? posterUrl;
  final String mediaType;

  @override
  List<Object?> get props =>
      [title, characterName, year, posterUrl, mediaType];
}

class PersonDetail extends Equatable {
  const PersonDetail({
    required this.id,
    required this.name,
    this.biography,
    this.birthday,
    this.placeOfBirth,
    this.profileUrl,
    this.knownFor = const [],
  });

  final int id;
  final String name;
  final String? biography;
  final String? birthday;
  final String? placeOfBirth;
  final String? profileUrl;
  final List<PersonKnownForCredit> knownFor;

  @override
  List<Object?> get props =>
      [id, name, biography, birthday, placeOfBirth, profileUrl, knownFor];
}
