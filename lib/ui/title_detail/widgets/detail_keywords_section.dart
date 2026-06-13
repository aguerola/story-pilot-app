import 'package:flutter/material.dart';

class DetailKeywordsSection extends StatelessWidget {
  const DetailKeywordsSection({super.key, required this.keywords});

  final List<String> keywords;

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keywords',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords
              .map(
                (keyword) => ActionChip(
                  label: Text(keyword),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {},
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
