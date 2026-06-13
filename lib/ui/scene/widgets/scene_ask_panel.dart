import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/config/gemini_model.dart';
import 'package:storypilot/data/services/settings_service.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/ask/bloc/ask_state.dart';

class SceneAskPanel extends StatefulWidget {
  const SceneAskPanel({
    super.key,
    required this.enabled,
  });

  final bool enabled;

  @override
  State<SceneAskPanel> createState() => _SceneAskPanelState();
}

class _SceneAskPanelState extends State<SceneAskPanel> {
  final _controller = TextEditingController();
  late GeminiModel _selectedModel;

  @override
  void initState() {
    super.initState();
    _selectedModel = getIt<SettingsService>().geminiModel;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onModelChanged(bool useFlash) async {
    final model = useFlash ? GeminiModel.flash25 : GeminiModel.flashLite25;
    setState(() => _selectedModel = model);
    await getIt<SettingsService>().setGeminiModel(model);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Preguntar sobre la escena',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              GeminiModel.flashLite25.shortLabel,
              style: _selectedModel == GeminiModel.flashLite25
                  ? theme.textTheme.labelLarge
                  : mutedStyle,
            ),
            Switch(
              value: _selectedModel == GeminiModel.flash25,
              onChanged: widget.enabled ? _onModelChanged : null,
            ),
            Text(
              GeminiModel.flash25.shortLabel,
              style: _selectedModel == GeminiModel.flash25
                  ? theme.textTheme.labelLarge
                  : mutedStyle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: !widget.enabled
              ? const Center(
                  child: Text('Carga subtítulos para preguntar'),
                )
              : BlocBuilder<AskBloc, AskState>(
                  builder: (context, state) => switch (state) {
                    AskInitial() => const Center(
                        child: Text(
                          'Pregunta quién está en la escena o qué ocurre',
                        ),
                      ),
                    AskAnswering(:final question) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('P: $question'),
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(),
                        ],
                      ),
                    AskAnswered(:final answer) => SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('P: ${answer.question}'),
                            const SizedBox(height: 12),
                            Text(
                              'R:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(answer.answer),
                            if (answer.sources.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Fuentes',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              ...answer.sources.map(Text.new),
                            ],
                            if (answer.hasTokenUsage) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Tokens: ${answer.tokenUsageLabel}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                            if (answer.costLabel != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Coste estimado: ${answer.costLabel}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    AskFailure(:final failure) =>
                      Center(child: Text(failure.message)),
                    AskMissingContext() => const Center(
                        child: Text('Contexto de escena no disponible'),
                      ),
                  },
                ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                decoration: const InputDecoration(
                  hintText: '¿Quién está en la escena?',
                ),
                onSubmitted: widget.enabled
                    ? (value) => _submit(context, value)
                    : null,
              ),
            ),
            IconButton(
              onPressed: widget.enabled
                  ? () => _submit(context, _controller.text)
                  : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }

  void _submit(BuildContext context, String question) {
    context.read<AskBloc>().add(AskQuestionSubmitted(question));
    _controller.clear();
  }
}
