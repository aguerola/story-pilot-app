import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/ui/subtitles/bloc/subtitle_bloc.dart';
import 'package:storypilot/ui/subtitles/bloc/subtitle_event.dart';
import 'package:storypilot/ui/subtitles/bloc/subtitle_state.dart';

class SubtitlesScreen extends StatelessWidget {
  const SubtitlesScreen({
    super.key,
    required this.id,
    required this.mediaType,
  });

  final int id;
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    final sessionType =
        getIt<TitleSessionHolder>().titleDetail?.summary.mediaType ??
            mediaType;
    return BlocProvider(
      create: (_) => getIt<SubtitleBloc>()
        ..add(
          SubtitleTracksRequested(tmdbId: id, mediaType: sessionType),
        ),
      child: _SubtitlesView(id: id),
    );
  }
}

class _SubtitlesView extends StatelessWidget {
  const _SubtitlesView({required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subtítulos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<SubtitleBloc, SubtitleState>(
              buildWhen: (prev, curr) =>
                  curr is SubtitleTracksLoaded ||
                  curr is SubtitleInitial ||
                  curr is SubtitleLoading,
              builder: (context, state) {
                final language = state is SubtitleTracksLoaded
                    ? state.language
                    : 'es';
                return Row(
                  children: [
                    const Text('Idioma:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: language,
                      items: const [
                        DropdownMenuItem(value: 'es', child: Text('ES')),
                        DropdownMenuItem(value: 'en', child: Text('EN')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          context
                              .read<SubtitleBloc>()
                              .add(SubtitleLanguageChanged(value));
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocConsumer<SubtitleBloc, SubtitleState>(
                listener: (context, state) {
                  if (state is SubtitleDownloaded) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Subtítulo descargado'),
                      ),
                    );
                  }
                },
                builder: (context, state) => switch (state) {
                  SubtitleInitial() || SubtitleLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  SubtitleFailure(:final failure) =>
                    Center(child: Text(failure.message)),
                  SubtitleDownloading(:final track) => Center(
                      child: Text('Descargando ${track.language}...'),
                    ),
                  SubtitleDownloaded(:final document) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${document.lines.length} líneas cargadas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go('/title/$id/scene'),
                          child: const Text('Ir a escena'),
                        ),
                      ],
                    ),
                  SubtitleTracksLoaded(:final tracks) => tracks.isEmpty
                      ? const Center(
                          child: Text('No hay subtítulos disponibles'),
                        )
                      : ListView.separated(
                          itemCount: tracks.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            return ListTile(
                              title: Text(
                                '${track.language.toUpperCase()} · ${track.format}',
                              ),
                              subtitle: Text(
                                'Descargas: ${track.downloadCount ?? '-'}',
                              ),
                              trailing: const Icon(Icons.download),
                              onTap: () => context.read<SubtitleBloc>().add(
                                    SubtitleDownloadRequested(
                                      tmdbId: id,
                                      track: track,
                                    ),
                                  ),
                            );
                          },
                        ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
