import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:storypilot/config/di.dart';
import 'package:storypilot/ui/auth/widgets/auth_app_bar_actions.dart';
import 'package:storypilot/ui/core/ui/story_pilot_app_bar.dart';
import 'package:storypilot/ui/search/bloc/search_bloc.dart';
import 'package:storypilot/ui/search/bloc/search_event.dart';
import 'package:storypilot/ui/search/bloc/search_state.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StoryPilotAppBar(
        title: const Text('Scene Context'),
        actions: [AuthAppBarActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entiende cualquier escena, sin spoilers.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Busca una película o serie',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  context.read<SearchBloc>().add(SearchQueryChanged(value)),
              onSubmitted: (value) =>
                  context.read<SearchBloc>().add(SearchSubmitted(value)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) => switch (state) {
                  SearchInitial() => const Center(
                      child: Text('Empieza escribiendo el título'),
                    ),
                  SearchLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  SearchFailure(:final failure) => Center(
                      child: Text(failure.message),
                    ),
                  SearchLoaded(:final results) => results.isEmpty
                      ? const Center(child: Text('Sin resultados'))
                      : ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = results[index];
                            return ListTile(
                              leading: item.posterUrl != null
                                  ? Image.network(
                                      item.posterUrl!,
                                      width: 48,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(Icons.movie),
                                    )
                                  : const Icon(Icons.movie),
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.mediaType.name.toUpperCase()}'
                                '${item.year != null ? ' · ${item.year}' : ''}',
                              ),
                              onTap: () => context.push(
                                '/title/${item.id}?type=${item.mediaType.name}',
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
