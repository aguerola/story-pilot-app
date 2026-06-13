import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/models/ai_usage.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/core/ui/character_chip.dart';
import 'package:storypilot/ui/core/ui/debug_usage.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
import 'package:storypilot/ui/scene/bloc/scene_brief_cubit.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';
import 'package:storypilot/ui/scene/widgets/scene_ask_panel.dart';
import 'package:storypilot/utils/timestamp_utils.dart';

const _wideLayoutBreakpoint = 840.0;

class SceneScreen extends StatelessWidget {
  const SceneScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<SceneBloc>()..add(SceneStarted(tmdbId: id)),
        ),
        BlocProvider(create: (_) => getIt<AskBloc>()),
        BlocProvider(create: (_) => getIt<SceneBriefCubit>()),
      ],
      child: _SceneView(id: id),
    );
  }
}

class _SceneView extends StatefulWidget {
  const _SceneView({required this.id});

  final int id;

  @override
  State<_SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<_SceneView> {
  final _timeController = TextEditingController(text: '00:00:00');
  double _sliderValue = 0;
  double _maxMs = 7200000;

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
          // Free, Lite-only brief (summary + characters + questions) shown
          // automatically; never counts toward the daily question quota.
          context
              .read<SceneBriefCubit>()
              .load(state.context, getIt<TitleSessionHolder>().cast);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('¿Qué está pasando?')),
        body: BlocBuilder<SceneBloc, SceneState>(
          builder: (context, state) {
            if (state is SceneLoaded || state is SceneAwaitingTimestamp) {
              final lastLine = getIt<TitleSessionHolder>()
                  .subtitleDocument
                  ?.lines
                  .last
                  .endMs;
              if (lastLine != null && lastLine > 0) {
                _maxMs = lastLine.toDouble();
              }
            }

            final askEnabled = state is SceneLoaded;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                            labelText: 'Timestamp (HH:MM:SS)',
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
                  if (state is SceneLoaded)
                    _SpoilerGuardBanner(timestampMs: state.context.timestampMs),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= _wideLayoutBreakpoint;
                        final scenePanel = _SceneContextPanel(state: state);
                        final askPanel = SceneAskPanel(enabled: askEnabled);

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 11, child: scenePanel),
                              const VerticalDivider(width: 24),
                              Expanded(flex: 9, child: askPanel),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 11, child: scenePanel),
                            const Divider(height: 24),
                            Expanded(flex: 9, child: askPanel),
                          ],
                        );
                      },
                    ),
                  ),
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
      SceneInitial() || SceneLoading() =>
        const Center(child: LinearProgressIndicator()),
      SceneAwaitingTimestamp() => const _AwaitingTimestampPrompt(),
      SceneFailure(:final failure) => Center(child: Text(failure.message)),
      SceneLoaded(:final context) => _SceneLoadedContent(sceneContext: context),
    };
  }
}

class _AwaitingTimestampPrompt extends StatelessWidget {
  const _AwaitingTimestampPrompt();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }
}

class _SpoilerGuardBanner extends StatelessWidget {
  const _SpoilerGuardBanner({required this.timestampMs});

  final int timestampMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vas por el ${formatMsToTimestamp(timestampMs)} · no te cuento '
              'nada de lo que pasa después',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneLoadedContent extends StatelessWidget {
  const _SceneLoadedContent({required this.sceneContext});

  final SceneContext sceneContext;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SceneBriefCubit, SceneBriefState>(
      builder: (context, briefState) => switch (briefState) {
        // While the AI is working, show a skeleton — no provisional results.
        SceneBriefInitial() || SceneBriefLoading() => const _SceneBriefSkeleton(),
        SceneBriefReady(:final summary, :final characters, :final usage) =>
          _SceneBriefContent(
            summary: summary,
            characters: characters,
            usage: usage,
          ),
        // Only on a real failure fall back to the heuristic characters.
        SceneBriefFailure() => _SceneBriefContent(
            summary:
                'No se pudo generar el resumen automático. Puedes preguntar abajo.',
            characters: sceneContext.characters,
            mutedSummary: true,
          ),
      },
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
    return ListView(
      children: [
        Text('Qué está pasando', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          summary,
          style: mutedSummary
              ? theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
              : theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (characters.isNotEmpty) ...[
          Text('Personajes en escena', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                characters.map((c) => CharacterChip(character: c)).toList(),
          ),
        ],
        DebugUsage(usage),
      ],
    );
  }
}

class _SceneBriefSkeleton extends StatelessWidget {
  const _SceneBriefSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Skeletonizer.zone(
      child: ListView(
        children: [
          Text('Qué está pasando', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Bone.multiText(lines: 3),
          const SizedBox(height: 20),
          Text('Personajes en escena', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SkeletonCharacterChip(),
              _SkeletonCharacterChip(),
              _SkeletonCharacterChip(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonCharacterChip extends StatelessWidget {
  const _SkeletonCharacterChip();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(6, 6, 14, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Bone.circle(size: 48),
          SizedBox(width: 10),
          Bone.text(width: 72),
        ],
      ),
    );
  }
}

