import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/title_summary.dart';
import 'package:storypilot/ui/home/widgets/title_poster_card.dart';

class TitleHorizontalRow extends StatelessWidget {
  const TitleHorizontalRow({
    super.key,
    required this.titles,
    required this.onTitleTap,
  });

  final List<TitleSummary> titles;
  final void Function(TitleSummary title) onTitleTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: titles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final title = titles[index];
          return TitlePosterCard(
            title: title,
            onTap: () => onTitleTap(title),
          );
        },
      ),
    );
  }
}
