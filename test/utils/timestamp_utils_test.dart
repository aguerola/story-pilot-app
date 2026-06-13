import 'package:flutter_test/flutter_test.dart';
import 'package:storypilot/utils/timestamp_utils.dart';

void main() {
  test('format and parse timestamp roundtrip', () {
    const ms = 3661000;
    final formatted = formatMsToTimestamp(ms);
    expect(formatted, '01:01:01');
    expect(parseTimestampToMs(formatted), ms);
  });
}
