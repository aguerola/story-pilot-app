import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/ai_usage.dart';

/// Shows token usage + estimated cost for an AI call. Renders nothing outside
/// debug builds, so end users never see it.
class DebugUsage extends StatelessWidget {
  const DebugUsage(this.usage, {super.key});

  final AiUsage? usage;

  @override
  Widget build(BuildContext context) {
    final usage = this.usage;
    if (!kDebugMode || usage == null || !usage.hasDebugInfo) {
      return const SizedBox.shrink();
    }
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (usage.contextLabel != null) ...[
          Text(usage.contextLabel!, style: style),
          const SizedBox(height: 4),
        ],
        if (usage.hasTokens) ...[
          Text('Tokens: ${usage.tokenLabel}', style: style),
          if (usage.costLabel != null) ...[
            const SizedBox(height: 4),
            Text('Coste estimado: ${usage.costLabel}', style: style),
          ],
        ],
      ],
    );
  }
}
