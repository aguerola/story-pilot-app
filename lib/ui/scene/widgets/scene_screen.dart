import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/domain/models/scene_context.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/core/ui/character_chip.dart';
import 'package:storypilot/ui/core/ui/subtitle_line_widget.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
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
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Escena actual')),
        body: BlocBuilder<SceneBloc, SceneState>(
          builder: (context, state) {
            if (state is SceneLoaded) {
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
      SceneFailure(:final failure) => Center(child: Text(failure.message)),
      SceneLoaded(:final context) => _SceneLoadedContent(sceneContext: context),
    };
  }
}

class _SceneLoadedContent extends StatelessWidget {
  const _SceneLoadedContent({required this.sceneContext});

  final SceneContext sceneContext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sceneContext.activeLine != null) ...[
          Text(
            'Subtítulo activo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SubtitleLineWidget(
            line: sceneContext.activeLine!,
            highlighted: true,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Escena: ${sceneContext.sceneWindowLabel}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Text(sceneContext.dialogueText),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Personajes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sceneContext.characters
              .map((c) => CharacterChip(character: c))
              .toList(),
        ),
      ],
    );
  }
}
