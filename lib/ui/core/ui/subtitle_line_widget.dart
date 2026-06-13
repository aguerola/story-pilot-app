import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';

class SubtitleLineWidget extends StatelessWidget {
  const SubtitleLineWidget({
    super.key,
    required this.line,
    this.highlighted = false,
  });

  final SubtitleLine line;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        line.text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
            ),
      ),
    );
  }
}
