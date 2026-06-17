import 'package:flutter/material.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/data/repositories/title_repository.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/domain/models/person_detail.dart';
import 'package:storypilot/domain/result.dart';

Future<void> showPersonDetailSheet(
  BuildContext context, {
  required CastMember castMember,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _PersonDetailSheet(castMember: castMember),
  );
}

class _PersonDetailSheet extends StatefulWidget {
  const _PersonDetailSheet({required this.castMember});

  final CastMember castMember;

  @override
  State<_PersonDetailSheet> createState() => _PersonDetailSheetState();
}

class _PersonDetailSheetState extends State<_PersonDetailSheet> {
  PersonDetail? _detail;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result =
        await getIt<TitleRepository>().getPersonDetail(widget.castMember.id);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _detail = data;
          _loading = false;
        });
      case Error(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  String get _fallbackInitial {
    final name = widget.castMember.characterName.isNotEmpty
        ? widget.castMember.characterName
        : widget.castMember.name;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileUrl =
        _detail?.profileUrl ?? widget.castMember.profileUrl;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        profileUrl != null ? NetworkImage(profileUrl) : null,
                    child: profileUrl == null ? Text(_fallbackInitial) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.castMember.characterName,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Interpretado por ${widget.castMember.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorBody(message: _error!, onRetry: _load)
              else if (_detail != null)
                _LoadedBody(detail: _detail!),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.detail});

  final PersonDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biography = detail.biography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.birthday != null || detail.placeOfBirth != null) ...[
          Text(
            [
              if (detail.birthday != null) detail.birthday,
              if (detail.placeOfBirth != null) detail.placeOfBirth,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text('Biografía', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          biography ?? 'Sin biografía disponible.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: biography == null
                ? theme.colorScheme.onSurfaceVariant
                : null,
          ),
        ),
        if (detail.knownFor.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Conocido por', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...detail.knownFor.map((credit) => _KnownForTile(credit: credit)),
        ],
      ],
    );
  }
}

class _KnownForTile extends StatelessWidget {
  const _KnownForTile({required this.credit});

  final PersonKnownForCredit credit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: credit.posterUrl != null
                ? Image.network(
                    credit.posterUrl!,
                    width: 48,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _posterPlaceholder(theme),
                  )
                : _posterPlaceholder(theme),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credit.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (credit.characterName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    credit.characterName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (credit.year != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${credit.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHigh,
      child: SizedBox(
        width: 48,
        height: 72,
        child: Icon(
          credit.mediaType == 'tv' ? Icons.tv : Icons.movie_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
