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

List<SubtitleLine> linesInSceneWindow(
  List<SubtitleLine> lines,
  int centerMs, {
  int beforeSeconds = 120,
  int afterSeconds = 30,
}) {
  final start = centerMs - beforeSeconds * 1000;
  final end = centerMs + afterSeconds * 1000;
  return lines
      .where((line) => line.endMs >= start && line.startMs <= end)
      .toList();
}

List<SubtitleLine> linesFromStartThroughWindow(
  List<SubtitleLine> lines,
  int centerMs,
  int afterSeconds,
) {
  final end = centerMs + afterSeconds * 1000;
  return lines.where((line) => line.startMs <= end).toList();
}

List<SubtitleLine> linesFromStartThroughTimestamp(
  List<SubtitleLine> lines,
  int timestampMs,
) {
  return lines.where((line) => line.startMs <= timestampMs).toList();
}

List<SubtitleLine> linesAfterTimestampWithinWindow(
  List<SubtitleLine> lines,
  int timestampMs, {
  int afterSeconds = 30,
}) {
  final end = timestampMs + afterSeconds * 1000;
  return lines
      .where((line) => line.startMs > timestampMs && line.startMs <= end)
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
