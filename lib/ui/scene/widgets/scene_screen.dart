import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/models/ai_usage.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/core/ui/character_chip.dart';
import 'package:storypilot/ui/core/ui/story_pilot_app_bar.dart';
import 'package:storypilot/ui/core/ui/debug_usage.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';
import 'package:storypilot/domain/models/media_type.dart';
import 'package:storypilot/domain/models/tv_episode_selection.dart';
import 'package:storypilot/domain/models/season.dart';
import 'package:storypilot/ui/scene/widgets/scene_ask_panel.dart';
import 'package:storypilot/ui/scene/widgets/season_episode_selector.dart';
import 'package:storypilot/utils/timestamp_utils.dart';

class SceneScreen extends StatelessWidget {
  const SceneScreen({
    super.key,
    required this.id,
    required this.mediaType,
  });

  final int id;
  final MediaType mediaType;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<SceneBloc>(),
        ),
        BlocProvider(create: (_) => getIt<AskBloc>()),
      ],
      child: _SceneView(id: id, mediaType: mediaType),
    );
  }
}

class _SceneView extends StatefulWidget {
  const _SceneView({
    required this.id,
    required this.mediaType,
  });

  final int id;
  final MediaType mediaType;

  @override
  State<_SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<_SceneView> {
  final _timeController = TextEditingController(text: '00:00:00');
  double _sliderValue = 0;
  double _maxMs = 7200000;
  late final bool _isTv;
  List<Season> _seasons = const [];
  int? _selectedSeason;
  int? _selectedEpisode;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final session = getIt<TitleSessionHolder>();
    final sessionDetail = session.titleDetail;
    final detailMatchesId =
        sessionDetail != null && sessionDetail.summary.id == widget.id;
    final effectiveMediaType = detailMatchesId
        ? sessionDetail.summary.mediaType
        : widget.mediaType;
    _isTv = effectiveMediaType == MediaType.tv;
    _seasons =
        detailMatchesId ? (sessionDetail.seasons ?? const []) : const [];
    final sessionEpisode = session.selectedEpisode;
    if (_isTv && _seasons.isNotEmpty) {
      _selectedSeason =
          sessionEpisode?.seasonNumber ?? _seasons.first.seasonNumber;
      _selectedEpisode = sessionEpisode?.episodeNumber ?? 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScene());
  }

  void _startScene() {
    if (_started) return;
    _started = true;
    final session = getIt<TitleSessionHolder>();
    final sessionDetail = session.titleDetail;
    final detailMatchesId =
        sessionDetail != null && sessionDetail.summary.id == widget.id;
    final mediaType = detailMatchesId
        ? sessionDetail.summary.mediaType
        : widget.mediaType;
    if (mediaType == MediaType.tv) {
      if (_selectedSeason == null || _selectedEpisode == null) return;
      context.read<SceneBloc>().add(
            SceneStarted(
              tmdbId: widget.id,
              mediaType: mediaType,
              seasonNumber: _selectedSeason,
              episodeNumber: _selectedEpisode,
            ),
          );
      return;
    }
    context.read<SceneBloc>().add(
          SceneStarted(
            tmdbId: widget.id,
            mediaType: mediaType,
          ),
        );
  }

