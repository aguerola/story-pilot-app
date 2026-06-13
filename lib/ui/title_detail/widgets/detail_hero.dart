import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/title_detail.dart';

class DetailHero extends StatelessWidget {
  const DetailHero({super.key, required this.detail});

  final TitleDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = detail.summary;
    final yearSuffix = summary.year != null ? ' (${summary.year})' : '';

    return SizedBox(
      height: detail.backdropUrl != null ? 220 : 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (detail.backdropUrl != null)
            Image.network(
              detail.backdropUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          if (detail.backdropUrl != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (summary.posterUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      summary.posterUrl!,
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 100,
                        height: 150,
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${summary.title}$yearSuffix',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: detail.backdropUrl != null
                              ? Colors.white
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (detail.rating != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 18,
                              color: detail.backdropUrl != null
                                  ? Colors.amber
                                  : Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              detail.rating!.toStringAsFixed(1),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: detail.backdropUrl != null
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                            if (detail.voteCount != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${_formatVoteCount(detail.voteCount!)})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: detail.backdropUrl != null
                                      ? Colors.white70
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatVoteCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k votes';
    }
    return '$count votes';
  }
}
