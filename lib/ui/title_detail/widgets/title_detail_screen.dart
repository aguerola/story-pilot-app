import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_bloc.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_event.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_state.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_actions.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_cast_section.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_crew_section.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_genre_chips.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_hero.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_keywords_section.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_meta_section.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_seasons_section.dart';
import 'package:storypilot/ui/title_detail/widgets/detail_tagline.dart';

class TitleDetailScreen extends StatelessWidget {
  const TitleDetailScreen({
    super.key,
    required this.id,
    required this.mediaType,
  });

  final int id;
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TitleDetailBloc>()
        ..add(TitleDetailRequested(id: id, mediaType: mediaType)),
      child: _TitleDetailView(id: id),
    );
  }
}

class _TitleDetailView extends StatelessWidget {
  const _TitleDetailView({required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: BlocBuilder<TitleDetailBloc, TitleDetailState>(
        builder: (context, state) => switch (state) {
          TitleDetailInitial() || TitleDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          TitleDetailFailure(:final failure) => Center(
              child: Text(failure.message),
            ),
          TitleDetailLoaded(:final detail) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailHero(detail: detail),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (detail.tagline != null)
                          DetailTagline(tagline: detail.tagline!),
                        DetailGenreChips(genres: detail.genres),
                        if (detail.overview.isNotEmpty) ...[
                          Text(
                            'Overview',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(detail.overview),
                          const SizedBox(height: 16),
                        ],
                        DetailMetaSection(detail: detail),
                        DetailCrewSection(crew: detail.crew),
                        DetailCastSection(cast: detail.cast),
                        if (detail.seasons != null)
                          DetailSeasonsSection(seasons: detail.seasons!),
                        DetailKeywordsSection(keywords: detail.keywords),
                        DetailActions(titleId: id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}
