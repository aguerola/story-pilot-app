import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/title_detail.dart';

class DetailMetaSection extends StatelessWidget {
  const DetailMetaSection({super.key, required this.detail});

  final TitleDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    row.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(child: Text(row.value)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<_MetaRow> _buildRows() {
    final rows = <_MetaRow>[];

    if (detail.runtimeMinutes != null) {
      rows.add(_MetaRow('Runtime', '${detail.runtimeMinutes} min'));
    }
    if (detail.status != null && detail.status!.isNotEmpty) {
      rows.add(_MetaRow('Status', detail.status!));
    }
    if (detail.originalLanguage != null && detail.originalLanguage!.isNotEmpty) {
      rows.add(_MetaRow('Language', detail.originalLanguage!));
    }
    if (detail.spokenLanguages.isNotEmpty) {
      rows.add(_MetaRow('Spoken', detail.spokenLanguages.join(', ')));
    }
    if (detail.countries.isNotEmpty) {
      rows.add(_MetaRow('Country', detail.countries.join(', ')));
    }
    if (detail.releaseDate != null && detail.releaseDate!.isNotEmpty) {
      rows.add(_MetaRow('Release', detail.releaseDate!));
    }
    if (detail.firstAirDate != null && detail.firstAirDate!.isNotEmpty) {
      rows.add(_MetaRow('First aired', detail.firstAirDate!));
    }
    if (detail.lastAirDate != null && detail.lastAirDate!.isNotEmpty) {
      rows.add(_MetaRow('Last aired', detail.lastAirDate!));
    }
    if (detail.budget != null && detail.budget! > 0) {
      rows.add(_MetaRow('Budget', _formatMoney(detail.budget!)));
    }
    if (detail.revenue != null && detail.revenue! > 0) {
      rows.add(_MetaRow('Revenue', _formatMoney(detail.revenue!)));
    }
    if (detail.collectionName != null && detail.collectionName!.isNotEmpty) {
      rows.add(_MetaRow('Collection', detail.collectionName!));
    }
    if (detail.createdBy.isNotEmpty) {
      rows.add(_MetaRow('Created by', detail.createdBy.join(', ')));
    }
    if (detail.networks.isNotEmpty) {
      rows.add(_MetaRow('Networks', detail.networks.join(', ')));
    }
    if (detail.numberOfSeasons != null) {
      rows.add(_MetaRow('Seasons', '${detail.numberOfSeasons}'));
    }
    if (detail.numberOfEpisodes != null) {
      rows.add(_MetaRow('Episodes', '${detail.numberOfEpisodes}'));
    }
    if (detail.inProduction == true) {
      rows.add(_MetaRow('In production', 'Yes'));
    }
    if (detail.originalTitle != null &&
        detail.originalTitle!.isNotEmpty &&
        detail.originalTitle != detail.summary.title) {
      rows.add(_MetaRow('Original title', detail.originalTitle!));
    }
    if (detail.imdbId != null && detail.imdbId!.isNotEmpty) {
      rows.add(_MetaRow('IMDb', detail.imdbId!));
    }

    return rows;
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '\$$amount';
  }
}

class _MetaRow {
  const _MetaRow(this.label, this.value);

  final String label;
  final String value;
}
