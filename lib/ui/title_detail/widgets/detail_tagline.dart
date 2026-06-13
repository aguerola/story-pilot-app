import 'package:flutter/material.dart';

class DetailTagline extends StatelessWidget {
  const DetailTagline({super.key, required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    if (tagline.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        tagline,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