  void _onEpisodeSelectionChanged(int seasonNumber, int episodeNumber) {
    setState(() {
      _selectedSeason = seasonNumber;
      _selectedEpisode = episodeNumber;
      _sliderValue = 0;
      _timeController.text = '00:00:00';
    });
    getIt<TitleSessionHolder>().setSelectedEpisode(
      TvEpisodeSelection(
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      ),
    );
    context.read<SceneBloc>().add(
          EpisodeSelected(
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
          ),
        );
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderValue = value;
      _timeController.text = formatMsToTimestamp(value.toInt());
    });
  }

  void _onSliderReleased(double value) {
    context.read<SceneBloc>().add(TimestampChanged(value.toInt()));
  }

  void _onTimeSubmitted(String value) {
    try {
      final ms = parseTimestampToMs(value);
      setState(() {
        _sliderValue = ms.clamp(0, _maxMs).toDouble();
        _timeController.text = formatMsToTimestamp(_sliderValue.toInt());
      });
      context.read<SceneBloc>().add(TimestampChanged(_sliderValue.toInt()));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato inválido. Usa HH:MM:SS')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SceneBloc, SceneState>(
      listenWhen: (previous, current) => current is SceneLoaded,
      listener: (context, state) {
        if (state is SceneLoaded) {
          context.read<AskBloc>().add(AskContextUpdated(state.context));
        }
      },
      child: Scaffold(
        appBar: StoryPilotAppBar(title: const Text('¿Qué está pasando?')),
        body: BlocBuilder<SceneBloc, SceneState>(
          builder: (context, state) {
            if (state is SceneLoaded || state is SceneAwaitingTimestamp) {
              final durationMs = getIt<TitleSessionHolder>().durationMs;
              if (durationMs != null && durationMs > 0) {
                _maxMs = durationMs.toDouble();
              }
            }

            final askEnabled = state is SceneLoaded;
            final showEpisodeSelector = _isTv &&
                _seasons.isNotEmpty &&
                _selectedSeason != null &&
                _selectedEpisode != null;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showEpisodeSelector) ...[
                        Expanded(
                          flex: 3,
                          child: SeasonEpisodeSelector(
                            seasons: _seasons,
                            selectedSeason: _selectedSeason!,
                            selectedEpisode: _selectedEpisode!,
                            onChanged: _onEpisodeSelectionChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        flex: showEpisodeSelector ? 2 : 1,
                        child: TextField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                            labelText: 'Momento (HH:MM:SS)',
                          ),
                          onSubmitted: _onTimeSubmitted,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _onTimeSubmitted(_timeController.text),
                        icon: const Icon(Icons.check),
                      ),
                    ],
                  ),
                  Slider(
                    value: _sliderValue.clamp(0, _maxMs),
                    max: _maxMs,
                    onChanged: _onSliderChanged,
                    onChangeEnd: _onSliderReleased,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SceneContextPanel(state: state),
                          const Divider(height: 32),
                          SceneAskScrollContent(enabled: askEnabled),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SceneAskInputBar(enabled: askEnabled),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SceneContextPanel extends StatelessWidget {
  const _SceneContextPanel({required this.state});

  final SceneState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      SceneInitial() || SceneLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: LinearProgressIndicator(),
        ),
      SceneAwaitingEpisode() => const _AwaitingEpisodePrompt(),
      SceneAwaitingTimestamp() => const _AwaitingTimestampPrompt(),
      SceneFailure(:final failure) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(failure.message)),
        ),
      SceneLoaded(:final summary, :final characters, :final briefUsage, :final briefError) =>
        _SceneLoadedContent(
          summary: summary,
          characters: characters,
          briefUsage: briefUsage,
          briefError: briefError,
        ),
    };
  }
}

class _AwaitingEpisodePrompt extends StatelessWidget {
  const _AwaitingEpisodePrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('Selecciona temporada y capítulo para continuar'),
      ),
    );
  }
}

class _AwaitingTimestampPrompt extends StatelessWidget {
  const _AwaitingTimestampPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '¿Por qué minuto vas?',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Indica el momento que estás viendo (arriba) y te explico '
            'qué está pasando.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SceneLoadedContent extends StatelessWidget {
  const _SceneLoadedContent({
    required this.summary,
    required this.characters,
    this.briefUsage,
    this.briefError,
  });

  final String? summary;
  final List<SceneCharacter> characters;
  final AiUsage? briefUsage;
  final String? briefError;

  @override
  Widget build(BuildContext context) {
    final hasBrief = summary != null && summary!.isNotEmpty;
    return _SceneBriefContent(
      summary: hasBrief
          ? summary!
          : (briefError ??
              'No se pudo generar el resumen automático. Puedes preguntar abajo.'),
      characters: characters,
      usage: briefUsage,
      mutedSummary: !hasBrief,
    );
  }
}

class _SceneBriefContent extends StatelessWidget {
  const _SceneBriefContent({
    required this.summary,
    required this.characters,
    this.usage,
    this.mutedSummary = false,
  });

  final String summary;
  final List<SceneCharacter> characters;
  final AiUsage? usage;
  final bool mutedSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (characters.isNotEmpty) ...[
          Text('Personajes en escena', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                characters.map((c) => CharacterChip(character: c)).toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text('Qué está pasando', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          summary,
          style: mutedSummary
              ? theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
              : theme.textTheme.bodyLarge,
        ),
        DebugUsage(usage),
      ],
    );
  }
}

