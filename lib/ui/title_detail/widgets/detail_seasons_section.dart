import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/domain/models/episode.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/result.dart';
import 'package:storypilot/data/services/title_session_holder.dart';

class DetailSeasonsSection extends StatelessWidget {
  const DetailSeasonsSection({
    super.key,
    required this.titleId,
    required this.seasons,
  });

  final int titleId;
  final List<Season> seasons;

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temporadas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...seasons.map(
          (season) => _SeasonExpansionTile(
            titleId: titleId,
            season: season,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SeasonExpansionTile extends StatefulWidget {
  const _SeasonExpansionTile({
    required this.titleId,
    required this.season,
  });

  final int titleId;
  final Season season;

  @override
  State<_SeasonExpansionTile> createState() => _SeasonExpansionTileState();
}

class _SeasonExpansionTileState extends State<_SeasonExpansionTile> {
  List<Episode>? _episodes;
  bool _loading = false;
  String? _error;

  Future<void> _loadEpisodes() async {
    if (_episodes != null || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await getIt<TitleRepository>().getSeasonEpisodes(
      widget.titleId,
      widget.season.seasonNumber,
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _episodes = data;
          _loading = false;
        });
      case Error(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  void _openScene(int episodeNumber) {
    getIt<TitleSessionHolder>().setSelectedEpisode(
      TvEpisodeSelection(
        seasonNumber: widget.season.seasonNumber,
        episodeNumber: episodeNumber,
      ),
    );
    context.push('/title/${widget.titleId}/scene?type=tv');
  }

  @override
  Widget build(BuildContext context) {
    final season = widget.season;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) _loadEpisodes();
        },
        leading: season.posterUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  season.posterUrl!,
                  width: 40,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.tv, size: 40),
                ),
              )
            : const Icon(Icons.tv, size: 40),
        title: Text(season.name),
        subtitle: Text(
          [
            '${season.episodeCount} capítulos',
            if (season.airDate != null && season.airDate!.isNotEmpty)
              season.airDate!,
          ].join(' · '),
        ),
        children: [
          if (season.overview != null && season.overview!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(season.overview!),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else if (_episodes != null)
            ..._episodes!.map((episode) => _EpisodeTile(
                  episode: episode,
                  onTap: () => _openScene(episode.episodeNumber),
                )),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.onTap,
  });

  final Episode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metaParts = <String>[
      if (episode.airDate != null && episode.airDate!.isNotEmpty)
        episode.airDate!,
      if (episode.runtimeMinutes != null && episode.runtimeMinutes! > 0)
        '${episode.runtimeMinutes} min',
    ];

    return ListTile(
      onTap: onTap,
      leading: episode.stillUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                episode.stillUrl!,
                width: 56,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 56,
                  height: 32,
                  child: Icon(Icons.movie, size: 24),
                ),
              ),
            )
          : SizedBox(
              width: 56,
              child: Text(
                '${episode.episodeNumber}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
      title: Text(
        '${episode.episodeNumber}. ${episode.name}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: metaParts.isEmpty
          ? null
          : Text(metaParts.join(' · ')),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
