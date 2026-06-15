import 'package:equatable/equatable.dart';

class DialogueLine extends Equatable {
  const DialogueLine({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  final int startMs;
  final int endMs;
  final String text;

  Map<String, dynamic> toJson() => {
        'startMs': startMs,
        'endMs': endMs,
        'text': text,
      };

  factory DialogueLine.fromJson(Map<String, dynamic> json) => DialogueLine(
        startMs: json['startMs'] as int,
        endMs: json['endMs'] as int,
        text: json['text'] as String,
      );

  bool containsTimestamp(int timestampMs) =>
      timestampMs >= startMs && timestampMs <= endMs;

  @override
  List<Object?> get props => [startMs, endMs, text];
}
