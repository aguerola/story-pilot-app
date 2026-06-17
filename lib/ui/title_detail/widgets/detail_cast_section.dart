import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/cast_member.dart';
import 'package:storypilot/ui/core/ui/person_detail_sheet.dart';

class DetailCastSection extends StatelessWidget {
  const DetailCastSection({super.key, required this.cast});

  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cast',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cast.take(12).length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final member = cast[index];
              return SizedBox(
                width: 80,
                child: InkWell(
                  onTap: () => showPersonDetailSheet(
                    context,
                    castMember: member,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: member.profileUrl != null
                            ? NetworkImage(member.profileUrl!)
                            : null,
                        child: member.profileUrl == null
                            ? Text(
                                member.name.isNotEmpty ? member.name[0] : '?',
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.characterName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
