import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetailActions extends StatelessWidget {
  const DetailActions({super.key, required this.titleId});

  final int titleId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => context.go('/title/$titleId/scene'),
          icon: const Icon(Icons.theaters),
          label: const Text('Scene'),
        ),
      ],
    );
  }
}
