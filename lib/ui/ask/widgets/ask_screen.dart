import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/services/title_session_holder.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/ask/bloc/ask_state.dart';

class AskScreen extends StatelessWidget {
  const AskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = getIt<TitleSessionHolder>();
    final contextData = session.sceneContext;
    return BlocProvider(
      create: (_) {
        final bloc = getIt<AskBloc>();
        if (contextData != null) {
          bloc.add(AskStarted(contextData));
        }
        return bloc;
      },
      child: _AskView(hasContext: contextData != null),
    );
  }
}

class _AskView extends StatefulWidget {
  const _AskView({required this.hasContext});

  final bool hasContext;

  @override
  State<_AskView> createState() => _AskViewState();
}

class _AskViewState extends State<_AskView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasContext) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preguntar')),
        body: const Center(
          child: Text('Carga una escena antes de hacer preguntas'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Preguntar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<AskBloc, AskState>(
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
                    decoration: const InputDecoration(
                      hintText: '¿Quién está en la escena?',
                    ),
                    onSubmitted: (value) => _submit(context, value),
                  ),
                ),
                IconButton(
                  onPressed: () => _submit(context, _controller.text),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context, String question) {
    context.read<AskBloc>().add(AskQuestionSubmitted(question));
    _controller.clear();
  }
}
