import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/ui/home/bloc/home_bloc.dart';
import 'package:storypilot/ui/home/bloc/home_state.dart';
import 'package:storypilot/ui/home/widgets/title_horizontal_row.dart';

class HomeFeed extends StatelessWidget {
  const HomeFeed({
    super.key,
    required this.onTitleTap,
  });

  final void Function(TitleSummary title) onTitleTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) => switch (state) {
        HomeLoading() => const Center(child: CircularProgressIndicator()),
        HomeFailure(:final failure) => Center(child: Text(failure.message)),
        HomeLoaded(
          :final recentSeries,
          :final recentMovies,
          :final popularMovies,
          :final popularSeries,
        ) =>
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recentSeries.isNotEmpty) ...[
                  _HomeSection(
                    title: 'Últimas series consultadas',
                    titles: recentSeries,
                    onTitleTap: onTitleTap,
                  ),
                  const SizedBox(height: 24),
                ],
                if (recentMovies.isNotEmpty) ...[
                  _HomeSection(
                    title: 'Últimas películas consultadas',
                    titles: recentMovies,
                    onTitleTap: onTitleTap,
                  ),
                  const SizedBox(height: 24),
                ],
                _HomeSection(
                  title: 'Películas populares',
                  titles: popularMovies,
                  onTitleTap: onTitleTap,
                ),
                const SizedBox(height: 24),
                _HomeSection(
                  title: 'Series populares',
                  titles: popularSeries,
                  onTitleTap: onTitleTap,
                ),
              ],
            ),
          ),
        HomeInitial() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.titles,
    required this.onTitleTap,
  });

  final String title;
  final List<TitleSummary> titles;
  final void Function(TitleSummary title) onTitleTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TitleHorizontalRow(titles: titles, onTitleTap: onTitleTap),
      ],
    );
  }
}
