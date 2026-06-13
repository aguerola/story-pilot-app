import 'package:flutter/material.dart';

class DetailGenreChips extends StatelessWidget {
  const DetailGenreChips({super.key, required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: genres
            .map(
              (genre) => Chip(
                label: Text(genre),
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(),
      ),
    );
  }
}
