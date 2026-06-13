import 'package:equatable/equatable.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/title_detail.dart';

sealed class TitleDetailState extends Equatable {
  const TitleDetailState();

  @override
  List<Object?> get props => [];
}

final class TitleDetailInitial extends TitleDetailState {
  const TitleDetailInitial();
}

final class TitleDetailLoading extends TitleDetailState {
  const TitleDetailLoading();
}

final class TitleDetailLoaded extends TitleDetailState {
  const TitleDetailLoaded(this.detail);

  final TitleDetail detail;

  @override
  List<Object?> get props => [detail];
}

final class TitleDetailFailure extends TitleDetailState {
  const TitleDetailFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
