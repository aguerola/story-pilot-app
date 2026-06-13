import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_bloc.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_event.dart';
import 'package:storypilot/ui/title_detail/bloc/title_detail_state.dart';

class TitleDetailScreen extends StatelessWidget {
  const TitleDetailScreen({
    super.key,
    required this.id,
    required this.mediaType,
  });

  final int id;
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TitleDetailBloc>()
        ..add(TitleDetailRequested(id: id, mediaType: mediaType)),
      child: _TitleDetailView(id: id),
    );
  }
}

class _TitleDetailView extends StatelessWidget {
  const _TitleDetailView({required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha')),
      body: BlocBuilder<TitleDetailBloc, TitleDetailState>(
        builder: (context, state) => switch (state) {
          TitleDetailInitial() || TitleDetailLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
          TitleDetailFailure(:final failure) => Center(
              child: Text(failure.message),
            ),
          TitleDetailLoaded(:final detail) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.summary.posterUrl != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          detail.summary.posterUrl!,
                          height: 240,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    detail.summary.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (detail.runtimeMinutes != null)
                    Text('Duración: ${detail.runtimeMinutes} min'),
                  const SizedBox(height: 12),
                  Text(detail.overview),
                  const SizedBox(height: 24),
                  Text(
                    'Reparto',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.cast.take(12).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final member = detail.cast[index];
                        return SizedBox(
                          width: 80,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage: member.profileUrl != null
                                    ? NetworkImage(member.profileUrl!)
                                    : null,
                                child: member.profileUrl == null
                                    ? Text(member.name[0])
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                member.characterName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () =>
                            context.go('/title/$id/subtitles'),
                        icon: const Icon(Icons.subtitles),
                        label: const Text('Subtítulos'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/title/$id/scene'),
                        icon: const Icon(Icons.theaters),
                        label: const Text('Escena'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/title/$id/ask'),
                        icon: const Icon(Icons.chat),
                        label: const Text('Preguntar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }
}
