import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/models/media_type.dart';

sealed class TitleDetailEvent extends Equatable {
  const TitleDetailEvent();

  @override
  List<Object?> get props => [];
}

final class TitleDetailRequested extends TitleDetailEvent {
  const TitleDetailRequested({required this.id, required this.mediaType});

  final int id;
  final MediaType mediaType;

  @override
  List<Object?> get props => [id, mediaType];
}
