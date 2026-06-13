import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/season.dart';

class SeasonEpisodeSelector extends StatelessWidget {
  const SeasonEpisodeSelector({
    super.key,
    required this.seasons,
    required this.selectedSeason,
    required this.selectedEpisode,
    required this.onChanged,
  });

  final List<Season> seasons;
  final int selectedSeason;
  final int selectedEpisode;
  final void Function(int seasonNumber, int episodeNumber) onChanged;

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentSeason = seasons.firstWhere(
      (season) => season.seasonNumber == selectedSeason,
      orElse: () => seasons.first,
    );
    final episodeCount = currentSeason.episodeCount;
    final safeEpisode = episodeCount == 0
        ? 1
        : selectedEpisode.clamp(1, episodeCount);

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: currentSeason.seasonNumber,
            decoration: const InputDecoration(
              labelText: 'Temporada',
            ),
            items: seasons
                .map(
                  (season) => DropdownMenuItem(
                    value: season.seasonNumber,
                    child: Text(
                      season.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
              onChanged: (seasonNumber) {
              if (seasonNumber == null) return;
              onChanged(seasonNumber, 1);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            initialValue: safeEpisode,
            decoration: const InputDecoration(
              labelText: 'Capítulo',
            ),
            items: episodeCount == 0
                ? const [
                    DropdownMenuItem(value: 1, child: Text('Cap. 1')),
                  ]
                : List.generate(
                    episodeCount,
                    (index) {
                      final number = index + 1;
                      return DropdownMenuItem(
                        value: number,
                        child: Text('Cap. $number'),
                      );
                    },
                  ),
            onChanged: episodeCount == 0
                ? null
                : (episodeNumber) {
                    if (episodeNumber == null) return;
                    onChanged(currentSeason.seasonNumber, episodeNumber);
                  },
          ),
        ),
      ],
    );
  }
}
