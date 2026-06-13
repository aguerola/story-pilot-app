import 'package:storypilot/domain/failure.dart';
import 'package:storypilot/domain/models/subtitle_line.dart';
import 'package:storypilot/domain/result.dart';

class SubtitleParserService {
  Result<List<SubtitleLine>> parseSrt(String content) {
    try {
      final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      final blocks = normalized.split(RegExp(r'\n\s*\n'));
      final lines = <SubtitleLine>[];

      for (final block in blocks) {
        final blockLines = block.trim().split('\n');
        if (blockLines.length < 2) continue;

        final timeLineIndex = blockLines.indexWhere((l) => l.contains('-->'));
        if (timeLineIndex == -1) continue;

        final times = _parseTimestampLine(blockLines[timeLineIndex]);
        if (times == null) continue;

        final text = blockLines.sublist(timeLineIndex + 1).join('\n').trim();
        if (text.isEmpty) continue;

        lines.add(
          SubtitleLine(
            startMs: times.$1,
            endMs: times.$2,
            text: _stripTags(text),
          ),
        );
      }

      if (lines.isEmpty) {
        return const Error(ParseFailure('No subtitle cues found'));
      }
      return Success(lines);
    } catch (e) {
      return Error(ParseFailure(e.toString()));
    }
  }

  (int, int)? _parseTimestampLine(String line) {
    final parts = line.split('-->');
    if (parts.length != 2) return null;
    final start = _parseTime(parts[0].trim());
    final end = _parseTime(parts[1].trim());
    if (start == null || end == null) return null;
    return (start, end);
  }

  int? _parseTime(String value) {
    final match = RegExp(
      r'(\d{2}):(\d{2}):(\d{2})[,.](\d{1,3})',
    ).firstMatch(value);
    if (match == null) return null;
    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final millis = int.parse(match.group(4)!.padRight(3, '0'));
    return ((hours * 3600) + (minutes * 60) + seconds) * 1000 + millis;
  }

  String _stripTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
}
