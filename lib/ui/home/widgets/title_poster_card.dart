import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/title_summary.dart';

class TitlePosterCard extends StatelessWidget {
  const TitlePosterCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  final TitleSummary title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: title.posterUrl != null
                  ? Image.network(
                      title.posterUrl!,
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(height: 6),
            Text(
              title.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (title.year != null)
              Text(
                '${title.year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 100,
      height: 150,
      color: Colors.grey.shade300,
      child: const Icon(Icons.movie, size: 32),
    );
  }
}
