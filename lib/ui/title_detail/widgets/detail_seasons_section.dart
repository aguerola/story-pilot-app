import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/season.dart';

class DetailSeasonsSection extends StatelessWidget {
  const DetailSeasonsSection({super.key, required this.seasons});

  final List<Season> seasons;

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seasons',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...seasons.map(
          (season) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              leading: season.posterUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        season.posterUrl!,
                        width: 40,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.tv, size: 40),
                      ),
                    )
                  : const Icon(Icons.tv, size: 40),
              title: Text(season.name),
              subtitle: Text(
                [
                  '${season.episodeCount} episodes',
                  if (season.airDate != null && season.airDate!.isNotEmpty)
                    season.airDate!,
                ].join(' · '),
              ),
              children: [
                if (season.overview != null && season.overview!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(season.overview!),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
