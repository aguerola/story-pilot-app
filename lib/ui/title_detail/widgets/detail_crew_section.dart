import 'package:flutter/material.dart';
import 'package:storypilot/domain/models/crew_member.dart';

class DetailCrewSection extends StatelessWidget {
  const DetailCrewSection({super.key, required this.crew});

  final List<CrewMember> crew;

  @override
  Widget build(BuildContext context) {
    if (crew.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crew',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...crew.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: member.profileUrl != null
                      ? NetworkImage(member.profileUrl!)
                      : null,
                  child: member.profileUrl == null
                      ? Text(member.name.isNotEmpty ? member.name[0] : '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name),
                      Text(
                        member.job,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
