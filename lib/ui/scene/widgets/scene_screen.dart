import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/ui/core/ui/character_chip.dart';
import 'package:storypilot/ui/core/ui/subtitle_line_widget.dart';
import 'package:storypilot/ui/scene/bloc/scene_bloc.dart';
import 'package:storypilot/ui/scene/bloc/scene_event.dart';
import 'package:storypilot/ui/scene/bloc/scene_state.dart';
import 'package:storypilot/utils/timestamp_utils.dart';

class SceneScreen extends StatelessWidget {
  const SceneScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SceneBloc>()..add(const SceneStarted()),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Escena actual')),
      body: BlocBuilder<SceneBloc, SceneState>(
        builder: (context, state) {
          if (state is SceneMissingData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Descarga subtítulos primero'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.go('/title/${widget.id}/subtitles'),
                    child: const Text('Ir a subtítulos'),
                  ),
                ],
              ),
            );
          }

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
                ),
                if (state is SceneLoading)
                  const LinearProgressIndicator()
                else if (state is SceneFailure)
                  Text(state.failure.message)
                else if (state is SceneLoaded) ...[
                  if (state.context.activeLine != null) ...[
                    Text(
                      'Subtítulo activo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SubtitleLineWidget(
                      line: state.context.activeLine!,
                      highlighted: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Ventana ±${state.context.windowSeconds}s',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(state.context.dialogueText),
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
                    children: state.context.characters
                        .map((c) => CharacterChip(character: c))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/title/${widget.id}/ask'),
                    icon: const Icon(Icons.chat),
                    label: const Text('Preguntar sobre esta escena'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
