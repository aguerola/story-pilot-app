int parseTimestampToMs(String input) {
  final parts = input.trim().split(':');
  if (parts.length != 3) {
    throw FormatException('Expected HH:MM:SS, got: $input');
  }
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  final secondsParts = parts[2].split('.');
  final seconds = int.parse(secondsParts[0]);
  final millis = secondsParts.length > 1
      ? int.parse(secondsParts[1].padRight(3, '0').substring(0, 3))
      : 0;
  return ((hours * 3600) + (minutes * 60) + seconds) * 1000 + millis;
}

String formatMsToTimestamp(int ms) {
  final totalSeconds = ms ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
