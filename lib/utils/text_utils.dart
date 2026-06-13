import 'package:storypilot/domain/models/subtitle_line.dart';

String normalizeText(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâ]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöô]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'ñ'), 'n');
}

List<SubtitleLine> linesInWindow(
  List<SubtitleLine> lines,
  int centerMs,
  int windowSeconds,
) {
  final windowMs = windowSeconds * 1000;
  final start = centerMs - windowMs;
  final end = centerMs + windowMs;
  return lines
      .where((line) => line.endMs >= start && line.startMs <= end)
      .toList();
}

String aggregateDialogue(List<SubtitleLine> lines) {
  return lines.map((l) => l.text.trim()).where((t) => t.isNotEmpty).join('\n');
}

bool containsWord(String haystack, String needle) {
  if (needle.isEmpty) return false;
  final pattern = RegExp(r'\b' + RegExp.escape(needle) + r'\b');
  return pattern.hasMatch(haystack);
}
