import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/data/services/subtitle_parser_service.dart';
import 'package:storypilot/domain/result.dart';

void main() {
  final parser = SubtitleParserService();

  test('parses basic SRT block', () {
    const srt = '''
1
00:00:01,000 --> 00:00:04,000
Hello world

2
00:00:05,000 --> 00:00:08,000
Second line
''';

    final result = parser.parseSrt(srt);
    expect(result, isA<Success>());
    final lines = (result as Success).data;
    expect(lines, hasLength(2));
    expect(lines.first.text, 'Hello world');
    expect(lines.first.startMs, 1000);
    expect(lines.last.endMs, 8000);
  });

  test('parses multiline cue text', () {
    const srt = '''
1
00:00:01,000 --> 00:00:04,000
Line one
Line two
''';

    final result = parser.parseSrt(srt);
    final lines = (result as Success).data;
    expect(lines.first.text, 'Line one\nLine two');
  });

  test('returns parse failure for empty content', () {
    final result = parser.parseSrt('');
    expect(result, isA<Error>());
  });
}
