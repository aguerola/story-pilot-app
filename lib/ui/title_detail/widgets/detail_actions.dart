import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/ui/scene/widgets/season_episode_selector.dart';

class DetailActions extends StatefulWidget {
  const DetailActions({
    super.key,
    required this.titleId,
    required this.mediaType,
    this.seasons = const [],
  });

  final int titleId;
  final MediaType mediaType;
  final List<Season> seasons;

  @override
  State<DetailActions> createState() => _DetailActionsState();
}

class _DetailActionsState extends State<DetailActions> {
  int? _selectedSeason;
  int? _selectedEpisode;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == MediaType.tv && widget.seasons.isNotEmpty) {
      final sessionEpisode = getIt<TitleSessionHolder>().selectedEpisode;
      _selectedSeason =
          sessionEpisode?.seasonNumber ?? widget.seasons.first.seasonNumber;
      _selectedEpisode = sessionEpisode?.episodeNumber ?? 1;
    }
  }

  void _onEpisodeChanged(int seasonNumber, int episodeNumber) {
    setState(() {
      _selectedSeason = seasonNumber;
      _selectedEpisode = episodeNumber;
    });
    getIt<TitleSessionHolder>().setSelectedEpisode(
      TvEpisodeSelection(
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      ),
    );
  }

  void _openScene() {
    if (widget.mediaType == MediaType.tv &&
        widget.seasons.isNotEmpty &&
        _selectedSeason != null &&
        _selectedEpisode != null) {
      getIt<TitleSessionHolder>().setSelectedEpisode(
        TvEpisodeSelection(
          seasonNumber: _selectedSeason!,
          episodeNumber: _selectedEpisode!,
        ),
      );
    }
    context.go('/title/${widget.titleId}/scene');
  }

  @override
  Widget build(BuildContext context) {
    final showEpisodeSelector = widget.mediaType == MediaType.tv &&
        widget.seasons.isNotEmpty &&
        _selectedSeason != null &&
        _selectedEpisode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showEpisodeSelector) ...[
          SeasonEpisodeSelector(
            seasons: widget.seasons,
            selectedSeason: _selectedSeason!,
            selectedEpisode: _selectedEpisode!,
            onChanged: _onEpisodeChanged,
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _openScene,
              icon: const Icon(Icons.theaters),
              label: const Text('Ver qué pasa en una escena'),
            ),
          ],
        ),
      ],
    );
  }
}
