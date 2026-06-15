import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storypilot/domain/models/media_type.dart';

class DetailActions extends StatelessWidget {
  const DetailActions({
    super.key,
    required this.titleId,
    required this.mediaType,
  });

  final int titleId;
  final MediaType mediaType;

  void _openScene(BuildContext context) {
    context.push('/title/$titleId/scene?type=${mediaType.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _openScene(context),
          icon: const Icon(Icons.theaters),
          label: const Text('Ver qué pasa en una escena'),
        ),
      ],
    );
  }
}
