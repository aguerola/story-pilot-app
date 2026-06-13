import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/ui/core/ui/debug_usage.dart';
import 'package:storypilot/data/services/usage_limit_service.dart';
import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/ui/ask/bloc/ask_bloc.dart';
import 'package:storypilot/ui/ask/bloc/ask_event.dart';
import 'package:storypilot/ui/ask/bloc/ask_state.dart';
import 'package:storypilot/ui/auth/bloc/auth_bloc.dart';
import 'package:storypilot/ui/auth/bloc/auth_state.dart';
import 'package:storypilot/ui/scene/bloc/scene_brief_cubit.dart';

const _fallbackSuggestedQuestions = [
  '¿Quién está en esta escena?',
  '¿Qué acaba de pasar?',
  '¿Por qué hacen esto?',
  '¿Qué significa esta conversación?',
];

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isAuthenticated(BuildContext context) =>
      context.watch<AuthBloc>().state is AuthAuthenticated;

  int _remainingQuestions() => getIt<UsageLimitService>().remainingQuestions();

  bool _canSubmit(BuildContext context) {
    if (!widget.enabled) return false;
    if (_isAuthenticated(context)) return true;
    return _remainingQuestions() > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final isAuthenticated = _isAuthenticated(context);
    final remaining = _remainingQuestions();
    final canSubmit = _canSubmit(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pregunta lo que quieras',
          style: theme.textTheme.titleMedium,
        ),
        if (!isAuthenticated) ...[
          const SizedBox(height: 4),
          Text(
            remaining > 0
                ? 'Te quedan $remaining preguntas hoy (sin cuenta)'
                : 'Has agotado tus preguntas de hoy. Inicia sesión para continuar.',
            style: mutedStyle,
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: !widget.enabled
              ? const Center(
                  child: Text('Indica un momento para empezar a preguntar'),
                )
              : BlocBuilder<AskBloc, AskState>(
                  builder: (context, state) => switch (state) {
                    AskInitial() => _SuggestedQuestions(
                        enabled: canSubmit,
                        onSelected: (question) => _submit(context, question),
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
                            DebugUsage(answer.usage),
                          ],
                        ),
                      ),
                    AskFailure(:final failure) =>
                      Center(child: Text(failure.message)),
                    AskMissingContext() => const Center(
                        child: Text('Contexto de escena no disponible'),
                      ),
                    AskAuthRequired() => _AuthRequiredPrompt(
                        message: const AuthRequiredFailure().message,
                      ),
                  },
                ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: canSubmit,
                decoration: InputDecoration(
                  hintText: canSubmit
                      ? '¿Quién está en la escena?'
                      : 'Inicia sesión para seguir preguntando',
                ),
                onSubmitted: canSubmit
                    ? (value) => _submit(context, value)
                    : null,
              ),
            ),
            IconButton(
              onPressed: canSubmit
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
    if (question.trim().isEmpty) return;
    context.read<AskBloc>().add(AskQuestionSubmitted(question));
    _controller.clear();
  }
}

class _SuggestedQuestions extends StatelessWidget {
  const _SuggestedQuestions({required this.enabled, required this.onSelected});

  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final briefState = context.watch<SceneBriefCubit>().state;
    // While the AI is generating questions, show a skeleton instead of the
    // static fallback list (which would flash and then change).
    final isLoadingBrief =
        briefState is SceneBriefInitial || briefState is SceneBriefLoading;
    // On Ready use the AI's questions; on failure fall back to the static list.
    final questions = briefState is SceneBriefReady &&
            briefState.questions.isNotEmpty
        ? briefState.questions
        : _fallbackSuggestedQuestions;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pregunta quién está en la escena o qué ocurre',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          if (isLoadingBrief)
            const Skeletonizer.zone(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Bone.button(width: 150),
                  Bone.button(width: 120),
                  Bone.button(width: 170),
                  Bone.button(width: 140),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: questions
                  .map(
                    (question) => ActionChip(
                      label: Text(question),
                      onPressed: enabled ? () => onSelected(question) : null,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AuthRequiredPrompt extends StatelessWidget {
  const _AuthRequiredPrompt({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }
}
